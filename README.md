# Postfix Mail Relay

# How it works?

* Public Remote Mail Server
  * Reachble via SMTP at mail.example.com, has <X> private IP address.
  * Internet (MTA) -> mail.example.com:25 -> Postfix (Linux/Docker)
  * Postfix -> if relayhost for relay_domains -> <X>:1025
* Private Local Servers
  * On <X>:1025 -> SSH Reverse Tunnel (Linux/Docker) -> mail.lan:25
  * The final destination is mail.lan:25 mail server

# Configuration

In the public remote mail server, add the following 
settings to the `/etc/postfix/main.cf` file:

```bash
# Allow to forward ports bound to non-localhost address
GatewayPorts yes
# Close unresponsive client (tunnel) connections after 30 seconds
ClientAliveInterval 10
ClientAliveCountMax 3
```

Then restart the SSH service:

```bash
# service ssh restart
systemctl restart ssh
```	

Create `.env` file with the following content:

```bash
MRELAY_POSTFIX_DOMAIN=example.com
MRELAY_POSTFIX_HOSTNAME=mail.example.com
MRELAY_POSTFIX_RELAYHOST=[mail.lan]:25
# MRELAY_POSTFIX_RELAYHOST=
MRELAY_POSTFIX_CERTBOT_CF_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MRELAY_POSTFIX_CERTBOT_CF_DNS_WAIT=30
MRELAY_POSTFIX_CERTBOT_EMAIL=olafrv@gmail.com
# MRELAY_POSTFIX_CERTBOT_FLAG=--dry-run
MRELAY_POSTFIX_CERTBOT_FLAG=-
MRELAY_TUNNEL_SSH_URL=ubuntu@mail.olafrv.com
MRELAY_TUNNEL_SSH_KEY=../aws_id_rsa
MRELAY_TUNNEL_FORWARD=10.0.0.10:1025:mail.lan:25
DOCKER_REGISTRY=registry.olafrv.com:8092
```

Then run:

```bash	
apt update && apt install -y git make
git clone https://github.com/olafrv/mrelay.git
cd mrelay
make install
make start   # foreground
make daemon  # background
```
