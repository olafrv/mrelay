FROM ubuntu:23.04

RUN apt-get update \
    && apt-get install -y certbot cron postfix supervisor \
    htop vim iputils-ping dnsutils net-tools mailutils python3-certbot-dns-cloudflare \
    && rm -rf /var/lib/apt/lists/*

COPY ./supervisord.conf /supervisord.conf

COPY ./postfix.sh /
RUN chmod +x /postfix.sh

COPY ./certbot.sh /
RUN chmod +x /certbot.sh

RUN echo "0 0 * * * /certbot.sh >/dev/null 2>&1" | crontab -

WORKDIR /etc/postfix
COPY ./main.conf ./main.cf

WORKDIR /
CMD ["/usr/bin/supervisord" , "-c", "/supervisord.conf"]