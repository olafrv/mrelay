#!/bin/bash

# Required for the cron job to work
printenv | grep "^MRELAY_" >> /etc/environment

# Set environment variables into Postfix configuration
postconf -e MRELAY_POSTFIX_HOSTNAME=$MRELAY_POSTFIX_HOSTNAME
postconf -e MRELAY_POSTFIX_RELAYHOST=$MRELAY_POSTFIX_RELAYHOST

# Set the certificate path into Postfix configuration
postconf -e smtpd_tls_cert_file=/etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/fullchain.pem
postconf -e smtpd_tls_key_file=/etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/privkey.pem

# Request a certificate from Let's Encrypt DNS-01 challenge
# See /var/log/letsencrypt/letsencrypt.log for details
bash /certbot.sh >/dev/null 2>&1

# Add resolv.conf to Postfix chroot jail
mkdir -p /var/spool/postfix/etc
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

# Start Postfix in foreground
postfix start-fg
