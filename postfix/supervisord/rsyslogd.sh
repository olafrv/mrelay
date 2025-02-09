#!/bin/bash

# Fix syslog socket complain in Docker
if [ ! -e /var/spool/postfix/dev/log ]; then
    mkdir -p /var/spool/postfix/dev
    ln -s /dev/log /var/spool/postfix/dev/log
fi

# Kernel facility not available in Docker
sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Require for syslog to save logs to /var/log
chown root:syslog /var/log
chmod 775 /var/log

# Remove pid file if it exists
[ -f /run/rsyslogd.pid ] && rm /run/rsyslogd.pid

exec /usr/sbin/rsyslogd -n