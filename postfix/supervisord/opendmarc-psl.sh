#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

source /supervisord/common.sh  # common functions

log "Downloading public_suffix_list.dat..."
curl -sfL -o /run/opendmarc/public_suffix_list.dat \
    https://publicsuffix.org/list/public_suffix_list.dat

log "Setting file permissions..."
chown opendmarc:opendmarc /run/opendmarc/public_suffix_list.dat

if pid=$(pidof opendmarc)
then
    log "Killing OpenDMARC pid:$pid ..."
    kill -HUP $pid || true
    netstat -tulpn | grep 9030 || true
else
    log "OpenDMARC is not running, reload skipped."
fi
