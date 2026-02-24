## /info

### [my-peer.sh](../info/my-peer.sh)

This script will print out your peer-id: _node-id@ip-address:port_. This is useful for sharing your node with others so that they can add you as a persistent peer.

Bear in mind that the _port_ being echo'd is extracted from the _config.toml_-file. So if you start the node on a different port without explicitly stating this in the _config.toml_-file, then the outputted port may not represent the actual port this node uses.

```
sh info/my-peer.sh
```

> Add a --local flag to echo a local IP address, instead of your (public) external address.
