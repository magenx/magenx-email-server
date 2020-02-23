#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

SERVER=${HOSTNAME}
ALERT=ADMIN_MAIL

# The following parameters are passed to the invoked program in this order:
# virus name, queue id, sender, destination, subject, message id, message date.
VIRUS=$1          # virus name
QUEUE=$2          # queue id
SENDER=$3         # sender
DESTINATION=$4    # destination
SUBJECT=$5        # subject
MSGID=$6          # message id
DATE=$7           # message date

cat -v << EOF | mail -s "${SERVER}: an infected e-mail has been detected." ${ALERT}
Signature   : ${VIRUS}
Date        : ${DATE}
Subject     : ${SUBJECT}

Sender      : ${SENDER}
Destination : ${DESTINATION}

Queue       : ${QUEUE}
Message ID  : ${MSGID}

Message was rejected. Further action is not required.
EOF
