#!/bin/bash

# Required for cron jobs to work
printenv | grep "^MRELAY_POSTFIX_" >> /etc/environment

# Require for syslog to save logs to /var/log
chown root:syslog /var/log
chmod 775 /var/log

# Start supervisord and services
mkdir -p /var/log/supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
