#!/bin/sh

# Dynamically update list of DNS entries based on node availability (ping)

# Requires ping and dnsmasq (configured as defined in uci-defaults present in this repo)
# to be present on the machine

echo "Starting addresses_ha helper"

# We disable the check, as the templating is done via gomplate first
# shellcheck disable=SC2016
ADDRESSES_HA='{{ range $name, $config := .dhcp.addresses_ha }}{{ range $config }}/{{ print $name }}/{{ . }} {{ end }}{{ end }}'

if [ -z "$ADDRESSES_HA" ]; then
	echo "No addresses provided, exiting"
	exit 0
fi

if ! command -v ping >/dev/null; then
	echo "ping command is not installed, aborting"
	exit 1
fi

while :; do
	config_changed=false

	# We actually want the globbing here
	# Default OpenWRT's shell seems to not like splitting on space by default
	# so we replace spaces with newlines on our own
	# shellcheck disable=SC2086
	for address in $(echo $ADDRESSES_HA | tr " " "\n"); do
		# dns_name="$(echo "$address" | cut -d "/" -f2)"
		dns_ip="$(echo "$address" | cut -d "/" -f3)"

		# echo "Testing  $dns_ip availability for $dns_name"

		# Try to ping node with 2sec timeout
		wanted=$(ping -c 1 -W 2 "$dns_ip" >/dev/null && echo "true" || echo "false")

		# Surround the grep with spaces to make sure an exact match is present
		present=$(echo " $(uci get dhcp.@dnsmasq[0].address) " | grep -q " $address " && echo "true" || echo "false")

		[ "$present" = "$wanted" ] && continue

		config_changed=true
		action="Removing"
		cmd="del_list"
		[ "$wanted" = "true" ] && action="Adding  " && cmd="add_list"

		echo "$action $address"
		uci $cmd dhcp.@dnsmasq[0].address="$address"
	done

	uci commit dhcp.@dnsmasq[0]

	if [ "$config_changed" = "true" ]; then
		echo "Reloading dnsmasq"
		/etc/init.d/dnsmasq reload
	fi

	sleep 60
done
