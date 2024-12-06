FROM debian:bullseye-slim as mailserver-overlay

ARG DEBIAN_FRONTEND=noninteractive
ARG BUILD_CORES

ARG SKALIBS_VER=2.14.3.0
ARG EXECLINE_VER=2.9.6.1
ARG S6_VER=2.13.1.0
ARG RSPAMD_VER=3.10.2
ARG GUCCI_VER=1.6.13

ARG SKALIBS_SHA256_HASH="a14aa558c9b09b062fa16acec623b2c8f93d69f5cba4d07f6d0c58913066c427"
ARG EXECLINE_SHA256_HASH="76919d62f2de4db1ac4b3a59eeb3e0e09b62bcdd9add13ae3f2dad26f8f0e5ca"
ARG S6_SHA256_HASH="bf0614cf52957cb0af04c7b02d10ebd6c5e023c9d46335cbf75484eed3e2ce7e"
ARG RSPAMD_SHA256_HASH="3f77a2230c88b5026b5c3cef022f0432b324ef492fdc297f30c6916f17103bdf"
ARG GUCCI_SHA256_HASH="93a9a6e75a02f8f02c3f2f19909b91c0da06c738cab623aae5ae0bef91ab666e"

LABEL description="s6 + rspamd image based on Debian" \
      maintainer="adrianetter <info@adrianetter.com" \
      rspamd_version="Rspamd v${RSPAMD_VER} built from source" \
      s6_version="s6 v${S6_VER} built from source"

ENV LC_ALL=C

RUN apt-get update && apt-get -y upgrade && apt-get -y autoremove && apt-get autoclean

ENV NB_CORES=4
ENV BUILD_DEPS="\
    cmake \
    gcc \
    g++ \
    make \
    ragel \
    wget \
    pkg-config \
    liblua5.1-0-dev \
    libluajit-5.1-dev \
    libglib2.0-dev \
    libevent-dev \
    libsqlite3-dev \
    libicu-dev \
    libssl-dev \
    libjemalloc-dev \
    libmagic-dev \
    libsodium-dev \
    libarchive-dev"
RUN apt-get update
RUN apt-get install -y -q --no-install-recommends \
    ${BUILD_DEPS} \
    libevent-2.1-7 \
    libglib2.0-0 \
    libssl1.1 \
    libmagic1 \
    liblua5.1-0 \
    libluajit-5.1-2 \
    libsqlite3-0 \
    libjemalloc2 \
    libsdl1.2-dev \
    libexecline-dev \
    libarchive13 \
    sqlite3 \
    openssl \
    ca-certificates \
    gnupg \
    dirmngr \
    netcat

RUN wget --version
RUN cd /tmp \
 && SKALIBS_TARBALL="skalibs-${SKALIBS_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/skalibs/${SKALIBS_TARBALL} \
 && CHECKSUM=$(sha256sum ${SKALIBS_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SKALIBS_SHA256_HASH}" ]; then echo "${SKALIBS_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${SKALIBS_TARBALL} && cd skalibs-${SKALIBS_VER} \
 && ./configure --prefix=/usr --datadir=/etc \
 && make && make install
RUN cd /tmp \
 && EXECLINE_TARBALL="execline-${EXECLINE_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/execline/${EXECLINE_TARBALL} \
 && CHECKSUM=$(sha256sum ${EXECLINE_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${EXECLINE_SHA256_HASH}" ]; then echo "${EXECLINE_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${EXECLINE_TARBALL} && cd execline-${EXECLINE_VER} \
 && ./configure --prefix=/usr \
 && make && make install
RUN cd /tmp \
 && S6_TARBALL="s6-${S6_VER}.tar.gz" \
 && wget -q https://skarnet.org/software/s6/${S6_TARBALL} \
 && CHECKSUM=$(sha256sum ${S6_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${S6_SHA256_HASH}" ]; then echo "${S6_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${S6_TARBALL} && cd s6-${S6_VER} \
 && ./configure --prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin \
 && make && make install
RUN cd /tmp \
 && RSPAMD_TARBALL="${RSPAMD_VER}.tar.gz" \
 && wget -q https://github.com/rspamd/rspamd/archive/${RSPAMD_TARBALL} \
 && CHECKSUM=$(sha256sum ${RSPAMD_TARBALL} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${RSPAMD_SHA256_HASH}" ]; then echo "${RSPAMD_TARBALL} : bad checksum" && exit 1; fi \
 && tar xzf ${RSPAMD_TARBALL} && cd rspamd-${RSPAMD_VER} \
 && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCONFDIR=/etc/rspamd \
    -DRUNDIR=/run/rspamd \
    -DDBDIR=/var/mail/rspamd \
    -DLOGDIR=/var/log/rspamd \
    -DPLUGINSDIR=/usr/share/rspamd \
    -DLIBDIR=/usr/lib/rspamd \
    -DNO_SHARED=ON \
    -DWANT_SYSTEMD_UNITS=OFF \
    -DENABLE_TORCH=ON \
    -DENABLE_HIREDIS=ON \
    -DINSTALL_WEBUI=ON \
    -DENABLE_OPTIMIZATION=ON \
    -DENABLE_HYPERSCAN=OFF \
    -DENABLE_JEMALLOC=ON \
    -DJEMALLOC_ROOT_DIR=/jemalloc \
    . \
 && make -j${NB_CORES} \
 && make install

RUN cd /tmp \
 && GUCCI_BINARY="gucci-v${GUCCI_VER}-linux-arm64" \
 && wget -q https://github.com/noqcks/gucci/releases/download/v${GUCCI_VER}/${GUCCI_BINARY} \
 && CHECKSUM=$(sha256sum ${GUCCI_BINARY} | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${GUCCI_SHA256_HASH}" ]; then echo "${GUCCI_BINARY} : bad checksum" && exit 1; fi \
 && chmod +x ${GUCCI_BINARY} \
 && mv ${GUCCI_BINARY} /usr/local/bin/gucci \
 && apt-get purge -y ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old \
 && echo "hello"


# FROM debian:bullseye-slim
FROM mailserver-overlay

LABEL description "Simple and full-featured mail server using Docker" \
      maintainer="adrianetter<info@adrianetter.com>"

ARG DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y -q --no-install-recommends \
    postfix postfix-pgsql postfix-mysql postfix-ldap postfix-pcre libsasl2-modules \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pgsql dovecot-mysql dovecot-ldap dovecot-sieve dovecot-managesieved dovecot-pop3d \
    fetchmail libdbi-perl libdbd-pg-perl libdbd-mysql-perl liblockfile-simple-perl \
    clamav clamav-daemon wget \
    python3-pip python3-setuptools python3-wheel \
    rsyslog dnsutils curl unbound jq rsync \
    inotify-tools
RUN rm -rf /var/spool/postfix
RUN mkdir -p /var/mail/postfix/spool
RUN ln -s /var/mail/postfix/spool /var/spool/postfix
RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/* /var/cache/debconf/*-old
RUN pip3 install watchdog

EXPOSE 25 143 465 587 993 4190 11334
COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish
CMD ["run.sh"]
