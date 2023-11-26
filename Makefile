include .env
export

env:
	@ env | grep -E "MRELAY"

postfix.daemon:
	docker compose -f ./postfix/docker-compose.yaml up -d

postfix.start:
	docker compose -f ./postfix/docker-compose.yaml up -d --build

postfix.stop:
	docker compose -f ./postfix/docker-compose.yaml down

postfix.sh:
	docker exec -it mrelay_postfix /bin/bash

tunnel.start:
	docker compose -f ./tunnel/docker-compose.yaml up --detach --build 

tunnel.stop:
	docker compose -f ./tunnel/docker-compose.yaml down

tunnel.sh:
	docker exec -it mrelay_tunnel /bin/bash

build:
	if ! docker buildx ls | grep multi-arch-builder; \
	then \
		docker buildx create --name multi-arch-builder; \
	fi
	docker buildx build --push --platform linux/amd64 -t ${DOCKER_REGISTRY}/mrelay_postfix:amd64 ./postfix
	docker buildx build --push --platform linux/arm64 -t ${DOCKER_REGISTRY}/mrelay_postfix:arm64 ./postfix
	docker build -t ${DOCKER_REGISTRY}/mrelay_tunnel:latest ./tunnel
	docker push ${DOCKER_REGISTRY}/mrelay_tunnel:latest

test:
	@ bash test.sh

install:
	bash install.sh

