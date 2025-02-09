FROM ubuntu:23.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y \
        locales supervisor cron rsyslog \
        certbot python3-certbot-dns-cloudflare \
        postfix postfix-policyd-spf-python opendkim opendkim-tools \
        sendemail mailutils \
        htop vim iputils-ping dnsutils net-tools curl \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS opendmarc

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y \
        ca-certificates \
        autoconf automake gcc g++ libc-dev libtool make \
        libmilter-dev libmilter1.0.1 curl \
    && update-ca-certificates \
    && curl -fL -o /tmp/opendmarc.tar.gz \
    https://github.com/trusteddomainproject/OpenDMARC/archive/refs/tags/rel-opendmarc-1-4-2.tar.gz \
    && tar -xzf /tmp/opendmarc.tar.gz -C /tmp/ \
    && cd /tmp/OpenDMARC-* \
    && autoreconf -v -i \
    && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/opendmarc \
        # documentation will be deleted with rm -rf /tmp/OpenDMARC-*
        --docdir=/tmp/opendmarc/doc \
        --infodir=/tmp/opendmarc/info \
        --mandir=/tmp/opendmarc/man \
    && make \
    && addgroup --system opendmarc \
    && adduser --system --disabled-password --shell /sbin/nologin \
        --no-create-home --home /run/opendmarc \
        --ingroup opendmarc --gecos opendmarc \
        opendmarc \
    && adduser opendmarc mail \
    && make install \
    && install -d -o opendmarc -g opendmarc /run/opendmarc/ \
    && install -d /etc/opendmarc/conf.d/ \
    && rm -rf /tmp/OpenDMARC-* /tmp/opendmarc* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM opendmarc AS final

# Always lastest CA & TZ
RUN apt-get update \
    && apt-get install -y \
        ca-certificates tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG MRELAY_TIMEZONE
ENV TZ=${MRELAY_TIMEZONE}
RUN ln -snf "/usr/share/zoneinfo/${TZ}" \
/etc/localtime && echo "${TZ}" > /etc/timezone

COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./supervisord/postfix-main.conf /etc/postfix/main.cf
RUN mkdir /supervisord
COPY ./supervisord/*.sh /supervisord/
RUN chmod +x /supervisord/*.sh

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /

ENTRYPOINT [ "/entrypoint.sh" ]
