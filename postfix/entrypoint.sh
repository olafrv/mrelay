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

# Require for syslog to save logs to /var/log
chown root:syslog /var/log
chmod 775 /var/log

# Fix syslog socket complain in Docker
if [ ! -e /var/spool/postfix/dev/log ]; then
    mkdir -p /var/spool/postfix/dev
    ln -s /dev/log /var/spool/postfix/dev/log
fi

# Kernel facility not available in Docker
sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Start supervisord and services
rm /run/rsyslogd.pid
mkdir -p /var/log/supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
