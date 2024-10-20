#!/usr/bin/env bash

# This is meant to be run directly in the container
# so no additional sourcing happens here

set -euo pipefail

# libubox
function build_libubox() {
	local LIBUBOX_BUILD_DIR && LIBUBOX_BUILD_DIR="$(mktemp -d)"
	pushd "${LIBUBOX_BUILD_DIR}"
	mkdir build-libubox && cd build-libubox
	cmake /builder/libubox-source -DBUILD_LUA=OFF -DBUILD_EXAMPLES=OFF -DCMAKE_INSTALL_PREFIX=/
	make -j"$(nproc)"
	make install
	popd
}

# uci
function build_uci() {
	local UCI_BUILD_DIR && UCI_BUILD_DIR="$(mktemp -d)"
	pushd "${UCI_BUILD_DIR}"
	#mkdir build-uci && cd build-uci
	cmake /builder/uci-source -DBUILD_LUA=OFF -DBUILD_STATIC=ON -DCMAKE_INSTALL_LIBDIR=lib
	make -j"$(nproc)"
	make install
}

build_libubox
build_uci
