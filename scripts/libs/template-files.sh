#!/usr/bin/env bash
set -euo pipefail

# This function must be run from a context
# which already sourced the common lib

function template_files() {
	check_tool gomplate

	if [ -z "$1" ]; then
		echo "template_files: No directory_to_template provided"
		exit 1
	fi

	local directory_to_template="$1"

	GOMPLATE_COMMAND_SUFFIX="-d base=$(readlink -f "${SCRIPTS_DIR}/../config/common/template-variables.yaml")"
	GOMPLATE_MERGE_CONTEXT="base"

	# Template the files
	if [ -n "${DEVICE_TEMPLATE_ENV_FILE:-}" ]; then
		echoerr "Applying ${DEVICE_TEMPLATE_ENV_FILE}"

		GOMPLATE_COMMAND_SUFFIX="-d config=${DEVICE_TEMPLATE_ENV_FILE} ${GOMPLATE_COMMAND_SUFFIX}"
		GOMPLATE_MERGE_CONTEXT="config|${GOMPLATE_MERGE_CONTEXT}"

		if [ -n "${DEVICE_TEMPLATE_SECRET_ENV_FILE:-}" ]; then
			echoerr "Detected ${DEVICE_TEMPLATE_SECRET_ENV_FILE} override, applying"
			GOMPLATE_COMMAND_SUFFIX="-d secrets=${DEVICE_TEMPLATE_SECRET_ENV_FILE} ${GOMPLATE_COMMAND_SUFFIX}"
			GOMPLATE_MERGE_CONTEXT="secrets|config|${GOMPLATE_MERGE_CONTEXT}"
		fi
	fi

	if [[ "${GOMPLATE_MERGE_CONTEXT}" == "base" ]]; then
		# Avoid merge argument with just one parameter, it won't work
		# so merge base with itself
		GOMPLATE_MERGE_CONTEXT="${GOMPLATE_MERGE_CONTEXT}|base"
	fi

	GOMPLATE_COMMAND_SUFFIX="-c \".=merge:${GOMPLATE_MERGE_CONTEXT}\" ${GOMPLATE_COMMAND_SUFFIX}"

	GOMPLATE_COMMAND="gomplate ${GOMPLATE_COMMAND_SUFFIX}"

	find "${directory_to_template}" -type f | sort | while read -r file; do
		echoerr "Templating ${file}"
		TMPFILE="$(mktemp)"
		env -i bash -c "cat ${file} | ${GOMPLATE_COMMAND}" >"${TMPFILE}"
		mv "${TMPFILE}" "${file}"
	done
}
