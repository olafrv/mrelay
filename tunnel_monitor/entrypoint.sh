#!/bin/bash

function log
{
    # timestamp format is ISO 8601 to match rsyslogd format
    echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%6N%:z") $1"  # Hide $0 for security
}

IP=$(echo $MRELAY_TUNNEL_FORWARD | cut -d':' -f1)
PORT=$(echo $MRELAY_TUNNEL_FORWARD | cut -d':' -f2)

cat - > /etc/nginx/sites-available/default <<EOF
server {
    listen 443 ssl;
    server_name ${MRELAY_POSTFIX_HOSTNAME};

    ssl_certificate /etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/privkey.pem;

    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

log "starting nginx..." \
&& nginx \
&& log "starting checks..." \
&& while true; do
    nc -z -w3 $IP $PORT
    if [ $? -eq 0 ]; then
        log "OK" > /var/www/html/index.html
    else
        log "ERROR" | tee /var/www/html/index.html
    fi
    if ! pidof nginx > /dev/null; then
        log "nginx died, exiting in 60s..."
        sleep 60  # avoid fast restarts
        log "exiting..."
        exit 1
    fi
    sleep 60 # avoid CPU waste
done \
&& log "exiting..."
