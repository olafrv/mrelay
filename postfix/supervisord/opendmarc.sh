#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

source /supervisord/common.sh  # common functions

# http://www.trusteddomain.org/opendmarc/opendmarc.conf.5.html
# https://github.com/trusteddomainproject/OpenDMARC/blob/master/opendmarc/opendmarc.conf.sample

log "Setting up OpenDMARC..."
cat - > /etc/opendmarc/opendmarc.conf <<EOF
AutoRestart                 false
AuthservID                  ${MRELAY_POSTFIX_HOSTNAME}
DNSTimeout                  5
IgnoreAuthenticatedClients  true
RejectFailures              true
HistoryFile                 /run/opendmarc/opendmarc.dat
RecordAllMessages           true
PidFile                     /run/opendmarc/opendmarc.pid
Syslog                      Yes
SyslogFacility              mail
Socket                      inet:9030@localhost
UserID                      opendmarc:opendmarc
TrustedAuthservIDs          ${MRELAY_POSTFIX_HOSTNAME}
MilterDebug                 4
EOF

log "Initializing Public Suffix List..."
/supervisord/opendmarc-psl.sh

log "Starting OpenDMARC..."
exec $(which opendmarc) -f -c /etc/opendmarc/opendmarc.conf
