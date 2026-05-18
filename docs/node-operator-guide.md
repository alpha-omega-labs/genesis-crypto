# GenesisL1 node operator guide

This guide is a docs-first companion to the root `README.md`. It gives operators one page to choose a path, prepare a host, and find the right setup script without mixing those details into the repository overview.

## 1. Choose the correct setup path

GenesisL1 mainnet currently uses chain ID `genesis_29-2`. Before running commands, decide which path matches your node:

| Path | Use it when | Primary script or command |
| --- | --- | --- |
| Bootstrapped snapshot | You are starting a new full node and want the fastest sync path. | `setup/quick-sync.sh` plus a trusted community snapshot. |
| Existing node upgrade | Your node has halted at a planned upgrade height or you are upgrading a legacy node. | `setup/upgrade.sh` from the release you are upgrading to. |
| Staged upgrade | You want to build the next binary before the chain reaches the upgrade height. | `setup/staged-upgrade.sh`. |
| Validator creation | Your node is fully synced and you have a funded local key. | `setup/create-validator.sh`. |

> [!IMPORTANT]
> Use the setup scripts from the same release tag or commit that matches the upgrade you are applying. Upgrade scripts are release-dependent.

## 2. Prepare the host

Recommended baseline:

- Debian-based Linux host.
- 1000GB+ NVMe storage for a full node.
- 8GB RAM minimum; 16GB+ recommended.
- 4 physical CPU cores or better.
- Stable network connectivity above 100Mbit/s.

Install common dependencies:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget build-essential git make gcc liblz4-tool htop unzip jq ca-certificates rsync lz4 pv -y
```

Optional swap for small hosts:

```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Persisting swap is host-specific; back up `/etc/fstab` before editing it.

## 3. Bootstrap a new full node from a snapshot

A snapshot is the fastest path, but it relies on the snapshot provider. Verify the source before use.

1. Clone the repository and check out the release you intend to run:

   ```bash
   git clone https://github.com/GenesisL1/genesis-crypto.git
   cd genesis-crypto
   git checkout v1.1.1
   ```

2. Create the base home directory and configuration:

   ```bash
   sh setup/quick-sync.sh <moniker>
   ```

3. Stop `genesisd` if it is running, then replace only the data directory with the downloaded snapshot:

   ```bash
   rm -r ~/.genesis/data
   lz4 -d data.tar.lz4 | tar -xvf - -C "$HOME/.genesis"
   ```

4. Start the daemon and watch logs:

   ```bash
   genesisd start --log_level warn
   ```

## 4. Upgrade an existing node

Use this path when the node has halted at a planned upgrade height or you are moving a legacy node forward.

1. Confirm the plan name, halt height, and target version in the root `README.md` or the release notes.
2. Check out the matching release:

   ```bash
   cd ~/genesis-crypto
   git checkout <version-to-upgrade-to>
   ```

3. Run the release-specific upgrade script:

   ```bash
   sh setup/upgrade.sh
   ```

4. Restart and monitor:

   ```bash
   sudo systemctl start genesisd
   journalctl -fu genesisd -ocat
   ```

For upgrades that should be built ahead of the halt height, see the staged upgrade flow in [`setup/README.md`](../setup/README.md#staged-upgradesh).

## 5. Run as a systemd service

The root `README.md` includes a minimal service example. Before enabling a service, confirm that `genesisd start --log_level warn` works interactively.

Typical service workflow:

```bash
sudo systemctl daemon-reload
sudo systemctl enable genesisd
sudo systemctl start genesisd
journalctl -fu genesisd -ocat
```

## 6. Validator handoff checklist

Only create a validator after the node is fully synced.

- `genesisd status` reports the node is caught up.
- The local key exists or has been imported.
- The wallet has enough funds for the validator transaction.
- The operator understands the commission, moniker, website, and security-contact values being submitted on-chain.

Use the helper script when ready:

```bash
sh setup/create-validator.sh <moniker> <walletname>
```

## 7. Related references

- [`setup/README.md`](../setup/README.md) for script-level behavior.
- [`../README.md`](../README.md) for the project overview and current network values.
- [`../utils/README.md`](../utils/README.md) for node utility scripts.
- [`versiondb/README.md`](../versiondb/README.md) for archive and non-validator storage options.
