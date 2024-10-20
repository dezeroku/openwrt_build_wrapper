#!/usr/bin/env bash
set -euo pipefail

# Unpack two images and run diff on them

function usage() {
	echo "compare-images image1.img.gz image2.img.gz"
	exit 1
}

function cleanup() {
	rm -rf "${TMPDIR}"
}

[ -z "${1:-}" ] && usage
[ -z "${2:-}" ] && usage

FIRST="$(readlink -f "${1}")"
SECOND="$(readlink -f "${2}")"

echoerr "${FIRST}"
echoerr "${SECOND}"

TMPDIR="$(mktemp -d)"

pushd "${TMPDIR}" >/dev/null

trap cleanup EXIT

unpack_image "${FIRST}" first
unpack_image "${SECOND}" second

du -s first second

diff -r first second --no-dereference --exclude custom-version-file
