#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

source /supervisord/common.sh  # common functions

DKIM_CONFIG=/etc/opendkim.conf
DKIM_ETCDIR=/etc/opendkim
DKIM_SELECTOR=${MRELAY_POSTFIX_DKIM_SELECTOR}
DKIM_DOMAIN=${MRELAY_POSTFIX_DOMAIN}
DKIM_KEYSDIR=${DKIM_ETCDIR}/keys/${DKIM_DOMAIN}
DKIM_KEYFILE=${DKIM_KEYSDIR}/${DKIM_SELECTOR}.private
DKIM_TXTFILE=${DKIM_KEYSDIR}/${DKIM_SELECTOR}.txt

# https://linux.die.net/man/8/opendkim
# https://linux.die.net/man/5/opendkim.conf

log "Creating DKIM config file '${DKIM_CONFIG}' ..."
cat - > ${DKIM_CONFIG} <<EOF
AutoRestart             false
CaptureUnknownErrors    true
Canonicalization        relaxed/simple
DNSTimeout              5
Domain                  ${DKIM_DOMAIN}
InternalHosts           127.0.0.1
KeyFile                 ${DKIM_KEYFILE}
LogResults              Yes
LogWhy                  Yes
# Mode                  <Defined by the key test result>
PidFile                 /run/opendkim/opendkim.pid
ReportAddress           postmaster@${DKIM_DOMAIN}
RequireSafeKeys         false
SignatureAlgorithm      rsa-sha256
Selector                ${DKIM_SELECTOR}
Syslog                  Yes
SyslogSuccess           Yes
SyslogFacility          mail
Socket                  inet:9020@localhost
UMask                   002
UserID                  opendkim:opendkim
EOF

if [ ! -f ${DKIM_KEYFILE} ]
then
    mkdir -p ${DKIM_KEYSDIR}
    log "Generating DKIM key for '${DKIM_DOMAIN}' selector '${DKIM_SELECTOR}' ..."
    opendkim-genkey -b 2048 -d ${DKIM_DOMAIN} -D ${DKIM_KEYSDIR} -s ${DKIM_SELECTOR} -v
fi
log "DKIM TXT record for '${DKIM_DOMAIN}' selector '${DKIM_SELECTOR}':"
cat ${DKIM_TXTFILE}

chown -R opendkim:opendkim ${DKIM_ETCDIR}
chown opendkim:opendkim ${DKIM_CONFIG}

opendkim-testkey -d ${DKIM_DOMAIN} -s ${DKIM_SELECTOR} -x ${DKIM_CONFIG} -vvv
if [ $? -ne 0 ]
then
    log "ERROR: DKIM key test failed for '${DKIM_DOMAIN}' selector '${DKIM_SELECTOR}'"
    echo "Mode v" >> ${DKIM_CONFIG}
    log "Set opendkim (Mode: v) ..."
else
    log "DKIM key test succeeded for '${DKIM_DOMAIN}' selector '${DKIM_SELECTOR}'"
    echo "Mode sv" >> ${DKIM_CONFIG}
    log "Set opendkim (Mode: sv) ..."
fi

log "Starting OpenDKIM ..."
exec /usr/sbin/opendkim -f -x ${DKIM_CONFIG} -P /run/opendkim/opendkim.pid
