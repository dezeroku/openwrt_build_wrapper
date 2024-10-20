FROM debian:11@sha256:34b24056f28be0f9b3f6c5b2417a0976d692261e3fe404f5da5fbe4b2b71f15a

USER root

RUN \
    apt-get update && \
    apt-get install -y \
        build-essential \
        cmake \
        pkgconf \
        libjson-c-dev \
        && \
    apt-get clean

RUN \
    groupadd buildbot && \
    useradd \
    --create-home --home-dir /home/builder \
    --gid 1000 --uid 1000 --shell /bin/bash buildbot && \
    chown buildbot:buildbot /home/builder

USER buildbot

WORKDIR /builder

USER root

RUN apt-get install -y \
        bsdmainutils

RUN ln -sf bash /bin/sh

COPY ./libubox-source ./libubox-source
COPY ./uci-source ./uci-source

COPY ./build-uci-host-helper /build-script
RUN /build-script

ENTRYPOINT ["/usr/local/bin/uci"]
