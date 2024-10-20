# Postfix Mail Relay

## How it works?

* Remote Public Postfix Mail Relay Server:
  * Reachble via SMTP at `mail.example.com` with `10.10.10.10` private IP.
  * Internet (MTA) -> (StartTLS) `mail.example.com:25` -> Postfix (Linux/Docker).
  * Postfix -> if relayhost for relay_domains -> `10.10.10.10:1025`.
* Local Private Mail Server (Final Destination):
  * SMTP `mail.example.lan:25` is the final destination mail server (SMTP).
  * If you prefer SSH Reverse Tunnel:
    * On `10.10.10.10:1025` -> SSH Reverse Tunnel (Linux/Docker) -> Local SMTP.
    * The remote server can connect to the local server via SSH tunnel.
    * DNS resolution for mail.example.lan is needed on the local server.
  + If your prefer Tailscale VPN:
    * On `10.10.10.10:1025` -> TailScale -> Client TailScale VPN -> Local SMTP.
    * Both the remote and local can see each other via the TailScale VPN.
    * The local server is reachable via the TailScale private IP address.
* Includes Realtime Blackhole List (RBL) rejection with Spamhaus.
* Includes SPF verification and OpenDKIM signing/verification.
* (Optional) Includes SSH reverse tunnel monitor Web endpoint.
* See references for more information.

## Configuration (Remote and Local Servers)

Download install the `mrelay` tool:
```bash
apt install make git  # If you don't have it
git clone https://github.com/olafrv/mrelay.git
cd mrelay
# If you don't have it (latest docker official version)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/olafrv/my_collections/refs/heads/main/scripts/bash/install-docker.sh)"
```

## Environment Variables

Create the `.env` file `VARIABLE=VALUE` even if empty `VARIABLE=` with the variable content:

| Variable                           | Example Value                        | Description                                                       |
|------------------------------------|--------------------------------------|-------------------------------------------------------------------|
| DOCKER_REGISTRY                    | docker.io/olafrv                     | The Docker registry to pull the mrelay image from.                |
| MRELAY_TIMEZONE                    | `Europe/Stockholm`                   | The timezone for the container.                                   |
| MRELAY_POSTFIX_DOMAIN              | `example.com`                        | The domain name for the Postfix mail server.                      |
| MRELAY_POSTFIX_HOSTNAME            | `mail.example.com`                   | The hostname (MX) for the Postfix mail server.                    |
| MRELAY_POSTFIX_RELAYHOST           | `[mail.example.lan]:25` or empty     | The relay host of the Postfix mail server. Empty disables relay.  |
| MRELAY_POSTFIX_CERTBOT_CF_API_KEY  | See *References* for deetails        | The Cloudflare API key for Certbot DNS authentication.            |
| MRELAY_POSTFIX_CERTBOT_CF_DNS_WAIT | 30                                   | The wait time in seconds for Certbot DNS authentication.          |
| MRELAY_POSTFIX_CERTBOT_EMAIL       | joe@example.com                      | The email address for Certbot cloudflare notifications.           |
| MRELAY_POSTFIX_CERTBOT_FLAG        | e.g. `--dry-run` or empty            | Additional flags for Certbot.                                     |
| MRELAY_POSTFIX_SPAMHAUS_KEY        | See *References* for details         | Spamhaus Data Query Service (DQS) key for RBL rejection.          |
| MRELAY_POSTFIX_DKIM_SELECTOR       | e.g. `default`                       | DKIM selector for OpenDKIM signing/verification.                  |
| MRELAY_TUNNEL_SSH_URL              | joe@mail.example.com                 | The SSH URL for the tunnel from the private local rely server.    |
| MRELAY_TUNNEL_SSH_KEY              | ../id_rsa                            | The SSH private key file to connect to the public server          |
| MRELAY_TUNNEL_FORWARD              | 10.10.10.10:1025:mail.example.lan:25 | The port forwarding configuration for the tunnel.                 |

## Configuration (Public Remote Server)

### SSH Server Configuration

>> **Note:** This is only needed if you are not using Tailscale VPN.

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
systemctl restart ssh       # or service ssh restart (apply previous changes)
```

### Postfix Server Configuration

```bash	

cd mrelay
make postfix.start          # start the container
make postfix.sh             # enter the shell inside the container
make dns                    # to print DNS records needed for SPF and DKIM
make test                   # works only after starting the tunnel
make postfix.stop           # stop the containers
# make postfix.run          # build and run in foreground (development)
```	

To check the SSL certificates, run the following command:

```bash
make postfix.certs.list
make postfix.certs.renew
make postfix.certs.renew.force
```

### Tunnel Monitor Configuration

>> **Note:** This is only needed if you are not using Tailscale VPN.

```bash	
make tunnel.monitor.start   # start the tunnel monitor (TCP open/close)
make tunnel.monitor.stop    # stop the tunnel monitor
make tunnel.sh              # enter the shell inside the container
# make tunnel.monitor.run   # build and run in in foreground (development)
```	

The tunnel monitor can be accessed at `https://mail.example.com/index.html`.

Its content will have `OK` or `ERROR` if the TCP port  `10.10.10.10:1025`
is open or closed, respectively.

To check the SSL certificates, run the following command:

```bash
make tunnel.monitor.certs.check
```

## Configuration (Private Local Server)

### Tunnel Client Configuration

>> **Note:** This is only needed if you are not using Tailscale VPN.

Then run the following command:

```bash
make tunnel.start  # start the container
make tunnel.sh     # enter the shell inside the container
make tunnel.stop   # stop the containers
# make tunnel.run  # build and run in foreground (development)
```

## Monitoring and Alerting

You can use [Uptime Kuma](https://github.com/louislam/uptime-kuma) for
monitoring the tunnel monitor HTTP endpoint and/or the postfix SMTP ports.

## Development

To build the Docker images locally, run the following command:

```bash
make build   # Build the Docker images locally x86_64 and arm64
make push    # Push the Docker images to the registry
```

# References

## Certbot SSL Certificates (and DNS Plugins)

* https://eff-certbot.readthedocs.io/en/latest/using.html#manual
* https://eff-certbot.readthedocs.io/en/latest/using.html#dns-plugins
* https://certbot-dns-cloudflare.readthedocs.io/en/stable/
* https://letsencrypt.org/

## OpenSSH Client and Server Configuration

* https://man.openbsd.org/ssh_config
* https://man.openbsd.org/sshd_config

## TailScale VPN

* https://tailscale.com/kb/1151/what-is-tailscale
* https://tailscale.com/kb/1031/install-linux

## Tackling E-Mail Spoofing and Phishing

* https://blog.cloudflare.com/tackling-email-spoofing/

## SPAMHAUS Data Query Service (DQS):

* https://www.spamhaus.org/faq/section/DNSBL%20Usage
* https://www.spamhaus.com/free-trial/sign-up-for-a-free-data-query-service-account/

## Mail Server Checks (Online Tools)

* https://mxtoolbox.com/
* https://www.spf-record.com/
* https://dmarc.org/resources/deployment-tools/

## Sender Policy Framework (SPF)

* https://www.cloudflare.com/learning/dns/dns-records/dns-spf-record/
* https://datatracker.ietf.org/doc/html/rfc7208
* https://www.spf-record.com/

## DomainKeys Identified Mail (DKIM)

* https://www.cloudflare.com/learning/dns/dns-records/dns-dkim-record/
* https://linux.die.net/man/8/opendkim
* https://linux.die.net/man/5/opendkim.conf
* https://datatracker.ietf.org/doc/html/rfc6376

## Domain-based Message Authentication, Reporting & Conformance (DMARC)

* https://www.cloudflare.com/learning/dns/dns-records/dns-dkim-record/
* https://dmarc.org/overview/
* https://dmarc.org/resources/specification/
