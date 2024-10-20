# This Dockerfile is really inspired (basically copy-pasted) by the `docker/buildworker/Dockerfile` available in [OpenWRT buildbot repo](https://git.openwrt.org/?p=buildbot.git;a=summary)
# At the time of writing it was based on 85ffd9a27da104698b3ee433aaf0ffb0cb13504e hash
# It also includes `sccache`, `gomplate` and `dropbearkey`

FROM rust:1.74.0 as sccache-build

RUN apt-get update && \
        apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl --toolchain 1.74.0
RUN cargo install sccache \
        --version 0.5.4 \
        --features openssl/vendored \
        --root /sccache-output \
        --target=x86_64-unknown-linux-musl

FROM        ubuntu:22.04@sha256:817cfe4672284dcbfee885b1a66094fd907630d610cab329114d036716be49ba

USER root

COPY --from=sccache-build /sccache-output/bin/sccache /usr/bin/sccache

RUN \
    apt-get update && \
    apt-get install -y \
        build-essential \
        curl \
        gawk \
        gcc-multilib \
        genisoimage \
        git \
        gosu \
        libdw-dev \
        libelf-dev \
        libncurses5-dev \
        locales \
        pv \
        pwgen \
        qemu-utils \
        rsync \
        signify-openbsd \
        subversion \
        swig \
        unzip \
        wget \
        clang-14 \
        llvm-14 \
        flex \
        g++ \
        gettext \
        python3-distutils \
        zlib1g-dev \
        libssl-dev \
        file \
        \
        dropbear-bin \
        dos2unix \
        moreutils \
        && \
    apt-get clean && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

COPY --from=hairyhenderson/gomplate:v3.11 /gomplate /bin/gomplate

ENV LANG=en_US.utf8

# Get wrapper for sccache
COPY ./sccache /sccache-wrapper/sccache
RUN \
        ln /sccache-wrapper/sccache /usr/local/bin/gcc && \
        ln /sccache-wrapper/sccache /usr/local/bin/g++ && \
        ln /sccache-wrapper/sccache /usr/local/bin/cc && \
        ln /sccache-wrapper/sccache /usr/local/bin/c++

RUN \
    groupadd buildbot && \
    useradd \
    --create-home --home-dir /home/builder \
    --comment "OpenWrt buildbot" \
    --gid 1000 --uid 1000 --shell /bin/bash buildbot && \
    chown buildbot:buildbot /home/builder

# WA the issue with local home directory not matching the /home/builder
# Probably a better approach here would be to create the required dir via script?
RUN chown buildbot:buildbot /home

USER buildbot

WORKDIR /builder
