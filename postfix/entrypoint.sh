#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

# LOL: Remove ;) /usr/local/games:/usr/games
sed -i '/^PATH=.*/d' /etc/environment
echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    >> /etc/environment

# Required for cron jobs to work
printenv | grep "^MRELAY_POSTFIX_" >> /etc/environment

# Require for syslog to save logs to /var/log
chown root:syslog /var/log
chmod 775 /var/log

# Kernel facility not available in Docker
sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Cronjobs
sd=/supervisord
echo "
SHELL=/bin/bash
# Certificate renewal via Cloudflare DNS (/var/log/letsencrypt)
0 0 * * * $sd/certbot.sh >/dev/null 2>&1
# OpenDMARC Public Suffix List update
0 1 * * * $sd/opendmarc-psl.sh >/var/log/opendmarc-psl.log 2>&1
" | crontab -

# Start supervisord and services
mkdir -p /var/log/supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
