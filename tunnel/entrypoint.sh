#!/bin/sh

function log
{
    # timestamp format is ISO 8601 to match rsyslogd format
    echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%6N%:z") $0 - $1"
}

# SSH complains if wrong permissions on used files
log "Fixing permissions for private key file"
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
log "Starting SSH tunnel"
ssh -i /id_rsa.pem -oStrictHostKeyChecking=no \
    -oServerAliveInterval=10 \
    -oServerAliveCountMax=3 \
    -oExitOnForwardFailure=yes \
    -g -N -R ${MRELAY_TUNNEL_FORWARD} ${MRELAY_TUNNEL_SSH_URL}
log "SSH tunnel stopped"
