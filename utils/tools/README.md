## /tools

### [restate-sync.sh](../tools/restate-sync.sh)

> [!CAUTION]
> Only use this if the network your node is connected to supports state-sync!

This tool recalibrates your state-sync configurations to a more recent height. **WARNING: this wipes your entire data folder, but will backup and restore the priv_validator_state.json file**. It uses the script(s) from the [`restate-sync`](https://github.com/zenodeapp/restate-sync/tree/v1.0.1) repository (`v1.0.1`). If in doubt whether this is safe, you could always check the repository to see how it works.

```
sh tools/restate-sync.sh [height_interval] [rpc_server_1] [rpc_server_2]
```

> [height_interval] is optional (default: 2000). This means it will set the trust_height to: latest_height - height_interval (rounded to nearest multiple of height_interval).
>
> [rpc_server_1] is optional (default: first rpc server configured in your config.toml file). If there is no rpc server configured, the script will abort.
>
> [rpc_server_2] is optional (default: rpc_server_1).

> [!NOTE]
> Leaving the _<rpc_server>_-arguments empty will leave the rpc_servers field in your config.toml untouched.

### [port-shifter.sh](../tools/port-shifter.sh)

This script is useful if you quickly want to replace the ports in the `client.toml`, `config.toml` and `app.toml` files. It uses the script(s) from the [`port-shifter`](https://github.com/zenodeapp/port-shifter/tree/v1.0.1) repository (`v1.0.1`). If in doubt whether this is safe, you could always check the repository to see how it works.

```
sh tools/port-shifter.sh <port_increment_value>
```

> <port_increment_value> is how much you would like to increment the value of the ports based on the default port values.
