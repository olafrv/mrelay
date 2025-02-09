#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

# LOL: Remove ;) /usr/local/games:/usr/games
sed -i '/^PATH=.*/d' /etc/environment
echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    >> /etc/environment

# Required for cron jobs to work
echo "SHELL=/bin/bash" >> /etc/environment
printenv | grep "^MRELAY_POSTFIX_" >> /etc/environment

# Start supervisord and services
mkdir -p /var/log/supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
