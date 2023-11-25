# Postfix Mail Relay

## How it works?

* Remote Public Postfix Mail Relay Server:
  * Reachble via SMTP at `mail.example.com` with `10.10.10.10` private IP.
  * Internet (MTA) -> (StartTLS) `mail.example.com:25` -> Postfix (Linux/Docker).
  * Postfix -> if relayhost for relay_domains -> `10.10.10.10:1025`.
* Local Private Mail Server (Final Destination):
  * On `10.10.10.10:1025` -> SSH Reverse Tunnel (Linux/Docker) -> `mail.example.lan:25`.
  * The final destination is `mail.example.lan:25` mail server (SMTP).
* Includes Realtime Blackhole List (RBL) rejection with Spamhaus.
* Includes SPF verification and OpenDKIM signing/verification.
* See references for more information on the last two points.

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
MRELAY_POSTFIX_HOSTNAME=mail.example.com
MRELAY_POSTFIX_RELAYHOST=[mail.example.lan]:25
# Empty to disable relay and deliver to localhost
# MRELAY_POSTFIX_RELAYHOST=
MRELAY_POSTFIX_CERTBOT_CF_API_KEY=xxxxxxxxxxxxx
MRELAY_POSTFIX_CERTBOT_CF_DNS_WAIT=30
MRELAY_POSTFIX_CERTBOT_EMAIL=joe@example.com
# http://certbot-dns-cloudflare.readthedocs.io/en/stable/
# MRELAY_POSTFIX_CERTBOT_FLAG=--dry-run
MRELAY_POSTFIX_CERTBOT_FLAG=
# https://www.spamhaus.com/free-trial/sign-up-for-a-free-data-query-service-account/
MRELAY_POSTFIX_SPAMHAUS_DQS_KEY=xxxxxxxxxxxxx
MRELAY_POSTFIX_DKIM_SELECTOR=default
MRELAY_TUNNEL_SSH_URL=joe@mail.example.com
MRELAY_TUNNEL_SSH_KEY=../id_rsa
MRELAY_TUNNEL_FORWARD=10.10.10.10:1025:mail.example.lan:25
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
make postfix.sh  # enter the container shell
make test  # after starting the tunnel on the local server
# make postfix.stop
```	

## Configuration (Private Local Server)

Then run the following command:

```bash
make tunnel.start
make tunnel.sh  # enter the container shell
# make tunnel.stop
```

# References

* Tackling E-Mail Spoofing and Phishing: 
  * https://blog.cloudflare.com/tackling-email-spoofing/
* Online Tools for Check mail server configuration:
  * https://mxtoolbox.com/
  * https://www.mimecast.com/products/dmarc-analyzer/spf-record-check/
* Sender Policy Framework (SPF):
  * https://www.cloudflare.com/learning/dns/dns-records/dns-spf-record/
  * https://www.mimecast.com/content/how-to-create-an-spf-txt-record/
* DomainKeys Identified Mail (DKIM):
  * https://www.cloudflare.com/learning/dns/dns-records/dns-dkim-record/
  * https://linux.die.net/man/8/opendkim
  * https://linux.die.net/man/5/opendkim.conf
* Domain-based Message Authentication, Reporting & Conformance (DMARC): 
  * https://www.cloudflare.com/learning/dns/dns-records/dns-dkim-record/
