include .env
export

env:
	@ env | grep -E "MRELAY_" || (echo "MRELAY_ variables not set." && exit 1)

postfix.image:
	@ # https://github.com/docker/hub-feedback/issues/1925
	@ docker buildx imagetools inspect \
		${DOCKER_REGISTRY}/mrelay_postfix:latest | grep -B2 "Platform:.*linux"

postfix.run:
	docker compose -f ./postfix/docker-compose.yaml up --build --remove-orphans

postfix.start: postfix.image
	docker pull ${DOCKER_REGISTRY}/mrelay_postfix:latest
	docker compose -f ./postfix/docker-compose.yaml up --detach

postfix.stop:
	docker compose -f ./postfix/docker-compose.yaml down

postfix.sh:
	docker exec -it mrelay_postfix /bin/bash

postfix.certs.list:
	@ docker exec mrelay_postfix bash -c "certbot certificates"

postfix.certs.renew:
	@ docker exec mrelay_postfix bash -c "./supervisord/certbot.sh"

postfix.certs.renew.force:
	@ docker exec mrelay_postfix bash -c "MRELAY_POSTFIX_CERTBOT_FLAG=--force-renewal ./supervisord/certbot.sh"

tunnel.run:
	docker compose -f ./tunnel/docker-compose.yaml up --detach --build

tunnel.start:
	docker pull ${DOCKER_REGISTRY}/mrelay_tunnel:latest
	docker compose -f ./tunnel/docker-compose.yaml up -d

tunnel.stop:
	docker compose -f ./tunnel/docker-compose.yaml down

tunnel.sh:
	docker exec -it mrelay_tunnel /bin/bash

tunnel.monitor.run:
	docker compose -f ./tunnel_monitor/docker-compose.yaml up --detach --build

tunnel.monitor.start:
	docker pull ${DOCKER_REGISTRY}/mrelay_tunnel_monitor:latest
	docker compose -f ./tunnel_monitor/docker-compose.yaml up --detach

tunnel.monitor.stop:
	docker compose -f ./tunnel_monitor/docker-compose.yaml down

tunnel.monitor.sh:
	docker exec -it mrelay_tunnel_monitor /bin/bash

tunnel.monitor.certs.check:
	@ docker exec mrelay_tunnel_monitor bash -c "ls -l /etc/letsencrypt/live/\${MRELAY_POSTFIX_DOMAIN}/"
	@ docker exec mrelay_tunnel_monitor bash -c "openssl s_client -connect \${MRELAY_POSTFIX_HOSTNAME}:443 -servername \${MRELAY_POSTFIX_HOSTNAME} 2>/dev/null < /dev/null | openssl x509 -text"

build:
	if ! docker buildx ls | grep multi-arch-builder; \
	then \
		docker buildx create --name multi-arch-builder; \
	fi
	# This is the way, build+push multi-arch images (amd64, arm64)
	docker buildx build \
		--build-arg "MRELAY_TIMEZONE=${MRELAY_TIMEZONE}" \
		--push --platform linux/amd64,linux/arm64 \
		-t ${DOCKER_REGISTRY}/mrelay_postfix:latest ./postfix
	docker buildx build \
		--push --platform linux/amd64,linux/arm64 \
		-t ${DOCKER_REGISTRY}/mrelay_tunnel_monitor:latest ./tunnel_monitor
	docker build -t ${DOCKER_REGISTRY}/mrelay_tunnel:latest ./tunnel
	docker push ${DOCKER_REGISTRY}/mrelay_tunnel:latest

push: build

dns.dkim:
	@ echo "--- DKIM ---"
	@ echo "List of local DKIM public keys for '${MRELAY_POSTFIX_DOMAIN}':"
	@ docker exec mrelay_postfix bash -c "find '/etc/opendkim/keys/' -name '*.txt' | grep '${MRELAY_POSTFIX_DOMAIN}' | xargs -n1 cat"
	@ echo "Testing DKIM public key for '${MRELAY_POSTFIX_DOMAIN}':"
	@ docker exec mrelay_postfix bash -c "opendkim-testkey -d ${MRELAY_POSTFIX_DOMAIN} -vvv"
	@ echo "NOTE: Key not secure means that is not protected via DNSSEC."

dns.spf:
	@ echo "--- SPF ---"
	@ echo "List of public SPF records for '${MRELAY_POSTFIX_DOMAIN}':"
	dig +short TXT ${MRELAY_POSTFIX_DOMAIN} | grep spf
	@ echo "To go live your SPF record should use '-all', for example:"
	@ echo "\"v=spf1 mx -all\"  # Only MX servers are allowed, other rejected."
	@ echo "See https://www.spf-record.com/ for more details."

dns.dmarc:
	@ echo "--- DMARC ---"
	@ echo "List of public DMARC records for '${MRELAY_POSTFIX_DOMAIN}':"
	dig +short TXT _dmarc.${MRELAY_POSTFIX_DOMAIN} | grep dmarc
	@ echo "To go live your DMARC record should use progressively, for example:"
	@ echo "\"v=DMARC1; p=none; rua=mailto:postmaster@${MRELAY_POSTFIX_DOMAIN};\""
	@ echo "\"v=DMARC1; p=quarantine; pct=10; rua=mailto:postmaster@${MRELAY_POSTFIX_DOMAIN};\""
	@ echo "\"v=DMARC1; p=reject; pct=10; rua=mailto:postmaster@${MRELAY_POSTFIX_DOMAIN};\""
	@ echo "\"v=DMARC1; p=reject; pct=100; rua=mailto:postmaster@${MRELAY_POSTFIX_DOMAIN};\""
	@ echo "\"v=DMARC1; p=reject; pct=100; adkim=s; aspf=s; rua=mailto:postmaster@${MRELAY_POSTFIX_DOMAIN};\""
	@ echo "See https://dmarc.org/overview/ and https://dmarc.org/resources/deployment-tools/ for more details."

dns: dns.dkim dns.spf dns.dmarc

test:
	if ! which sendemail; \
	then \
		apt-get install -y sendemail; \
	fi
	bash ./postfix/test.sh

install.docker:
	bash ./install-docker.sh

