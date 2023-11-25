FROM ubuntu:23.04

RUN apt-get update \
    && apt-get install -y cron certbot python3-certbot-dns-cloudflare postfix \
    postfix-policyd-spf-python sendemail opendkim opendkim-tools supervisor \
    rsyslog htop vim iputils-ping dnsutils net-tools mailutils locales \
    && locale-gen en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./supervisord/postfix-main.conf /etc/postfix/main.cf
# COPY ./supervisord/postfix-master.conf /etc/postfix/master.cf  # saved for later
COPY ./supervisord/*.sh /supervisord/
RUN chmod +x /supervisord/*.sh
RUN echo "0 0 * * * /supervisord/certbot.sh >/dev/null 2>&1" | crontab -
RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

WORKDIR /

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["bash"]
