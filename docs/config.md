This document talks in general about the `config` directory layout.
If you're looking for the YAML based templating document please see [templating.md](templating.md).

# Per device config

The configuration files for a device should be stored in `config/device_name` directory.

There are few files that are required:

1. `config.orig` - upstream .config file, used to initialize the workspace
2. `variables` - file containing env variables that should be present during the build.
   Customisable with `DEVICE_ENV_FILE`.
   This file should at least define the OpenWRT version to use, e.g.

```
OPENWRT_VERSION="v23.05.2"
```

There are also files that are optional and can be used to customize the build.
Take a look at the YAML based templating document please see [templating.md](templating.md) for more details.

1. `config` - diffconfig with custom changes, applied on top of config.orig.
   You'd usually obtain it by modifying the configuration in workspace with `make menuconfig` and then runnning
   `/scripts/utils/generate-diffconfig`.
   Customisable with `DEVICE_CONFIG_FILE`
2. `files/` - directory of files that should be templated and copied to the image.
   Please note that by default (if `REPRODUCE_UPSTREAM_BUILD=true` env variable is not defined) the files from
   `config/common/` directory will also be templated and copied.
3. `patches/` - directory of patches to apply in the OpenWRT build workspace.
   At the moment two types of patches are supported, `.patch` which are git patches appliable with `git am` (can be generated
   with e.g. `git format-patch HEAD^1`) and `.sh` which are scripts that will be run.
   The `.patch` approach is recommended, as it has better guarantees regarding reseting the workspace to a base state.
   Patches can also be stored in the corresponding directories, meaning patch located under `patches/some/directory` is equivalent
   to performing the patch operation in `some/directory` in the build workspace.
   Patches are templated in the same manner as `files/`
4. `template-variables.yaml` - file containing variables that are templated into `files/`.
   Customisable with `DEVICE_TEMPLATE_ENV_FILE`
5. `secret-variables.yaml` - file overriding "template-variables.yaml" values.
6. `lib.sh` - file definining few bash functions useful from the `utils` point of view:

- `unpack_image() [.img.gz to unpack] [directory to output]` - used e.g. when diffing the built images
