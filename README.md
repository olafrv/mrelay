# Postfix Mail Relay

Create `.env` file with the following content:

```bash
MRELAY_LETENCRYPT_DIR=./mount/letenycrypt
MRELAY_POSTFIX_DIR=./mount/postfix
MRELAY_POSTFIX_HOSTNAME=mail.example.com
MRELAY_POSTFIX_RELAYHOST=relay.example.com
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
