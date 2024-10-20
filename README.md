# OpenWRT build wrapper

This repo was initially developed as part of [network_layout](https://github.com/dezeroku/network_layout).

Scripts in this repo can be used to perform the build of OpenWRT from source and allow:

1. cloning the build repo in proper revision
2. setting up the .config for the build
3. downloading the projects dependencies
4. applying custom configuration
5. applying custom patches
6. performing the build

The idea here was to simplify the whole process, so it can be run with a single command, e.g. in the CI environment.
All the build scripts are run in a container and only require `docker` to be present on host.
Persistence is achieved by mounting the required directories in the container.

On top of that utility scriptlets ([scripts/utils](scripts/utils)) are provided that allow:

1. diffing the built images
2. applying the `sysupgrade` in an automated way
3. updating the OpenWRT revision to be used
4. generating SSH host keys for the router
5. entering interactive shell in the container

The builds are performed based on the settings defined in the [config](config) directory, each device should have its own
directory in there. _config_ directory can exist either within the repo itself or outside of it (e.g. this repository can be added
as a submodule in a different repo).
More details about the directory layout can be found in the [docs/config.md](docs/config.md) file.

[UCI configuration files](https://openwrt.org/docs/guide-user/base-system/uci) are generated for each device based on the YAML
config files. More details about that can be found in the [docs/templating.md](docs/templating.md) file.

For more in-depth description of the build system take a look at [docs/build-system.md](docs/build-system.md) file.

Upstream build instructions (that scripts in this repo are based on) can be viewed [here](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem).

For adding a new device take a look at [docs/adding-new-device.md](docs/adding-new-device.md) file.

# Usage

Let's assume that you have a device named `example` and you have already defined a configuration for it in the `config` directory.

## CI / One-Off Build

In this case you want to run all the build steps. This can be achieved with a single command:

```
DEVICE=example ./scripts/core/entrypoint
```

You can find the workspace under `builds/example` path.
The final image will land in `builds/example/bin/targets/...` directory.

## Development

If you want to introduce some changes to the configuration, you most likely want to set up the workspace, download the dependencies one
and only run the rebuilds. This can be achieved by following the listed steps

### Initialize Workspace

Clone the OpenWRT build repo, apply the customizations, download the source code for all of the dependencies.

It will not run the build (because of the `ONLY_INITIALIZE_WORKSPACE=true`).

```
DEVICE=example ONLY_INITIALIZE_WORKSPACE=true ./scripts/core/entrypoint
```

### Run the builds

At this stage you can freely modify the `config` and only rebuild what's needed, using the workspace initialized
in previous point.

With every call this command will:

1. reset the repo to base tag, defined in `variables` file
2. apply the customizations
3. perform the build (reusing cache from previous builds)

Note that if you change the `config/example/config` file, so that some new dependencies need to be downloaded, you can just
ditch the `SKIP_DOWNLOADS=true` option once to achieve that.

```
DEVICE=example SKIP_DOWNLOADS=true ./scripts/core/entrypoint
```

### Running a single build step

From time to time it may be useful to only run a single build step, e.g. only template the custom files or override the
make config. This can be achieved by running step's script in the `scripts/core` directory as so:

```
DEVICE=example ./scripts/core/run ./scripts/core/template-files
```

While possible to run outside of the provided docker container (without the `./scripts/core/run` wrapper), it's not recommended,
as it changes the build env used during the "real builds" and a single step run.
This can become especially problematic with the stages related to the make config.

### Entering the container

In case of modifying the make config with `make menuconfig` and debugging, interactive shell may come in handy.
An easy way to enter shell in the container with common build variables set is to run `./scripts/utils/enter-shell`
using the same set of env variables as for the normal builds

```
DEVICE=example ./scripts/utils/enter-shell
```
