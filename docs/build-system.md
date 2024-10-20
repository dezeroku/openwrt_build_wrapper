TODO: clean up this file

# Build Environment

To get the best results, a debian based environment is built, Dockerfile for which is kept in `docker` directory.
The image is very similar to the official build env.

## Build

The idea is to:

1. first apply the upstream `config.orig`
2. Put our custom changes (`config`) on top (concatenate the files)
3. Run `make defconfig` to expand the diffconfigs into proper full .config

Some warnings about overriding values are expected, as that's what we're doing with custom `.config`.

After the base config is applied and you do some changes with `make menuconfig` or similar, it's possible to easily obtain the custom diffconfig by running `./scripts/core/generate-diffconfig > config/$DEVICE/config` and inspecting the changes.

## Tips

If there's an error during the compilation, you can run make with additional `V=s` flag.
It might also be a good idea to run with `-j1`, so it's easier to see the error.

As `ccache` needs custom OpenWRT patches to work properly, setting it on system-level and then building `tools/ccache` can cause unexpected messups.
To resolve this problem, use `sccache` on system-host-level (e.g. to compile tools) and `ccache` internally in OpenWRT.
This is already handled in the Docker container.

## Comparing UCI configuration

TODO: obsolete this

For the sake of reproducibility (avoiding issues with glibc matching), you can build `uci-runner` docker image with `scripts/utils/build-uci-host`.
The image has `uci` available as `/usr/local/bin/uci`.

Using `scripts/utils/get-uci-config` script it's possible to retrieve the UCI default values from built image.
When such a default config is obtained, it's easy to calculate diff between the config currently in use on the router and the default.

`scripts/utils/diff-uci-configs` allows you to calculate a diff showing entries that are present in one file (the one that's meant to land on your device) and not present in the second one (the one that's default).
Thanks to this mechanism you can keep only a list of entries that are custom to your config and not provided by default.

## OpenWRT updates

TODO: move this section to a better place

1. Modify the `config/<DEVICE>/variables` to point to a new commit
2. Get new `config.buildinfo` for the release and put it in `config/<DEVICE>/config.orig`
3. (Recommended) Remove old workspace in `builds`
4. Run `end-to-end-build` script with `ONLY_INITIALIZE_WORKSPACE=true` in your env
5. Use `scripts/utils/generate-diffconfig` to override `config/<DEVICE>/config` and check the changes
6. Run the build as usual with `end-to-end-build` script

For the convenience this can be done by calling `scripts/utils/update-openwrt-version`
helper and providing DEVICE and NEW_OPENWRT_VERSION (which must be a git release tag from the OpenWRT repo, git commits won't work because of the releases URL) env variables.

## Checking the scripts used to build a used image

Sometimes you may not be sure what commit of this repo (and what variables) were used to build the image that you're currently using.
This may happen if you lose the checkout or the file due to e.g. a disk outage

In this case it's possible to check all the information required to reproduce the build by looking at `/etc/custom-version-file` file in the built image.
This file also persists when flashed on the device.

## Further wrappers

Sometimes issues can occur with builds running in Docker, it sometimes helps to wrap these further and run in VM `vagrant-setup` or remotely with `ec2-build` (this can also significantly speed up the build, but for a price).
