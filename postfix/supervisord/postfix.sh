#!/bin/bash

# Required for the certbot cron job to work
printenv | grep "^MRELAY_POSTFIX_" >> /etc/environment

# In the main.cf file, the following defaults rules apply:
# mydomain => Defaults to $myhostname (without subdomain.)
# myhostname => Defaults to FQDN gethostname() !!!
# myorigin => Default to $myhostname (FQDN)

# Set the hostname to the specified FQDN (gethostname() could be useless)
postconf -e "MRELAY_POSTFIX_HOSTNAME=${MRELAY_POSTFIX_HOSTNAME}"  # set the hostname
postconf -e 'myhostname = $MRELAY_POSTFIX_HOSTNAME'

# Set the the origin for outbound mails to "user@$mydomain"
postconf -e 'myorigin = $mydomain'

# Conditionally set the relayhost
if [ -z "${MRELAY_POSTFIX_RELAYHOST}" ]
then
    # Act as primary MX
    postconf -e 'mydestination = $mydomain, $myhostname, localhost, localhost.localdomain, 127.0.0.1'
else
    # Act as relay MX
    postconf -e "MRELAY_POSTFIX_RELAYHOST=${MRELAY_POSTFIX_RELAYHOST}"  # set the relayhost
    postconf -e 'mydestination = localhost, localhost.localdomain, 127.0.0.1'
    postconf -e 'relay_domains = $mydomain, $myhostname'
    postconf -e 'relayhost = $MRELAY_POSTFIX_RELAYHOST'
fi


# Set the certificate path for starttls
postconf -e smtpd_tls_cert_file=/etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/fullchain.pem
postconf -e smtpd_tls_key_file=/etc/letsencrypt/live/${MRELAY_POSTFIX_DOMAIN}/privkey.pem

# https://www.spamhaus.org/organization/dnsblusage/
# https://www.spamhaus.org/whitepapers/dnsbl_function/
# https://docs.spamhaus.com/datasets/docs/source/40-real-world-usage/MTAs/020-Postfix.html
postconf -e "smtpd_restriction_classes = reject_spamhaus"
if [ -z "${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}" ]
then
    postconf -e "reject_spamhaus = permit"
else
    cat - >> /etc/postfix/main.cf <<EOF
reject_spamhaus = reject_rbl_client ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.zen.dq.spamhaus.net=127.0.0.[2..11]
    , reject_rhsbl_sender ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.dbl.dq.spamhaus.net=127.0.1.[2..99]
    , reject_rhsbl_helo ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.dbl.dq.spamhaus.net=127.0.1.[2..99]
    , reject_rhsbl_reverse_client ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.dbl.dq.spamhaus.net=127.0.1.[2..99]
    , reject_rhsbl_sender ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.zrd.dq.spamhaus.net=127.0.2.[2..24]
    , reject_rhsbl_helo ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.zrd.dq.spamhaus.net=127.0.2.[2..24]
    , reject_rhsbl_reverse_client ${MRELAY_POSTFIX_SPAMHAUS_DQS_KEY}.zrd.dq.spamhaus.net=127.0.2.[2..24]
    , permit
EOF
fi

# Request a certificate from Let's Encrypt DNS-01 challenge
# See /var/log/letsencrypt/letsencrypt.log for details
bash /certbot.sh >/dev/null 2>&1

# Add resolv.conf to Postfix chroot jail
mkdir -p /var/spool/postfix/etc
cp /etc/resolv.conf /var/spool/postfix/etc/resolv.conf

# postfix/postfix-script: fatal: Postfix integrity check failed!
# postsuper: fatal: scan_dir_push: open directory defer: Permission denied
postfix set-permissions

# Start Postfix in foreground
postfix start-fg