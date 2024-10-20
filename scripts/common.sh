#!/usr/bin/env bash

# This file is not meant to be run
# It contains a collection of utilities to be shared by every script

set -euo pipefail

function echoerr() {
	echo "$@" 1>&2
}

function check_tool() {
	local tool
	tool="$1"
	if ! command -v "${tool}" >/dev/null; then
		echoerr "${tool} command not found"
		return 1
	fi
}

function set_git_info() {
	# If not present, configure the user's name and email
	if ! git config user.email; then
		git config user.email "openwrt-builder@example.com"
	fi
	if ! git config user.name; then
		git config user.name "openwrt-builder"
	fi
}

function source_device_lib() {
	if [ -z "${DEVICE_CONFIG_DIR:-}" ]; then
		echoerr "DEVICE_CONFIG_DIR variable is empty"
		echoerr "Did you call parse_env_args function in your script?"
		exit 1
	fi

	local lib_file="${DEVICE_CONFIG_DIR}/lib.sh"

	if [ -f "${lib_file}" ]; then
		# This file is dynamic, we can't follow it
		# shellcheck disable=SC1090
		. "${lib_file}"
	else
		echoerr "File ${lib_file} does not exist"
		exit 1
	fi
}

function parse_env_args() {
	if [ -z "${SCRIPTS_DIR:-}" ]; then
		echo "SCRIPTS_DIR is required to be in env"
		echo "Did you start the script properly?"
		exit 1
	fi

	SCRIPTS_DIR="$(readlink -f "${SCRIPTS_DIR}")"

	if [ -z "${DEVICE:-}" ]; then
		echo "DEVICE is required to be in env" && exit 1
	fi

	if [ -d "${SCRIPTS_DIR}/../config/${DEVICE}" ]; then
		DEVICE_CONFIG_DIR="$(readlink -f "${SCRIPTS_DIR}/../config/${DEVICE}")"
	else
		echoerr "${SCRIPTS_DIR}/../config/${DEVICE} directory does not exist"
		echoerr "Did you create the config directory for ${DEVICE}?"
		exit 1
	fi

	[ -z "${DEVICE_ENV_FILE:-}" ] && DEVICE_ENV_FILE="$(readlink -f "${DEVICE_CONFIG_DIR}/variables")"
	DEVICE_ENV_FILE="$(readlink -f "${DEVICE_ENV_FILE}")"

	if [ ! -f "${DEVICE_ENV_FILE}" ]; then
		echoerr "${DEVICE_ENV_FILE} file does not exist"
		echoerr "Did you create the 'variables' file for ${DEVICE}?"
		exit 1
	fi

	if [ -z "${DEVICE_TEMPLATE_ENV_FILE:-}" ]; then
		[ -f "${DEVICE_CONFIG_DIR}/template-variables.yaml" ] && DEVICE_TEMPLATE_ENV_FILE="$(readlink -f "${DEVICE_CONFIG_DIR}/template-variables.yaml")"
	else
		DEVICE_TEMPLATE_ENV_FILE="$(readlink -f "${DEVICE_TEMPLATE_ENV_FILE}")"
	fi

	if [ -z "${DEVICE_TEMPLATE_SECRET_ENV_FILE:-}" ]; then
		[ -f "${DEVICE_CONFIG_DIR}/secret-variables.yaml" ] && DEVICE_TEMPLATE_SECRET_ENV_FILE="$(readlink -f "${DEVICE_CONFIG_DIR}/secret-variables.yaml")"
	else
		DEVICE_TEMPLATE_SECRET_ENV_FILE="$(readlink -f "${DEVICE_TEMPLATE_SECRET_ENV_FILE}")"
	fi

	[ -z "${REPRODUCE_UPSTREAM_BUILD:-}" ] && REPRODUCE_UPSTREAM_BUILD="false"

	[ -z "${DEVICE_CONFIG_FILE:-}" ] && DEVICE_CONFIG_FILE="$(readlink -f "${DEVICE_CONFIG_DIR}/config")"
	DEVICE_CONFIG_FILE="$(readlink -f "${DEVICE_CONFIG_FILE}")"

	echoerr "DEVICE=${DEVICE}"
	echoerr "DEVICE_CONFIG_FILE=${DEVICE_CONFIG_FILE}"
	echoerr "DEVICE_ENV_FILE=${DEVICE_ENV_FILE}"
	if [ -n "${DEVICE_TEMPLATE_ENV_FILE:-}" ]; then
		echoerr "DEVICE_TEMPLATE_ENV_FILE=${DEVICE_TEMPLATE_ENV_FILE}"
	fi
	if [ -n "${DEVICE_TEMPLATE_SECRET_ENV_FILE:-}" ]; then
		echoerr "DEVICE_TEMPLATE_SECRET_ENV_FILE=${DEVICE_TEMPLATE_SECRET_ENV_FILE}"
	fi
	echoerr "REPRODUCE_UPSTREAM_BUILD=${REPRODUCE_UPSTREAM_BUILD}"

	# Example file for reference
	# shellcheck source=build/config/mainrouter/variables
	. "${DEVICE_ENV_FILE}"

	if [ -z "${BUILDDIR:-}" ]; then
		mkdir -p "${SCRIPTS_DIR}/../builds"
		BUILDDIR="${SCRIPTS_DIR}/../builds/openwrt-${DEVICE}"
	fi

	if [ -z "${ARTIFACTS_DIR:-}" ]; then
		ARTIFACTS_DIR="${SCRIPTS_DIR}/../artifacts"
		mkdir -p "${ARTIFACTS_DIR}"
	fi
	ARTIFACTS_DIR="$(readlink -f "${ARTIFACTS_DIR}")"

	if [ -z "${APPLIED_SYSUPGRADES_DIR:-}" ]; then
		APPLIED_SYSUPGRADES_DIR="${SCRIPTS_DIR}/../applied-sysupgrades"
		mkdir -p "${APPLIED_SYSUPGRADES_DIR}"
	fi
	APPLIED_SYSUPGRADES_DIR="$(readlink -f "${APPLIED_SYSUPGRADES_DIR}")"

	[ -z "${OPENWRT_VERSION:-}" ] && echo "No OPENWRT_VERSION provided" && exit 1

	# This is pretty hacky
	# We rely on clone step to create this directory
	# but we also want it to be an absolute path in the next steps
	if [ -d "$BUILDDIR" ]; then
		BUILDDIR="$(readlink -f "${BUILDDIR}")"
	fi

	echoerr "BUILDDIR=${BUILDDIR}"
	echoerr "OPENWRT_VERSION=${OPENWRT_VERSION}"

	export DEVICE
	export BUILDDIR
	export OPENWRT_VERSION
}
