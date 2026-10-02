# Build:
#   docker build --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t syslog-ng-kafka:4.12.0 .
# Run:
#   docker run -d -p 514:514/udp -p 514:514/tcp -p 601:601/tcp \
#     -v ./syslog-ng.conf:/etc/syslog-ng/syslog-ng.conf -v ./logs:/mnt/logs syslog-ng-kafka:4.12.0

ARG SYSLOG_VERSION=4.12.0

########################
# Build stage
########################
FROM ubuntu:24.04 AS build

ARG SYSLOG_VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf-archive \
    bison \
    build-essential \
    ca-certificates \
    flex \
    libcurl4-openssl-dev \
    libglib2.0-dev \
    libjson-c-dev \
    libpaho-mqtt-dev \
    libpcre2-dev \
    librdkafka-dev \
    libssl-dev \
    pkg-config \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q -O - https://github.com/syslog-ng/syslog-ng/releases/download/syslog-ng-${SYSLOG_VERSION}/syslog-ng-${SYSLOG_VERSION}.tar.gz | tar -xzf - -C /tmp/
WORKDIR /tmp/syslog-ng-${SYSLOG_VERSION}

RUN ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/syslog-ng \
        --localstatedir=/var/lib/syslog-ng \
        --enable-json \
        --enable-kafka \
        --enable-mqtt \
        --enable-http \
        --disable-java \
        --disable-python \
        --disable-mongodb \
        --disable-amqp \
        --disable-riemann \
        --disable-sql && \
    make -j"$(nproc)" && \
    make install DESTDIR=/out

########################
# Runtime stage
########################
FROM ubuntu:24.04

ARG BUILD_DATE
ARG SYSLOG_VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="bcinfosec" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version=${SYSLOG_VERSION} \
      org.label-schema.name="bcinfosec/syslog-ng-kafka" \
      org.label-schema.vcs-url="https://github.com/backcountryinfosec/docker-syslog-ng-kafka" \
      org.label-schema.docker.cmd="docker run -d -p 514:514/udp -p 514:514/tcp -p 601:601/tcp -v ./syslog-ng.conf:/etc/syslog-ng/syslog-ng.conf syslog-ng-kafka" \
      org.label-schema.description="syslog-ng build with Kafka, MQTT, HTTP and JSON support enabled."

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="UTC"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4t64 \
    libglib2.0-0t64 \
    libjson-c5 \
    libpaho-mqtt1.3 \
    libpcre2-8-0 \
    librdkafka1 \
    libssl3t64 \
    tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY --from=build /out/ /
RUN ldconfig && \
    mkdir -p /etc/syslog-ng/conf.d /var/lib/syslog-ng /mnt/logs

COPY syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

EXPOSE 514/udp
EXPOSE 514/tcp
EXPOSE 601/tcp

ENTRYPOINT ["/usr/sbin/syslog-ng", "-F"]
