# syntax = docker/dockerfile:labs
FROM alpine:3.16

RUN <<EOF
  apk update
  apk upgrade
  apk add --no-cache \
  ca-certificates \
  update-ca-certificates \
	dovecot \
	dovecot-lmtpd \
	dovecot-mysql \
	dovecot-pigeonhole-plugin
  
ADD dovecot.conf /etc/dovecot/dovecot.conf
ADD dovecot-sql.conf /etc/dovecot/dovecot-sql.conf

ENTRYPOINT ["dovecot", "-F"]
