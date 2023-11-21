#!/bin/sh

# Set the permissions for the private key file
echo "-----------------------------------------------"
echo "$(date) Fixing permissions for private key file"
chmod 600 /id_rsa.pem
ls -l /id_rsa.pem
md5sum /id_rsa.pem

# Start the SSH tunnel
# Requires sshd_config => GatewayPorts yes
echo "$(date) Starting SSH tunnel"
ssh -i /id_rsa.pem -oStrictHostKeyChecking=no \
    -g -N -R ${MRELAY_TUNNEL_FORWARD} ${MRELAY_TUNNEL_SSH_URL}
