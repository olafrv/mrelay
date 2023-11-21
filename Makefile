include .env
export

start:
	docker compose -f docker-compose.yaml up --build || true

daemon:
	docker compose -f docker-compose.yaml up -d --build || true

install:
	bash install.sh