#!/bin/bash

# Renew the certificate via certbot with the Cloudflare DNS plugin
echo "dns_cloudflare_api_token=${MRELAY_POSTFIX_CERTBOT_CF_API_KEY}" \
 > /cloudflare.ini

# Certbot will complain if permissions are too open
chmod 600 /cloudflare.ini  

# Request new (or renew) the (existing) certificate
certbot certonly ${MRELAY_POSTFIX_CERTBOT_FLAG} --no-self-upgrade \
  -d "${MRELAY_POSTFIX_DOMAIN}" -d "${MRELAY_POSTFIX_HOSTNAME}" \
  -m "${MRELAY_POSTFIX_CERTBOT_EMAIL}" \
  --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini \
  --dns-cloudflare-propagation-seconds ${MRELAY_POSTFIX_CERTBOT_CF_DNS_WAIT} \
  --noninteractive \
  --agree-tos \
  --deploy-hook "postfix reload"

# Remove the Cloudflare DNS plugin credentials
rm /cloudflare.ini
