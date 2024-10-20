This document talks about using the YAML files to template UCI config files.
If you're looking for the general configuration document please see [config.md](config.md).

# Templating the UCI files

Config directory for a device can contain `files` directory. This directory is then templated using `gomplate` and put into the image.

For example, you can create a file under `config/example/files/etc/example_file` and its contents (after templating) will be put in
the image under `/etc/example_file`.

This means that [UCI configuration](https://openwrt.org/docs/guide-user/base-system/uci) scriptlets can be defined and templated

## Hierarchy

The `files` directory are copied from two places:

1. `config/common/files`
2. `config/device_specific/files`

If a file with the same name is provided in both the common configuration and device-specific configuration, the device-specific configuration takes priority.

Similarly the values used during the templating come from few places, listed from the lowest to highest priority (latter overrides former):

1. `config/common/template-variables.yaml`
2. device-specific template variables (defaults to `config/device_specific/template-variables.yaml`)
3. device-specific secret variables (defaults to `config/device_specific/secret-variables.yaml`)

`secret-variables.yml` file is meant to only override the parts that can not be commited to git repo, e.g. passwords or API keys.
As such it should be listed in `.gitignore`.

## Common files

The files defined in `config/common/files` serve as a reasonable default for most of the configurations.
They allow for defining:

- networks (including VLANs)
- firewall rules
- dhcp hosts/domains
- letsencrypt certificates for the LuCI web interface
- wireless

Available options for these are documented next to the values in [config/common/template-variables.yaml](../config/common/template-variables.yaml)

## MWE

To get a working configuration with lan and guest network, configured SSH, exposing guest over wireless, you can put just
the below snippet in device-specific `template-variables.yaml` and the required UCI files will be templated into the image

```
hostname: example-router

security:
  root_password: somepassword

  ssh:
    keys:
      - ssh-ed25519 some-key some-key-comment

networks:
  lan:
    proto: static
    ipaddr: 192.168.1.1
    gateway: 192.168.1.1
    netmask: 255.255.255.0
    dhcp:
      start: 100
      limit: 150
      leasetime: 12h
  guest:
    proto: static
    ipaddr: 192.168.2.1
    gateway: 192.168.1.1
    netmask: 255.255.255.0
    dhcp:
      start: 100
      limit: 150
      leasetime: 12h
    firewall:
      zone:
        input: REJECT
        output: ACCEPT
        forward: REJECT
      forwarding:
        - wan

wireless:
  radios:
    radio0:
      country: PL
      enabled: true
  networks:
    GuestNetworkSSID:
      device: radio0
      mode: ap
      encryption: psk2
      key: GuestNetworkPassword
      isolate: true
      network: guest
      enabled: true
```
