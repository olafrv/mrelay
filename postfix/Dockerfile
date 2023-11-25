FROM ubuntu:23.04

RUN apt-get update \
    && apt-get install -y certbot cron postfix sendemail supervisor \
    htop vim iputils-ping dnsutils net-tools mailutils python3-certbot-dns-cloudflare \
    opendkim opendkim-tools rsyslog \
    && rm -rf /var/lib/apt/lists/*

COPY ./supervisord.conf /supervisord.conf
COPY ./supervisord/postfix-main.conf /etc/postfix/main.cf

COPY ./supervisord/*.sh /supervisord/
RUN chmod +x /supervisord/*.sh

RUN echo "0 0 * * * /supervisord/certbot.sh >/dev/null 2>&1" | crontab -

WORKDIR /
CMD ["/usr/bin/supervisord" , "-c", "/supervisord.conf"]
