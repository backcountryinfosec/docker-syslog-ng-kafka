# Docker-Version 20.10.17
#docker build --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg SYSLOG_VERSION=3.37.1 -t syslog-ng-kafka:3.37.1 .
FROM ubuntu:20.04

ARG BUILD_DATE
ARG SYSLOG_VERSION

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="" \
      org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.version="1.0" \
      org.label-schema.name="" \
      org.label-schema.vcs-url="" \
      org.label-schema.docker.cmd="docker run -d -p 514/udp -p 601/tcp -v syslog-ng.yaml:/etc/syslog-ng/syslog-ng.yaml" \
      org.label-schema.description="This is a syslog-ng build with Kafka-c enabled and ready to go. https://www.syslog-ng.com/community/b/blog/posts/kafka-destination-improved-with-template-support-in-syslog-ng"

ENV TZ="UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    autoconf-archive \
    bison \
    build-essential \
    flex \
    gnupg \
    gradle \
    libglib2.0-dev \
    libjson-c-dev \
    libpcre3-dev \
    librdkafka-dev \
    libssl-dev \
    openjdk-8-jdk \
    wget && \
    rm -rf /var/cache/apk/*

RUN wget -q -O - https://github.com/syslog-ng/syslog-ng/releases/download/syslog-ng-${SYSLOG_VERSION}/syslog-ng-${SYSLOG_VERSION}.tar.gz | tar -xzf - -C /tmp/
WORKDIR /tmp/syslog-ng-${SYSLOG_VERSION}
RUN export LD_LIBRARY_PATH=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server:$LD_LIBRARY_PATH

RUN ./configure --enable-java-modules --enable-json --enable-kafka

RUN make && make install
RUN ldconfig

EXPOSE 514/udp
EXPOSE 601/tcp

ENTRYPOINT ["/usr/local/sbin/syslog-ng", "-F"]
