#!/bin/bash
#====================================================================#
#  MagenX - Automated Deployment of Virtual Mail Server              #
#  Copyright (C) 2018 admin@magenx.com                               #
#  All rights reserved.                                              #
#====================================================================#
# version
ADOVMS_VER="4.0"

# Roundcube version
ROUNDCUBE="1.3.4"

# Repositories
REPO_GF="http://mirror.ghettoforge.org/distributions/gf/gf-release-latest.gf.el7.noarch.rpm"

# Extra packages
MAIL_PACKAGES="postfix3 postfix3-cdb postfix3-mysql postfix3-pcre postfix3-perl-scripts postfix3-sqlite dovecot22 dovecot22-mysql dovecot22-pigeonhole clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner"
EXTRA_PACKAGES="opendkim git subversion libicu"

# PEAR packages
PEAR="Net_IDNA2 Mail_mime Mail_mimeDecode Net_LDAP3 Auth_SASL Net_SMTP"

# Configs
POSTFIX_MAIN_CF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/main.cf"
POSTFIX_MASTER_CF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/master.cf"
POSTFIX_REPLY_FILTER="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/smtp_reply_filter"
DOVECOT_CONF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/dovecot.conf"
DOVECOT_SQL_CONF="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/dovecot-sql.conf"
CLAMAV_MILTER="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/clamav-milter.conf"
CLAMAV_SCAN="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/mailscan.conf"

# Virus alert
VIRUS_ALERT="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/virus_alert.sh"

# Postfix filters
POSTFIX_FILTERS="black_client black_client_ip block_dsl helo_checks mx_access white_client white_client_ip"
POSTFIX_FILTERS_URL="https://raw.githubusercontent.com/magenx/magenx-email-server/master/CentOS-7/postfix/config/"

# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"

# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"

# Styles
BOLD="\e[1m"

# Reset
RESET="\e[0m"

# quick-n-dirty coloring
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${BOLD}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${BOLD}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${BOLD}${MESSAGE}${RESET}"
} 
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${BOLD}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${BOLD}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}
function pause() {
   read -p "$*"
}

clear
###################################################################################
#                                     START CHECKS                                #
###################################################################################
echo

# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# do we have CentOS 7?
if grep "CentOS.* 7\." /etc/redhat-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7"
  echo
  exit 1
fi

# check if x64.
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  GREENTXT "PASS: YOUR ARCHITECTURE IS 64-BIT"
  else
  echo
  REDTXT "ERROR: YOUR ARCHITECTURE IS 32-BIT?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# network is up?
host1=74.125.24.106
host2=208.80.154.225
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi

# dumb check for php package
which php > /dev/null 2>&1
 if [ "$?" = 0 ]
  then
  # we need php > 5.4.0
  PHPVER=$(php -v | head -1 | awk {'print $2'})
  if echo ${PHPVER} 5.4.0 | awk '{exit !( $1 > $2)}'; then
    GREENTXT "PASS: YOUR PHP IS ${WHITE}${BOLD}${PHPVER}"
    else
    REDTXT "ERROR: YOUR PHP VERSION IS NOT > 5.4"
    YELLOWTXT "------> CONFIGURATION FOR PHP > 5.4 ONLY."
    echo
    exit 1
  fi
  else
  REDTXT "ERROR: PHP PACKAGE IS NOT INSTALLED"
  echo
  exit
 fi
echo
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" /root/adovms/.terms >/dev/null 2>&1 ; then
echo "...... loading menu"
sleep 1
      else
        YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            echo
        YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
        YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
            echo
        YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
        YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
            echo
        YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            echo
            echo
	echo -n "---> Do you agree to these terms?  [y/n][y]:"
 	read terms_agree
        if [ "$terms_agree" == "y" ];then
          echo
            mkdir -p /root/adovms
            echo "yes" > /root/adovms/.terms
            else
            echo "Exiting"
           exit 1
          echo
        fi
fi
###################################################################################
#                                  HEADER MENU START                              #
###################################################################################

showMenu () {
printf "\033c"
        echo
        echo
        echo -e "${DGREYBG}${BOLD}  Virtual Mail Server Configuration v.${ADOVMS_VER}  ${RESET}"
        echo -e "\t\t${BLUE}${BOLD}:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  ${RESET}"
        echo
        echo -e "\t\t${WHITE}${BOLD}-> For packages installation enter     :  ${YELLOW} packages  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Download and install vimbadmin      :  ${YELLOW} vimbadmin  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Download and install roundcube      :  ${YELLOW} roundcube  ${RESET}"
        echo -e "\t\t${WHITE}${BOLD}-> Setup and configure everything      :  ${YELLOW} config  ${RESET}"
        echo
        echo -e "\t\t${BLUE}${BOLD}:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::  ${RESET}"
        echo
        echo -e "\t\t${WHITE}${BOLD}-> To quit enter                       :  ${RED} exit  ${RESET}"
        echo
        echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "${CHOICE}" in
"packages")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW INSTALLING POSTFIX, DOVECOT, CLAMAV, MILTER, GIT, SUBVERSION, OPENDKIM "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
echo -n "---> Start mail packages installation? [y/n][n]:"
read mail_install
if [ "${mail_install}" == "y" ];then
    echo
    GREENTXT "Running mail packages installation"
    rpm -e --nodeps postfix >/dev/null 2>&1
    echo
    pear config-set preferred_state alpha >/dev/null 2>&1
    pear install ${PEAR} >/dev/null 2>&1
    yum -q -y install epel-release
    yum -q -y install ${REPO_GF}
    yum --enablerepo=gf-plus -y install ${MAIL_PACKAGES}
    yum --enablerepo=epel-testing -y install ${EXTRA_PACKAGES} 
    echo
    echo
    rpm --quiet -q postfix3
    if [ $? = 0 ]
      then
        echo
        GREENTXT "INSTALLED"
        else
        REDTXT "ERROR"
        exit
    fi
        echo
	systemctl enable dovecot
	alternatives --set mta /usr/sbin/sendmail.postfix
        else
        YELLOWTXT "Mail packages installation skipped. Next step"
fi
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED PACKAGES INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"vimbadmin")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW DOWNLOADING ViMbAdmin "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo -n "---> Download and configure ViMbAdmin 3? [y/n][n]:"
read vmb_down
if [ "${vmb_down}" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/vimbadmin" VMB_PATH
        echo
        echo "  ViMbAdmin will be installed into:" 
		GREENTXT ${VMB_PATH}
		echo
		pause '------> Press [Enter] key to continue'
		echo
		mkdir -p ${VMB_PATH} && cd $_
		echo
		###################################################
		git config --global url."https://".insteadOf git://
		###################################################
                git clone git://github.com/opensolutions/ViMbAdmin.git .
		echo
		echo "  Installing Third Party Libraries"
		echo
                cd ${VMB_PATH}
		echo "  Get composer"
		curl -sS https://getcomposer.org/installer | php
		mv composer.phar composer
		echo
                ./composer install
		cp ${VMB_PATH}/public/.htaccess.dist ${VMB_PATH}/public/.htaccess
echo
cat > /root/adovms/.adovms_index <<END
mail	${VMB_PATH}
END
fi
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED ViMbAdmin INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"roundcube")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW DOWNLOADING ROUNDCUBE "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo -n "---> Download and configure ROUNDCUBE v${ROUNDCUBE}? [y/n][n]:"
read rcb_down
if [ "${rcb_down}" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/roundcube" RCB_PATH
        echo
        echo "  ROUNDCUBE will be installed into:" 
		GREENTXT ${RCB_PATH}
		echo
		pause '------> Press [Enter] key to continue'
		echo
		mkdir -p ${RCB_PATH}
                cd ${RCB_PATH}
		echo
		wget -qO - https://github.com/roundcube/roundcubemail/releases/download/${ROUNDCUBE}/roundcubemail-${ROUNDCUBE}-complete.tar.gz | tar -xz --strip 1
		echo
		ls -l ${RCB_PATH}
		echo
		GREENTXT "INSTALLED"
	echo	
	echo	
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " FINISHED ROUNDCUBE INSTALLATION "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  else
        YELLOWTXT "ROUNDCUBE installation skipped. Next step"
fi
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"config")
echo
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
BLUEBG " NOW CONFIGURING POSTFIX, DOVECOT, OPENDKIM, ViMbAdmin AND ROUNDCUBE "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
printf "\033c"
echo
WHITETXT "Creating virtual mail User and Group"
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /home/vmail -m -s /sbin/nologin
echo
WHITETXT "Creating ViMbAdmin MySQL DATABASE and USER"
echo
echo -n "---> Generate ViMbAdmin strong password? [y/n][n]:"
read vmb_pass_gen
if [ "${vmb_pass_gen}" == "y" ];then
   echo
     VMB_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
     WHITETXT "ViMbAdmin database password: ${RED}${VMB_PASSGEN}"
     YELLOWTXT "!REMEMBER IT AND KEEP IT SAFE!"
fi
echo
echo
read -e -p "---> Enter MySQL ROOT password : " MYSQL_ROOT_PASS
read -e -p "---> Enter ViMbAdmin database host : " VMB_DB_HOST
read -e -p "---> Enter ViMbAdmin database name : " VMB_DB_NAME
read -e -p "---> Enter ViMbAdmin database user : " VMB_DB_USER_NAME
echo
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${VMB_DB_USER_NAME}'@'${VMB_DB_HOST}' IDENTIFIED BY '${VMB_PASSGEN}';
CREATE DATABASE ${VMB_DB_NAME};
GRANT ALL PRIVILEGES ON ${VMB_DB_NAME}.* TO '${VMB_DB_USER_NAME}'@'${VMB_DB_HOST}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
EOMYSQL
echo
echo
echo -n "---> SETUP ROUNDCUBE MySQL DATABASE AND USER? [y/n][n]:"
read rcb_sdb
if [ "${rcb_sdb}" == "y" ];then
echo
WHITETXT "CREATING ROUNDCUBE MySQL DATABASE AND USER"
echo
echo -n "---> Generate ROUNDCUBE strong password? [y/n][n]:"
read rcb_pass_gen
if [ "${rcb_pass_gen}" == "y" ];then
   echo
     RCB_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
     WHITETXT "ROUNDCUBE database password: ${RED}${RCB_PASSGEN}"
     YELLOWTXT "!REMEMBER IT AND KEEP IT SAFE!"
fi
echo
echo
read -e -p "---> Enter MySQL ROOT password : " MYSQL_ROOT_PASS
read -e -p "---> Enter ROUNDCUBE database host : " RCB_DB_HOST
read -e -p "---> Enter ROUNDCUBE database name : " RCB_DB_NAME
read -e -p "---> Enter ROUNDCUBE database user : " RCB_DB_USER_NAME
echo
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${RCB_DB_USER_NAME}'@'${RCB_DB_HOST}' IDENTIFIED BY '${RCB_PASSGEN}';
CREATE DATABASE ${RCB_DB_NAME} /*!40101 CHARACTER SET utf8 COLLATE utf8_general_ci */;
GRANT ALL PRIVILEGES ON ${RCB_DB_NAME}.* TO '${RCB_DB_USER_NAME}'@'${RCB_DB_HOST}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit
EOMYSQL
echo
WHITETXT "Import Roundcube database tables..."
mysql -u root -p${MYSQL_ROOT_PASS} ${RCB_DB_NAME} < ${RCB_PATH}/SQL/mysql.initial.sql
  else
  YELLOWTXT "ROUNDCUBE installation skipped. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Load preconfigured postfix dovecot configs? [y/n][n]:"
read load_configs
if [ "${load_configs}" == "y" ];then
echo
REDTXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
echo
mkdir -p /etc/postfix/mysql
mkdir -p /etc/postfix/config
WHITETXT "Writing Postfix/ViMbAdmin mysql connection files"
cat > /etc/postfix/mysql/virtual-alias-maps.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT goto FROM alias WHERE address = '%s' AND active = '1'
END
cat > /etc/postfix/mysql/virtual-mailbox-domains.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT domain FROM domain WHERE domain = '%s' AND backupmx = '0' AND active = '1'
END
cat > /etc/postfix/mysql/virtual-mailbox-maps.cf <<END
user = ${VMB_DB_USER_NAME}
password = ${VMB_PASSGEN}
hosts = ${VMB_DB_HOST}
dbname = ${VMB_DB_NAME}
query = SELECT maildir FROM mailbox WHERE username = '%s' AND active = '1'
END
echo
WHITETXT "Writing Postfix main.cf file"
read -e -p "---> Enter your domain : " VMB_DOMAIN
read -e -p "---> Enter your hostname : " VMB_MYHOSTNAME
read -e -p "---> Enter your admin email : " VMB_ADMIN_MAIL
read -e -p "---> Enter your ssl cert location: " -i "/etc/letsencrypt/live/example.com/fullchain.pem"  VMB_SSL_CRT
read -e -p "---> Enter your ssl key location: " -i "/etc/letsencrypt/live/example.com/privkey.pem"  VMB_SSL_KEY

wget -qO /etc/postfix/main.cf ${POSTFIX_MAIN_CF}
sed -i "s,VMB_SSL_CRT,${VMB_SSL_CRT}," /etc/postfix/main.cf
sed -i "s,VMB_SSL_KEY,${VMB_SSL_KEY}," /etc/postfix/main.cf
sed -i "s/VMB_MYHOSTNAME/${VMB_MYHOSTNAME}/" /etc/postfix/main.cf
sed -i "s/VMB_DOMAIN/${VMB_DOMAIN}/" /etc/postfix/main.cf
sed -i "s/VMB_ADMIN_MAIL/${VMB_ADMIN_MAIL}/" /etc/postfix/main.cf

wget -qO /etc/postfix/master.cf ${POSTFIX_MASTER_CF}
wget -qO /etc/postfix/smtp_reply_filter ${POSTFIX_REPLY_FILTER}

echo
WHITETXT "Writing Dovecot config file"
wget -qO /etc/dovecot/dovecot.conf ${DOVECOT_CONF}
sed -i "s,VMB_SSL_CRT,${VMB_SSL_CRT}," /etc/dovecot/dovecot.conf
sed -i "s,VMB_SSL_KEY,${VMB_SSL_KEY}," /etc/dovecot/dovecot.conf
sed -i "s/VMB_ADMIN_MAIL/${VMB_ADMIN_MAIL}/" /etc/dovecot/dovecot.conf

echo
WHITETXT "Writing Dovecot mysql connection file"
wget -qO /etc/dovecot/dovecot-sql.conf ${DOVECOT_SQL_CONF}
sed -i "s/VMB_DB_HOST/${VMB_DB_HOST}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_DB_NAME/${VMB_DB_NAME}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_DB_USER_NAME/${VMB_DB_USER_NAME}/" /etc/dovecot/dovecot-sql.conf
sed -i "s/VMB_PASSGEN/${VMB_PASSGEN}/" /etc/dovecot/dovecot-sql.conf

echo
WHITETXT "Writing Postfix PERMIT/REJECT filters. Please uncomment/edit to your needs"
WHITETXT "at /etc/postfix/config/*"
cd /etc/postfix/config/
for FILTER in ${POSTFIX_FILTERS}
do
wget -q ${POSTFIX_FILTERS_URL}${FILTER}
done

echo
WHITETXT "Writing Clamav-Milter config"
wget -qO /etc/mail/clamav-milter.conf ${CLAMAV_MILTER}
echo
WHITETXT "Writing Clamav-Scanner config"
wget -qO /etc/clamd.d/mailscan.conf ${CLAMAV_SCAN}
echo

WHITETXT "Writing Virus alert script"
wget -qO /etc/clamd.d/virus_alert.sh ${VIRUS_ALERT}
chmod +x /etc/clamd.d/virus_alert.sh
sed -i "s/ADMIN_MAIL/${VMB_ADMIN_MAIL}/" /etc/clamd.d/virus_alert.sh

mkdir -p /var/log/clamd.scan
touch /var/log/clamd.scan/mailscan.log
chown -R clamscan:clamscan /var/log/clamd.scan

sed -i "/^Example/d" /etc/freshclam.conf
sed -i "/^FRESHCLAM_DELAY/d" /etc/sysconfig/freshclam

systemctl enable clamav-milter.service
systemctl enable opendkim.service
systemctl enable clamd@mailscan

systemctl restart clamd@mailscan
systemctl restart clamav-milter.service
systemctl restart postfix.service
systemctl restart dovecot.service

echo
echo
WHITETXT "============================================================================="
echo
WHITETXT "Now we going to configure opendkim - generating signing key and configs"
echo
echo
read -e -p "---> Enter your domains: domain1.com domain2.net domain3.eu: " DKIM_DOMAINS
echo
echo
for DOMAIN in ${DKIM_DOMAINS}
do
# Generate folders and keys
mkdir -p /etc/opendkim/keys/${DOMAIN}
opendkim-genkey -D /etc/opendkim/keys/${DOMAIN}/ -d ${DOMAIN} -s default
chown -R opendkim:opendkim /etc/opendkim/keys/${DOMAIN}
cd /etc/opendkim/keys/${DOMAIN}
cp default.private default
# Add key rule to Table
echo "default._domainkey.${DOMAIN} ${DOMAIN}:default:/etc/opendkim/keys/${DOMAIN}/default.private" >> /etc/opendkim/KeyTable
echo "*@${DOMAIN} default._domainkey.${DOMAIN}" >> /etc/opendkim/SigningTable
echo
GREENTXT " DNS records for ${YELLOW}${BOLD}${DOMAIN} "
cat /etc/opendkim/keys/${DOMAIN}/default.txt
echo "_adsp._domainkey.${DOMAIN} IN TXT dkim=unknown"
echo "_dmarc.${DOMAIN}. IN TXT v=DMARC1; p=none; sp=none; rf=afrf; pct=100; ri=86400"
WHITETXT "============================================================================="
done
echo
WHITETXT "Loading main opendkim config"
cat > /etc/opendkim.conf <<END
## BEFORE running OpenDKIM you must:
## - edit your DNS records to publish your public keys
## CONFIGURATION OPTIONS
PidFile /var/run/opendkim/opendkim.pid
AutoRestart     yes
AutoRestartRate 5/1h
Mode    sv
Syslog  yes
SyslogSuccess   yes
LogWhy  yes
UserID  opendkim:opendkim
Socket  inet:8891@localhost
Umask   002
## SIGNING OPTIONS
Canonicalization        relaxed/simple
Selector        default
MinimumKeyBits 1024
KeyTable        /etc/opendkim/KeyTable
SigningTable    refile:/etc/opendkim/SigningTable
ExternalIgnoreList /etc/opendkim/TrustedHosts
InternalHosts      /etc/opendkim/TrustedHosts
END
echo
systemctl start opendkim.service
echo
WHITETXT "============================================================================="
echo
pause '------> Press [Enter] key to continue'
echo
echo
WHITETXT "============================================================================="
WHITETXT "============================================================================="
echo
VMB_PATH=$(awk '/mail/ {print $2}' /root/adovms/.adovms_index)
WHITETXT "Now we will try to edit ViMbAdmin v3 application.ini file:"
WHITETXT "${VMB_PATH}/application/configs/application.ini"
cd ${VMB_PATH}
cp ${VMB_PATH}/application/configs/application.ini.dist ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.domain.transport = "virtual"/defaults.domain.transport = "dovecot"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.mailbox.uid = 2000/defaults.mailbox.uid = 5000/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/defaults.mailbox.gid = 2000/defaults.mailbox.gid = 5000/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.pop3.enabled = 1/server.pop3.enabled = 0/' ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.dbname   = 'vimbadmin'/resources.doctrine2.connection.options.dbname   = '${VMB_DB_NAME}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.user     = 'vimbadmin'/resources.doctrine2.connection.options.user     = '${VMB_DB_USER_NAME}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.password = 'xxx'/resources.doctrine2.connection.options.password = '${VMB_PASSGEN}'/" ${VMB_PATH}/application/configs/application.ini
sed -i "s/resources.doctrine2.connection.options.host     = 'localhost'/resources.doctrine2.connection.options.host     = '${VMB_DB_HOST}'/" ${VMB_PATH}/application/configs/application.ini
sed -i 's,defaults.mailbox.maildir = "maildir:/srv/vmail/%d/%u/mail:LAYOUT=fs",defaults.mailbox.maildir = "maildir:/home/vmail/%d/%u",'  ${VMB_PATH}/application/configs/application.ini
sed -i 's,defaults.mailbox.homedir = "/srv/vmail/%d/%u",defaults.mailbox.homedir = "/home/vmail/%d/%u",' ${VMB_PATH}/application/configs/application.ini
sed -i 's/.*defaults.mailbox.password_scheme.*/defaults.mailbox.password_scheme = "dovecot:SHA512-CRYPT"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.email.name = "ViMbAdmin Administrator"/server.email.name = "eMail Administrator"/' ${VMB_PATH}/application/configs/application.ini
sed -i 's/server.email.address = "support@example.com"/server.email.address = "'${VMB_ADMIN_MAIL}'"/' ${VMB_PATH}/application/configs/application.ini
echo
WHITETXT "Creating ViMbAdmin v3 database tables:"
./bin/doctrine2-cli.php orm:schema-tool:create
echo
WHITETXT "Now edit ${VMB_PATH}/application/configs/application.ini and configure all parameters in the [user] section"
WHITETXT "except securitysalt - easier to do that later when you first run web frontend"
WHITETXT "monitor mail log   tail -f /var/log/maillog"
echo
fi
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"exit")
REDTXT "------> bye"
echo -e "\a"
exit
;;
###################################################################################
#                               MENU DEFAULT CATCH ALL                            #
###################################################################################
*)
printf "\033c"
;;
esac
done
