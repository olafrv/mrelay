#!/bin/bash

set -e  # exit on error
trap 'echo "Error on line $LINENO"' ERR

source /supervisord/common.sh  # common functions

# Potfix chroot jail (for readability)
POSTFIX_CHROOT=/var/spool/postfix

# Add resolv.conf to Postfix chroot jail
mkdir -p ${POSTFIX_CHROOT}/etc
cp /etc/resolv.conf ${POSTFIX_CHROOT}/etc/resolv.conf

# In the main.cf file, the following defaults rules apply:
# mydomain => Defaults to $myhostname (without subdomain.)
# myhostname => Defaults to FQDN gethostname() !!!
# myorigin => Default to $myhostname (FQDN)

log "Setting up Postfix..."

# Set the hostname to the specified FQDN (gethostname() could be useless)
postconf -e "MRELAY_POSTFIX_HOSTNAME=${MRELAY_POSTFIX_HOSTNAME}"
postconf -e 'myhostname = $MRELAY_POSTFIX_HOSTNAME'

# Do not use FQDN in FROM for outgoing mails (e.g @mail.domain.com)
postconf -e 'myorigin = $mydomain'
postconf -e 'masquerade_domains = $mydomain'  # Mask to: @domain.com

# Conditionally set the relayhost
pubdoms='$mydomain, $myhostname'  # public domains
locdoms='localhost, localhost.localdomain, 127.0.0.1'  # local domains
if [ -z "${MRELAY_POSTFIX_RELAYHOST}" ]
then
    # Act as primary MX

    postconf -e "mydestination = $pubdoms, $locdoms"
else
    # Act as relay MX
    postconf -e "MRELAY_POSTFIX_RELAYHOST=${MRELAY_POSTFIX_RELAYHOST}"
    postconf -e "mydestination = $locdoms" # local delivered
    postconf -e "relay_domains = $pubdoms" # authorized relays
    postconf -e 'relayhost = $MRELAY_POSTFIX_RELAYHOST'
fi

# Set TLS certificates paths
d='/etc/letsencrypt/live'  # Let's Encrypt Directory (Live)
postconf -e "smtpd_tls_cert_file=${d}/${MRELAY_POSTFIX_DOMAIN}/fullchain.pem"
postconf -e "smtpd_tls_key_file=${d}/${MRELAY_POSTFIX_DOMAIN}/privkey.pem"

# https://www.spamhaus.org/organization/dnsblusage/
# https://www.spamhaus.org/whitepapers/dnsbl_function/
# https://docs.spamhaus.com/datasets/docs/source/40-real-world-usage/index.html
classes="reject_spamhaus_client, reject_spamhaus_helo, reject_spamhaus_sender"
postconf -e "smtpd_restriction_classes = $classes"
if [ -z "${MRELAY_POSTFIX_SPAMHAUS_KEY}" ]
then
    postconf -e "reject_spamhaus_client ="
    postconf -e "reject_spamhaus_helo ="
    postconf -e "reject_spamhaus_sender ="
else
    sph='dq.spamhaus.net'
    zen="${MRELAY_POSTFIX_SPAMHAUS_KEY}.zen.${sph}"
    dbl="${MRELAY_POSTFIX_SPAMHAUS_KEY}.dbl.${sph}"
    zrd="${MRELAY_POSTFIX_SPAMHAUS_KEY}.zrd.${sph}"
    cat - >> /etc/postfix/main.cf <<EOF
reject_spamhaus_client = 
    , reject_rbl_client ${zen}=127.0.0.[2..11]
    , reject_rhsbl_reverse_client ${dbl}=127.0.1.[2..99]
    , reject_rhsbl_reverse_client ${zrd}=127.0.2.[2..24]
reject_spamhaus_helo =
    , reject_rhsbl_helo ${dbl}=127.0.1.[2..99]
    , reject_rhsbl_helo ${zrd}=127.0.2.[2..24]
reject_spamhaus_sender =
    , reject_rhsbl_sender ${dbl}=127.0.1.[2..99]
    , reject_rhsbl_sender ${zrd}=127.0.2.[2..24]
EOF
fi

# Allow localhost to send mails (e.g. from/to 'root@localhost')
# See smtpd_*_restrictions in /etc/postfix/main.cf
cat - > /etc/postfix/access_localhost_unrestricted <<EOF
127.0.0.1 OK
::1 OK
EOF
postmap /etc/postfix/access_localhost_unrestricted

# Allow the specified private networks to send mails (e.g. client wo/FQDN)
# See smtpd_*_restrictions in /etc/postfix/main.cf
cat - > /etc/postfix/access_private_networks_unrestricted <<EOF
10.0.0.0/8 OK
172.16.0.0/12 OK
192.168.0.0/16 OK
EOF

# Avoid external MAIL FROM (envelope sender) spoofing
cat -> /etc/postfix/access_sender_no_spoofing <<EOF
olafrv.com REJECT "No spoofing"
mail.olafrv.com REJECT "No spoofing"
EOF
postmap /etc/postfix/access_sender_no_spoofing

# Add SPF Policy python script to Postfix programs
# See smtpd_*_restrictions in /etc/postfix/main.cf
cat - >> /etc/postfix/master.cf <<EOF
#
# SPF Policy Check
#
policyd-spf  unix  -       n       n       -       0       spawn
    user=policyd-spf argv=/usr/bin/policyd-spf
EOF

# Save DMARC email reports to folder
# for later processing by OpenDMARC
dmarc_reports_dir=${POSTFIX_CHROOT}/opendmarc
mkdir -p ${dmarc_reports_dir}
chmod 770 ${dmarc_reports_dir}
chown opendmarc:opendmarc ${dmarc_reports_dir}

cat - > /etc/postfix/dmarc_mail_save.sh <<EOF
#!/bin/bash
ts=\$(date +%Y%m%d_%H%M%S)_\$RANDOM
fp="${dmarc_reports_dir}/\${ts}_dmarc.eml"
echo "to: \$fp"
cat > "\$fp"
EOF
chmod +x /etc/postfix/dmarc_mail_save.sh

cat - >> /etc/postfix/master.cf <<EOF
#
# DMARC Reports Save To Folder sScript
#
dmarc_transport unix - n n - - pipe flags=F 
    user=opendmarc argv=/etc/postfix/dmarc_mail_save.sh
EOF

cat - >> /etc/postfix/dmarc_transport_map <<EOF
dmarc@${MRELAY_POSTFIX_DOMAIN} dmarc_transport:
EOF
postmap /etc/postfix/dmarc_transport_map
postconf -e "transport_maps = hash:/etc/postfix/dmarc_transport_map"

# Mail Filters
cat - >> /etc/postfix/main.cf <<EOF
# https://www.postfix.org/MILTER_README.html

# Local filters
# custom_spf_milter=inet:localhost:9010
custom_dkim_milter=inet:localhost:9020
custom_dmarc_milter=inet:localhost:9030

# Enabled mail filters
milter_protocol=6
milter_default_action=accept
smtpd_milters=\${custom_dkim_milter}, \${custom_dmarc_milter}
non_smtpd_milters=\$smtpd_milters

# To sign Postfix's own bounce messages, enable filtering of 
# internally-generated bounces and don't reject any internally-generated
# bounces with non_smtpd_milters,  header_checks or body_checks
internal_mail_filter_classes=bounce
EOF

# Request a certificate from Let's Encrypt DNS-01 challenge
# See /var/log/letsencrypt/letsencrypt.log for details
log "Requesting certificate from Let's Encrypt..."
bash /supervisord/certbot.sh >/dev/null 2>&1

# postfix/postfix-script: fatal: Postfix integrity check failed!
# postsuper: fatal: scan_dir_push: open directory defer: Permission denied
# postfix set-permissions

log "Checking Postfix config..."
if /usr/sbin/postfix check
then
    log "Postfix config OK"
    # Call "postfix stop" when signaled SIGTERM
    trap "{ log 'Stopping postfix'; /usr/sbin/postfix stop; exit 0; }" EXIT
    # Start postfix in foreground mode
    /usr/sbin/postfix -c /etc/postfix start-fg
else
    log "Postfix config error"
    exit 1
fi
