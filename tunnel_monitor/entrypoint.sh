#!/bin/bash

function log
{
    # timestamp format is ISO 8601 to match rsyslogd format
    echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%6N%:z") $1"  # Hide $0 for security
}

IP=$(echo $MRELAY_TUNNEL_FORWARD | cut -d':' -f1)
PORT=$(echo $MRELAY_TUNNEL_FORWARD | cut -d':' -f2)

cat - > /etc/nginx/nginx.conf <<EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
        worker_connections 768;
}
http {
        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        ssl_prefer_server_ciphers on;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        gzip on;
        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;

        # Limit requests to 10 per second
        limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=10r/s;
}
EOF

cat - > /etc/nginx/sites-available/default <<EOF
server {
    listen 443 ssl http2;
    server_name ${MRELAY_POSTFIX_HOSTNAME} http2;

    ssl_certificate /etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/privkey.pem;

    # Secure Nginx configuration
    ssl_protocols TLSv1.2 TLSv1.3;

    # Hide version
    server_tokens off;

    # Limit Request Size
    client_max_body_size 1k;

    location / {
        # Limit requests per second
        limit_req zone=mylimit burst=10 nodelay;
        
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
