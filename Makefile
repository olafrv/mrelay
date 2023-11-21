include .env
export

env:
	@ env | grep -E "MRELAY"

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

push:
	docker push ${DOCKER_REGISTRY}/mrelay_postfix:latest
	docker push ${DOCKER_REGISTRY}/mrelay_tunnel:latest

test:
	bash test.sh

install:
	bash install.sh

