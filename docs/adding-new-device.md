# Adding a new device

This process is easy to follow, you have to complete these steps:

1. Create a directory in `config/` with the name of your device, e.g. `config/example`
2. Create a file with env variables regarding the build: `config/example/variables`.
   It must at least point to the openwrt version that should be used

```
OPENWRT_VERSION="v23.05.2"
```

3. Obtain the `config.buildinfo` for your device and place it as file `config/example/config.orig`.
   You can find the `config.buildinfo` on [OpenWRT releases webpage](http://downloads.openwrt.org/releases/23.05.2/targets/) by
   navigating to the correct target.

And that's all, you can now run builds as usual.
