#!/bin/sh

# Set the permissions for the private key file

echo "$(date) Fixing permissions for private key file"
chmod 600 /id_rsa.pem
ls -l /id_rsa.pem
md5sum /id_rsa.pem

# Start the SSH tunnel
# https://man.openbsd.org/ssh_config#ServerAliveInterval
# Requires sshd_config to close unresponsive tunnels:
#   - GatewayPorts yes
#   - ClientAliveInterval 10
#   - ClientAliveMaxCount 3

echo "$(date) Starting SSH tunnel"
ssh -i /id_rsa.pem -oStrictHostKeyChecking=no \
    -oServerAliveInterval=10 \
    -oServerAliveCountMax=3 \
    -oExitOnForwardFailure=yes \
    -g -N -R ${MRELAY_TUNNEL_FORWARD} ${MRELAY_TUNNEL_SSH_URL}
echo "$(date) SSH tunnel stopped"
