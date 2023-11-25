#!/bin/bash

# Pre-hooks for supervisord apps 

chown root:syslog /var/log
chmod 775 /var/log

# Start supervisord 

mkdir -p /var/log/supervisord
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
