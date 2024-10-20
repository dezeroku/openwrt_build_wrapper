#!/bin/sh

# Restart or initialize some services that cause problems if run from uci-defaults
# as the system is not fully initialized yet at that stage

echo "Restarting dropbear"
/etc/init.d/dropbear restart
echo "DONE"

# shellcheck disable=SC1054,SC1083
{{- if .letsencrypt.enabled }}
# Wait for the internet connection with 10 minutes timeout
ping -c 1 -W 600 1.1.1.1

echo "Starting acme"
/etc/init.d/acme start

# shellcheck disable=SC2017,SC2016
if [ ! -f '/etc/ssl/acme/{{ .hostname }}.{{ .letsencrypt.domain }}.crt' ]; then
	echo "Couldn't obtain cert, STOP"
	exit 1
else
	echo "DONE"
fi

echo "Align uhttpd to use ACME obtained certs"

# shellcheck disable=SC2017,SC2016
uci set uhttpd.main.cert='/etc/ssl/acme/{{ .hostname }}.{{ .letsencrypt.domain }}.crt'
# shellcheck disable=SC2017,SC2016
uci set uhttpd.main.key='/etc/ssl/acme/{{ .hostname }}.{{ .letsencrypt.domain }}.key'

# Make sure default cert generation will not mess up the symlinks
uci -q get uhttpd.defaults && uci delete uhttpd.defaults

uci commit uhttpd
echo "DONE"

echo "Restarting uhttpd"
/etc/init.d/uhttpd restart
echo "DONE"
# shellcheck disable=SC1009,SC1054,SC1056,SC1072,SC1073,SC1083
{{- end }}
