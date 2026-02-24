<h1 align="center">
  GenesisL1 Mainnet (Cronos fork)
</h1>

<p align="center">
  <ins>Release <b>v1.0.0</b> ~ Cronos <b>v1.0.15</b></ins>
</p>

<p align="center">
  <img src="https://avatars.githubusercontent.com/u/88520218" alt="GenesisL1" width="150" height="150"/>
</p>

<p align="center">
  Chain ID <b>genesis_29-2</b>
</p>

<p align="center">
   A source code fork of <b>Cronos</b> and <b>Ethermint</b>
</p>

<p align="center">
  Cosmos SDK <b>v0.46.15</b>
</p>

---

## 🧭 Introduction

Due to the recent on-chain minting of the full Protein Data Bank (PDB), the size of the GenesisL1 blockchain has increased significantly. This data-heavy event resulted in a substantial boost to storage requirements and syncing time. To address this, the GenesisL1 community provides multiple streamlined methods to get a node up and running quickly — including a bootstrapped `data` folder backup that allows syncing within hours instead of several days.

> ⚠️ **IMPORTANT:**
> In **Step 2**, you will need to choose **one setup method**: Option A, B, or C. Only follow **one** of these — copying all three will cause your setup to fail.

This repository is intended for those who want to join the Cronos-fork **mainnet**: `genesis_29-2`, using one of the following paths:

### 🔹 OPTION A: Bootstrapped Snapshot (Fastest Setup)
Use a fully synced 622GB `data` folder provided by the community, compressed to ~543GB.

### 🔹 OPTION B: State Sync Setup (Recommended for New Nodes)
Sync your node from a trusted block height using the built-in **state sync** mechanism.

### 🔹 OPTION C: Upgrade Existing Node
Migrate from the legacy Evmos-based network `genesis-ethermint` to the current Cronos-fork chain.

> [!WARNING]
> ⚠️ **Legacy Node Warning:**
> 
> We were an Evmos-fork before deciding to hard fork to Cronos. If you're attempting a full-node sync from scratch, follow the instructions in the [`genesis-ethermint`](https://github.com/GenesisL1/genesis-ethermint) repository first.


---

## 1. ⚙️ System Requirements

### Hardware

- **Disk**: 1000GB+ (NVMe M.2 SSD recommended)  
- **RAM**: 8GB+ (16GB+ recommended)  
- **CPU**: 4+ physical CPU cores | 8+ threads  
- **Network**: > 100Mbit/s stable connection bothways 

### Software Setup

Debian based OS

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget build-essential git make gcc liblz4-tool htop unzip -y
```

### 💡 Enable Swap (Optional but Recommended)

```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

To persist:

```bash
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 2. 🛠️ Node Setup Options

> [!IMPORTANT]
> Choose **one** method and expand the '>' :

### 🔹 A. Bootstrap with Provided Snapshot (Fastest; Trustfull)

<details>
<summary> Quick-Sync from provided `data` backup </summary>

```bash
cd ~
wget https://ftp.basementnodes.ca/genesis_backup_20250407082420.tar.lz4
```

If this one is currently unavailable try the following

```bash
cd ~
wget http://85.122.195.176:55865/genesis_backup_20250505.tar.gz
```

let the download finish and grab a coffee. 

setup the github repo.

```bash
git clone https://github.com/JoMfN/genesis-crypto.git
cd genesis-crypto
```

create a `.genesis` folder with your config in the meanwhile.

```bash
sh setup/quick-sync.sh <moniker>
```

Follow the instructions in the terminal.

check if a .genesis folder was generated.

unzip the fully downloaded `data` folder 

```bash
lz4 -d genesis_backup_20250407082420.tar.lz4 | tar -xvf -
```

If you downloaded the .tar.gz file instead:

```bash
tar -xvzf genesis_backup_20250505.tar.gz
```

replace it with the one existing in `~/.genesis/data`

```bash
mv genesis_backup_20250407082420/* ~/.genesis/
```

If you downloaded the .tar.gz file instead:

```bash
mv genesis_backup_20250505/* ~/.genesis/
```

> ⚠️ Ensure `genesisd` is not running before replacing `.genesis`

</details>

### 🔹 B. State Sync from Recent Height (Trusted)

<details>
<summary> Setup a node _(using state sync)_ from a snapshot </summary>

```bash
git clone https://github.com/GenesisL1/genesis-crypto.git
cd genesis-crypto
git checkout v1.0.0
```

> [!IMPORTANT]
> Running this will **wipe the entire database** (the _/data_-folder **excluding** the priv_validator_state.json file). Therefore if you already have a node set up and you prefer not to have your GenesisL1 database lost, create a backup.
>
> You could use [utils/backup/create.sh](/utils/backup/create.sh) for this.
>

```bash
sh setup/state-sync.sh <moniker>
```

> 💡 This method will auto-install `genesisd` and dependencies

</details>


### 🔹 C. Upgrade from `genesis-ethermint` (Trustless)

<details>
<summary>⚙️ Upgrade an ethermint Node synced from scratch </summary>

> ⚠️ **Legacy Node Warning:**
> If you're attempting a full-node sync from scratch, follow the instructions in the  (repo: [`genesis-ethermint`](https://github.com/GenesisL1/genesis-ethermint)) and the node synced till height: `7400000` which caused it to panic.
>

Then to upgrade to the new **mainnet** (`genesis_29-2`):

```bash
sh setup/upgrade.sh
```

</details>

---

## 3. Daemon check

If you can't access the `genesisd` command at this point, then you may need to execute:

```bash
. ~/.bashrc
```
> Or the equivalent: `source ~/.bashrc`

Try if now if you can initiate the node

```bash
genesisd start --log_level warn
```

> Confirm everything initializes correctly, then stop it (Ctrl + C).

(Stop with Ctrl + C after confirmation)

<details>
<summary>⚙️ getting errors with helper script Go Installation (ignore if no error above)</summary>

**For AMD:**

```bash
ver="1.22.12"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
```

**For ARM (Raspberry Pi 5):**

```bash
wget https://go.dev/dl/go1.22.12.linux-arm64.tar.gz 
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go1.22.12.linux-arm64.tar.gz"
rm "go1.22.12.linux-arm64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
```

</details>

---

## 4. Create or import a key (optional for just a node, required for validator node)

A key is necessary to interact with the network/node. If you haven't already created one, either import one or generate a new one, using:

replace `<walletname>` with an arbitrary name for your wallet key

```bash
sh utils/key/create.sh <walletname>
```

OR

```bash
sh utils/key/create.sh <walletname> <private_eth_key>
```

> _<private_eth_key>_ is the private key for a (wallet) address you already own (not recommended).

> [!TIP]
> 💡 **TIP:** Clear bash history:  
> `history -c && exec bash`
>

> [!NOTE]
> Transfer some L1 to the wallet you just created
>

to check your keys:

```bash
genesisd keys list
```

To check wallet balance:

```bash
genesisd query bank balances $(genesisd keys show <walletname> -a)
```


<details>
<summary>🔐 Pro Key Management</summary>

Creating a new wallet (write down you seed phrase with pen and paper!)

```bash
genesisd keys add <walletname>
```

OR

Recover a wallet:

```bash
genesisd keys add <walletname> --recover
```

The terminal will request you to input the 24-words long seed phrase

</details>

---

## 5 installing genesisd as a service (optional)

In general you can always start the node just once, and have to keep track of this terminal window by prompting: 

```bash
genesisd start --log_level warn
```

This can be automized by installing it as a service checkout the details below.


<details>
<summary>🖥️ Systemd Service Setup</summary>

```bash
sudo nano /etc/systemd/system/genesisd.service
```

Paste this:

```
[Unit]
Description=genesisd
After=network-online.target

[Service]
User=$USER
ExecStart=$(which genesisd) start
Restart=on-failure
RestartSec=15
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Start it:

```bash
sudo systemctl start genesisd
```

check hidden genesisd output

```bash
journalctl -fu genesisd -ocat
```

</details>

---

## 6. Become a validator (optional, also very welcoming)

> [!Warning]
> make sure you are in sync and `genesisd` is running

```bash
genesisd status
```

should show `"catching_up":false`

```json
"catching_up": false
```

Once your node is _up-and-running_, _fully synced_ and you have a _key_ created or imported, you could become a validator using:

```
sh setup/create-validator.sh <moniker> <walletname>
```

> This is a wizard and shall prompt the user only the required fields to create an on-chain validator.


<details>
<summary>⚙️ Pro Validator Setup</summary>

Watch the sync status by opening a new terminal and prompt `genesisd status` again. When you are in sync this appears:

```json
"catching_up": false
```

Adjust gas-prices and gas if the transaction gives the error out-of-gas

```bash
genesisd tx staking create-validator \
  --amount=1000000el1 \
  --pubkey=$(genesisd tendermint show-validator) \
  --moniker="YOUR_NODE_NAME" \
  --identity="More_Info_You_Want_To_Add" \
  --website="" \
  --details="Example: Community Valoper node and Supporter of GenesisL1" \
  --security-contact="YourEmail@mail.com" \
  --chain-id="genesis_29-2" \
  --commission-rate="0.05" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=355172 \
  --gas-prices=1127530424125el1 \
  --from=<walletname> \
```

</details>

---

## 7. Explore utilities

> [!TIP]
> The [/utils](/utils)-folder contains useful utilities one could use to manage their node (e.g. for fetching latest seeds and peers, fetching the genesis state, quickly shifting your config's ports, recalibrating your state sync etc.). To learn more about these, see the [README](utils/README.md) in the folder.

---

### 7.1 FAQ and useful links

FAQ -> Welcome for suggestions

Useful links presented below 

> [!TIP]
> 
> [`Checking status of your validator node at ping.pub`](https://ping.pub/genesisL1/uptime)
>
> [`MolNFT App`](https://app.molnft.org/)
>
> [`Anode team node installation guide`](https://anode.team/GenesisL1)
>
> [`starv-team node installation guide`](https://stavr-team.gitbook.io/nodes-guides/mainnets/genesisl1/node-installation)
>

## 8. Acknowledgements

Special thanks to the contributors who made this bootstrap flow possible:

- [@Zenodeapp](https://github.com/Zenodeapp) — for reviewing these instructions and optimizing the required scripting.
- [@Cordtus](https://github.com/Cordtus) — for hosting and maintaining the FTP server for snapshot distribution.
