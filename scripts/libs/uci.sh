#!/usr/bin/env bash

function ensure_uci_runner() {
	# Make sure that uci-runner container exists and build it
	# if it doesn't
	if [[ "$(docker images uci-runner -q)" != "" ]]; then
		echoerr "uci-runner image present"
	else
		echoerr "uci-runner image not present, building"
		"${SCRIPTS_DIR}/utils/build-uci-host"
	fi
}
