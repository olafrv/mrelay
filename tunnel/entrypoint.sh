#!/bin/sh

# SSH complains if wrong permissions on used files
echo "$(date) Fixing permissions for private key file"
chmod 600 /id_rsa.pem
ls -l /id_rsa.pem
md5sum /id_rsa.pem

# Server Parameters to close unresponsive tunnels:
# See details add https://man.openbsd.org/sshd_config
# Add this to /etc/sshd/sshd_config file:
#   - GatewayPorts yes
#   - ClientAliveInterval 10
#   - ClientAliveMaxCount 3

# Client Parameters to close unresponsive tunnels:
# See details at https://man.openbsd.org/ssh_config
echo "$(date) Starting SSH tunnel"
ssh -i /id_rsa.pem -oStrictHostKeyChecking=no \
    -oServerAliveInterval=10 \
    -oServerAliveCountMax=3 \
    -oExitOnForwardFailure=yes \
    -g -N -R ${MRELAY_TUNNEL_FORWARD} ${MRELAY_TUNNEL_SSH_URL}
echo "$(date) SSH tunnel stopped"
