FROM alpine:3.17

LABEL description "PostfixAdmin is a web based interface used to manage mailboxes" \
      maintainer="Eydrian <info@adrianetter.com>"

ARG VERSION=3.3.13
ARG PHP_VERSION=81
ARG SHA256_HASH="026c4f370656b96b6c9f62328e901b9416a6e56d1c4df86249995d661498947b"

RUN apk update \
  && apk -U upgrade \
  && apk add -t build-dependencies \
    ca-certificates \
    gnupg \
  && apk add --no-cache \
    su-exec \
    dovecot \
    tini \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysqli \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-pdo_mysql \
    php${PHP_VERSION}-pdo_pgsql \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-phar \
    php${PHP_VERSION}-session \
 && cd /tmp \
 && PFA_NAME="postfixadmin-${VERSION}" \
 && PFA_TARBALL="${PFA_NAME}.tar.gz" \
 && wget -q https://codeload.github.com/postfixadmin/postfixadmin/tar.gz/refs/tags/${PFA_NAME} -O ${PFA_TARBALL}\
 && CHECKSUM=$(sha256sum ${PFA_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SHA256_HASH}" ]; then echo "ERROR: Checksum does not match!" && exit 1; fi \
 && mkdir /postfixadmin && tar -zxvf ${PFA_TARBALL} -C /postfixadmin && mv /postfixadmin/postfixadmin-postfixadmin-$VERSION/* /postfixadmin \
 && apk del build-dependencies \
 && rm -rf /var/cache/apk/* /tmp/* /root/.gnupg /postfixadmin/postfixadmin-postfixadmin-$VERSION* \
 && rm -f ${PFA_TARBALL} \
 && chmod 644 /etc/ssl/dovecot/server.key

COPY bin /usr/local/bin
RUN chmod +x /usr/local/bin/*
EXPOSE 80
CMD ["tini", "--", "run.sh"]
