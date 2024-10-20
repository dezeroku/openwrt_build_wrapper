#!/usr/bin/env bash
set -euo pipefail

# This script applies the sysupgrade WITHOUT PRESERVING ANY CONFIGURATION ON THE ROUTER
# However by default a local backup gets created

function usage() {
	echo "apply-sysupgrade sysupgrade_file router_ip"
	exit 1
}

APPLY_SYSUPGRADE_PERFORM_BACKUP="${APPLY_SYSUPGRADE_PERFORM_BACKUP:-true}"

[ -z "${1:-}" ] && usage
[ -z "${2:-}" ] && usage

SYSUPGRADE_FILE="$(readlink -f "${1}")"
ROUTER_IP="${2}"

SSH_HOST="root@${ROUTER_IP}"
SYSUPGRADE_FILE_CHECKSUM="$(sha256sum "${SYSUPGRADE_FILE}" | cut -d " " -f 1)"
ROUTER_SYSUPGRADE_FILE="$(ssh -T "${SSH_HOST}" mktemp)"
APPLY_TIMESTAMP="$(date -u +%Y_%m_%dT%H_%M_%S%Z)"

echoerr "Running an update with ${SYSUPGRADE_FILE}"

RESULT_DIRECTORY="${APPLIED_SYSUPGRADES_DIR}/${DEVICE}/sysupgrade-${APPLY_TIMESTAMP}"

mkdir -p "${RESULT_DIRECTORY}"

if [[ "${APPLY_SYSUPGRADE_PERFORM_BACKUP}" == "true" ]]; then
	BACKUP_FILE="${RESULT_DIRECTORY}/backup.tar.gz"
	echoerr "Backing up the router configuration as ${BACKUP_FILE}"
	ssh -T "${SSH_HOST}" "sysupgrade -b -" >"${BACKUP_FILE}"
	echoerr "Backup succeeded"
fi

# poor man's scp for better compability
# We want this to expand on the client's side
# shellcheck disable=SC2029
ssh "${SSH_HOST}" "cat > ${ROUTER_SYSUPGRADE_FILE}" <"${SYSUPGRADE_FILE}"
ROUTER_SYSUPGRADE_FILE_CHECKSUM="$(ssh -T "${SSH_HOST}" "sha256sum ${ROUTER_SYSUPGRADE_FILE} | cut -d ' ' -f 1")"
if [[ "${ROUTER_SYSUPGRADE_FILE_CHECKSUM}" != "${SYSUPGRADE_FILE_CHECKSUM}" ]]; then
	echo "Copied file failed the checksum check!"
	echo "expected: ${SYSUPGRADE_FILE_CHECKSUM} got: ${ROUTER_SYSUPGRADE_FILE_CHECKSUM}"
	exit 1
fi

SYMLINK_TIMESTAMPED="${RESULT_DIRECTORY}/sysupgrade_file"
SYMLINK_LAST="${APPLIED_SYSUPGRADES_DIR}/${DEVICE}/last"

ln -s "${SYSUPGRADE_FILE}" "${SYMLINK_TIMESTAMPED}"

if [[ ! -e "${SYMLINK_LAST}" ]]; then
	ln -s "${RESULT_DIRECTORY}" "${SYMLINK_LAST}"
elif [[ -L "${SYMLINK_LAST}" && -d "${SYMLINK_LAST}" ]]; then
	rm "${SYMLINK_LAST}"
	ln -s "${RESULT_DIRECTORY}" "${SYMLINK_LAST}"
else
	echoerr "Not creating a link: ${SYMLINK_LAST}, because of a file already present there"
fi

echoerr "Performing the sysupgrade"
# We want this to expand on the client's side
# shellcheck disable=SC2029
ssh "${SSH_HOST}" "sysupgrade -v -n ${ROUTER_SYSUPGRADE_FILE}"
