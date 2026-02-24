## /service

### [install.sh](../service/install.sh)

This script installs the daemon as a service, which will automatically start the node whenever the device reboots. See the `$SERVICE_DIR` and `$SERVICE_FILE` variables in [\_variables.sh](../_variables.sh) to see which service gets installed.

```
sh service/install.sh
```

### [uninstall.sh](../service/uninstall.sh)

This script uninstalls the daemon as a service. See the `$SERVICE_FILE` variable in [\_variables.sh](../_variables.sh) to see which service gets uninstalled.

```
sh service/uninstall.sh
```
