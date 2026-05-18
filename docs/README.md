# GenesisL1 documentation

This directory is the starting point for GenesisL1 operator and developer documentation. It keeps long-form operational guidance out of the repository root while leaving the root `README.md` as a short project overview and quick-start pointer.

## Operator docs

- [Node operator guide](node-operator-guide.md) — choose a setup path, prepare a host, bootstrap or upgrade a node, run the daemon, and move into validator operations.
- [Setup script reference](../setup/README.md) — details for the helper scripts under `setup/`.
- [VersionDB guide](../versiondb/README.md) — archive and non-validator node storage guidance.

## Protocol and API docs

- [Architecture decisions](architecture/README.md)
- [Proto API reference](api/proto-docs.md)
- JSON-RPC: [server](api/json-rpc/server.md), [endpoints](api/json-rpc/endpoints.md), [namespaces](api/json-rpc/namespaces.md), [events](api/json-rpc/events.md)

## Bridge docs

- [Gravity bridge development setup](gravity-bridge/dev-setup-guide.md)
- [Relayer modes](gravity-bridge/gravity-bridge-relayer-modes.md)
- [GORC build guide](gravity-bridge/gorc-build.md)
- [GORC keystore guide](gravity-bridge/gorc-keystores.md)

## Maintenance notes

When adding or changing docs:

1. Keep the root `README.md` focused on project identity and the shortest viable onboarding path.
2. Put step-by-step operational details in this directory or in `setup/README.md`.
3. Link to release-specific setup scripts instead of duplicating values that change per network upgrade.
4. Call out destructive actions, such as replacing `~/.genesis/data`, before the command block that performs them.
