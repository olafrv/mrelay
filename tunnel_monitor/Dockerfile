FROM debian:buster-slim

RUN apt-get update \
    && apt-get install -y nginx openssl netcat procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
