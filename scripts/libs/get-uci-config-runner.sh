#!/usr/bin/env bash
set -euo pipefail

# This is meant to be sourced and not run

# Run 'uci show' on the sysroot

function usage() {
	echo "get-uci-config image1.img.gz"
	exit 1
}

function cleanup() {
	rm -rf "${TMPDIR}"
}

[ -z "${1:-}" ] && usage

[ -z "${APPLY_INIT_SCRIPTS:-}" ] && APPLY_INIT_SCRIPTS="true"

IMAGE="$(readlink -f "${1}")"

echoerr "Image: ${IMAGE}"

TMPDIR="$(mktemp -d)"
pushd "${TMPDIR}" >/dev/null

trap cleanup EXIT

unpack_image "${IMAGE}" .

ensure_uci_runner

if [[ ! "${APPLY_INIT_SCRIPTS}" == "false" ]]; then
	APPLIER_SCRIPT="$(mktemp)"
	chmod +x "${APPLIER_SCRIPT}"
	cat <<-"EOF" >"${APPLIER_SCRIPT}"
		#!/usr/bin/env bash
		    set -e

		    # Run the init configurator
		    bash /bin/config_generate

		    # Run the additional init scripts

		    # Add / to PATH, as uci binary lives there
		    export PATH="/:${PATH}"

		    echo "#### APPLY LOGIC START ####"

		    find /etc/uci-defaults/ -type f | sort | while read f; do
		        echo "#### ${f} ####"
		        bash "${f}"
		    done

		    echo "#### APPLY LOGIC END ####"
	EOF

	# Prepare a "no action" file, to overwrite problematic scripts, that don't affect
	# configuration
	NONE_FILE="$(mktemp)"
	chmod +x "${NONE_FILE}"
	echo ":" >"${NONE_FILE}"

	chmod +x "bin/board_detect"

	# Mount bash libraries and files from OpenWRT, needed to generate init config
	docker run -it --rm \
		--entrypoint /applier-script \
		-v "${APPLIER_SCRIPT}:/applier-script" \
		-v "$PWD/etc:/etc" \
		-v "$PWD/lib/functions:/lib/functions" \
		-v "$PWD/lib/functions.sh:/lib/functions.sh" \
		-v "$PWD/lib/config/uci.sh:/lib/config/uci.sh" \
		-v "$PWD/usr/share/libubox/jshn.sh:/usr/share/libubox/jshn.sh" \
		-v "$PWD/bin/config_generate:/bin/config_generate" \
		-v "$PWD/bin/board_detect:/bin/board_detect" \
		-v "${NONE_FILE}:/etc/init.d/uhttpd" \
		uci-runner 1>&2
else
	echoerr "Not applying init scripts because of APPLY_INIT_SCRIPTS=false"
fi

docker run -it --rm -v "$PWD/etc:/etc" uci-runner show
