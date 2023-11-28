#!/bin/bash

echo "$(date) - Downloading public_suffix_list.dat..."
curl -fL -o /run/opendmarc/public_suffix_list.dat \
    https://publicsuffix.org/list/public_suffix_list.dat
echo "$(date) - Exit code: $?"

echo "$(date) - Setting file permissions..."
chown opendmarc:opendmarc /run/opendmarc/public_suffix_list.dat
echo "$(date) - Exit code: $?"

pid=$(pidof opendmarc)
if [ -n "$pid" ]
then
    echo "$(date) - Killing OpenDMARC pid:$pid ..."
    kill -HUP $pid
    netstat -tulpn | grep 9030
    echo "$(date) - Exit code: $?"
fi
