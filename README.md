# Postfix Mail Relay

## How it works?

* Remote Public Postfix Mail Relay Server:
  * Reachble via SMTP at `mail.example.com` with `10.10.10.10` private IP.
  * Internet (MTA) -> `mail.example.com:25` -> Postfix (Linux/Docker).
  * Postfix -> if relayhost for relay_domains -> `10.10.10.10:1025`.
* Local Private Mail Server (Final Destination):
  * On `10.10.10.10:1025` -> SSH Reverse Tunnel (Linux/Docker) -> `mail.lan:25`.
  * The final destination is `mail.lan:25` mail server (STMP).

## Configuration (Remote and Local Servers)

Then download install the `mrelay` tool:

```bash	
apt update && apt install -y git make
git clone https://github.com/olafrv/mrelay.git
cd mrelay
```

Create `.env` file with the following content:

```bash
MRELAY_POSTFIX_DOMAIN=example.com
# mail.example.com => Private IP: 10.10.10.10
MRELAY_POSTFIX_HOSTNAME=mail.example.com
MRELAY_POSTFIX_RELAYHOST=[mail.lan]:25
# MRELAY_POSTFIX_RELAYHOST=
MRELAY_POSTFIX_CERTBOT_CF_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MRELAY_POSTFIX_CERTBOT_CF_DNS_WAIT=30
MRELAY_POSTFIX_CERTBOT_EMAIL=ubuntu@example.com
# MRELAY_POSTFIX_CERTBOT_FLAG=--dry-run
MRELAY_POSTFIX_CERTBOT_FLAG=-
MRELAY_TUNNEL_SSH_URL=ubuntu@mail.example.com
MRELAY_TUNNEL_SSH_KEY=../id_rsa
MRELAY_TUNNEL_FORWARD=10.10.10.10:1025:mail.lan:25
DOCKER_REGISTRY=registry.example.com:8092
```


## Configuration (Remote Server)

In the public remote mail server, add the following 
settings to the `/etc/sshd/sshd_config` file:

```bash
# Allow to forward ports bound to non-localhost address
GatewayPorts yes
# Close unresponsive client (tunnel) connections after 30 seconds
ClientAliveInterval 10
ClientAliveCountMax 3
```

Then run the following commands:

```bash
# service ssh restart
systemctl restart ssh
cd mrelay
make postfix.start
# make postfix.stop
make test  # after starting the tunnel on the local server
```	

## Configuration (Private Local Server)

Then run the following command:

```bash
make tunnel.start
# make tunnel.stop
```
