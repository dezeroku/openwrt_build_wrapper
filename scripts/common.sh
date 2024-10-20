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
	# shellcheck source=config/example/variables
	. "${DEVICE_ENV_FILE}"

	if [ -z "${BUILDDIR:-}" ]; then
		mkdir -p "${ROOT_DIR}/builds"
		BUILDDIR="${ROOT_DIR}/builds/openwrt-${DEVICE}"
	fi

	if [ -z "${ARTIFACTS_DIR:-}" ]; then
		ARTIFACTS_DIR="${ROOT_DIR}/artifacts"
		mkdir -p "${ARTIFACTS_DIR}"
	fi
	ARTIFACTS_DIR="$(readlink -f "${ARTIFACTS_DIR}")"

	if [ -z "${APPLIED_SYSUPGRADES_DIR:-}" ]; then
		APPLIED_SYSUPGRADES_DIR="${ROOT_DIR}/applied-sysupgrades"
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

function on_entry() {
	if [ -z "${SCRIPTS_DIR:-}" ]; then
		echo "SCRIPTS_DIR is required to be in env"
		echo "Did you start the script properly?"
		exit 1
	fi

	SCRIPTS_DIR="$(readlink -f "${SCRIPTS_DIR}")"
	# Root of the repository containing the build wrapper (this repo)
	ROOT_REPO_DIR="$(readlink -f "${SCRIPTS_DIR}/..")"

	if [ -z "${DEVICE:-}" ]; then
		echo "DEVICE is required to be in env" && exit 1
	fi

	echoerr "DEVICE=${DEVICE}"

	# Look for device config OOT first and fallback to in-repo
	# Based on where we find the device config, we assume the build and artifacts dirs later on
	oot_root_dir="${ROOT_REPO_DIR}/../"
	oot_device_config_dir="${oot_root_dir}/config/${DEVICE}"
	in_tree_root_dir="${ROOT_REPO_DIR}"
	in_tree_device_config_dir="${in_tree_root_dir}/config/${DEVICE}"

	if [ -d "$oot_device_config_dir" ]; then
		echoerr "OOT device config detected, using it"
		ROOT_DIR="$(readlink -f "${oot_root_dir}")"
	elif [ -d "${in_tree_device_config_dir}" ]; then
		echoerr "Falling back to in-tree device config"
		ROOT_DIR="$(readlink -f "${in_tree_root_dir}")"
	else
		echoerr "Neither ${oot_device_config_dir} nor ${in_tree_device_config_dir} directory exists"
		echoerr "Did you create the config directory for ${DEVICE}?"
		exit 1
	fi

	DEVICE_CONFIG_DIR="$(readlink -f "${ROOT_DIR}/config/${DEVICE}")"
	# Root of the "whole context", this can be either same as ROOT_REPO_DIR or can include ROOT_REPO_DIR as a
	# subdirectory in case of OOT builds
	echoerr "ROOT_DIR=${ROOT_DIR}"
	echoerr "DEVICE_CONFIG_DIR=${DEVICE_CONFIG_DIR}"

	export SCRIPTS_DIR
	export ROOT_DIR
	export ROOT_REPO_DIR
	export DEVICE_CONFIG_DIR
}

on_entry
