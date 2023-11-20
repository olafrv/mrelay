#!/bin/bash

# Parameters:
# "--force-renewal"
# "--force-renewal -vv"
# "--force-renewal --dry-run"

# Renew the certificate via certbot with the Cloudflare DNS plugin
echo "dns_cloudflare_api_token=$MRELAY_CLOUDFLARE_API_KEY" > /cloudflare.ini
chmod 600 /cloudflare.ini  # certbot will complain if permissions are too open

certbot certonly $1 --no-self-upgrade \
    -d $MRELAY_POSTFIX_DOMAIN -d $MRELAY_POSTFIX_HOSTNAME \
    -m $MRELAY_CERTBOT_EMAIL \
    --dns-cloudflare --dns-cloudflare-credentials /cloudflare.ini \
    --dns-cloudflare-propagation-seconds 30 \
    --noninteractive \
    --agree-tos \
    --deploy-hook "postfix reload"

# Remove the Cloudflare DNS plugin credentials
rm /cloudflare.ini