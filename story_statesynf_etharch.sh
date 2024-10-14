#!/bin/bash

# Step 1: Update and Upgrade
sudo apt update && sudo apt upgrade -y

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" STORY_PORT
echo 'export STORY_PORT='$STORY_PORT
read -p "Enter your PORT for GETH (for example 88, default port=85):" STORY_PORT_GETH
echo 'export STORY_PORT_GETH='$STORY_PORT_GETH

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export STORY_CHAIN_ID="iliad"" >> $HOME/.bash_profile
echo "export STORY_PORT="$PORT"" >> $HOME/.bash_profile
echo "export STORY_PORT_GETH="$STORY_PORT_GETH"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$STORY_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$STORY_PORT\e[0m"
echo -e "Node custom port geth:  \e[1m\e[32m$STORY_PORT_GETH\e[0m"
sleep 1

printGreen "1. Installing go..." && sleep 1
# install go, if needed
cd $HOME
VER="1.23.1"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin

echo $(go version) && sleep 1

# install dependences
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

printGreen "4. Installing binary..." && sleep 1
# download binary
cd $HOME
rm -rf bin
mkdir bin
cd bin
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz
tar -xvzf geth-linux-amd64-0.9.3-b224fdf.tar.gz
mv ~/bin/geth-linux-amd64-0.9.3-b224fdf/geth ~/go/bin/
mkdir -p ~/.story/story
mkdir -p ~/.story/geth

cd $HOME
rm -rf story
git clone https://github.com/piplabs/story
cd story
git checkout v0.11.0
go build -o story ./client
sudo mv ~/story/story ~/go/bin/

# initialize the story client
story init --moniker $MONIKER --network $STORY_CHAIN_ID
sleep 2
echo done

# set custom ports in config.toml file
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${STORY_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${STORY_PORT}657\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${STORY_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${STORY_PORT}660\"%" $HOME/.story/story/config/config.toml
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:${STORY_PORT}656\"/" $HOME/.story/story/config/config.toml

SEEDS="6127cdd105667912f3953eb9fd441ad5043dbda8@167.235.39.5:26656,51ff395354c13fab493a03268249a74860b5f9cc@story-testnet-seed.itrocket.net:26656,5a0191a6bd8f17c9d2fa52386ff409f5d796d112@b1.testnet.storyrpc.io:26656,0e2f0d4b5204e5e92a994a1eaa745b9ccb1d747b@b2.testnet.storyrpc.io:26656"
PEERS="7686492ec120d9e8e754c337ab21a139bd65a8b1@75.119.145.90:26656,19e6d8071820297a32fd4ebfa6b05efa5882a236@65.109.130.217:26656,8c1b516805e0c4631306032a0108e51339ab7cfd@78.46.60.145:26656,d54d1bdbe7ff2f6f250c7d1c16853bb6c5fa4d53@77.68.82.101:26656,3061ea70f7429088a0df90120496d14a85cdc505@138.2.53.213:26656,ada36795d8d84cefdb7c6a0c3ca3faedb2b091e8@152.53.66.0:26656,537b4c11a17f282bd9f84ba578e5998944c49c79@176.9.155.156:28656,cbac5c33ccfda7c86ed0af588defa9362f62a5e9@77.90.43.44:26656,de6a4d04aab4e22abea41d3a4cf03f3261422da7@65.109.26.242:25556,f93d33e57a8b0b873f4439bd0e47ba04d4563c2d@65.21.229.226:39656,fe5b39d2bd701ed12a953894cc1449d4c5c6d699@135.125.189.91:26656,58c02d9ca3708fee44e3138d42f176df8100650b@84.247.167.167:26656,d2d0c17e43378259adb40a103361992105786dcd@46.105.48.235:26656,6654567779ffb927eb3d36f058b3a13959154b0a@38.242.158.136:26656,9b234101b92bbdb30c0ace230771e71895a7a5bc@185.133.248.5:26656,f22ec9a759a63e12b59847cc210aa72cb16d2743@185.250.148.147:26656,412bf6e15c1d441276464120c496d839afdd90e7@38.242.238.182:26656,3d12549f08675eff94f3599f849de0e84b639f9c@46.105.55.149:26656,24680170773c73364479019b483b28918d225228@46.105.47.240:26656,bbf178a81921b81f8468c0d9c835f3b499a80fed@194.233.70.90:26656,13d478e54aee90e615e3199dea1c68a83aa995a7@46.105.57.39:26656,daa14069120493fbabb7a760f08432e0c272b2d8@37.60.238.248:26656,5aa23a5ba37c09dca04c01f0f78b40c47cab8654@135.181.61.214:26656,ee01a5b8d6c5cced75ae65018e6494df8bcbe352@116.202.219.112:26656,1b721a5a8f3043d6e3f3e3798716c7da4e349484@46.105.47.161:26656,74f6987aa9f7029aa9cca4a5c92773fd7907e991@65.108.130.39:27656,d6416eb44f9136fc3b03535ae588f63762a67f8e@211.219.19.141:31656,72da48cef917ecad1e2b77f261a976ff9f865f59@178.63.118.247:26656,ef4efc0e44c74807daf8996b3e0bb945eb3e26b0@15.235.14.88:26656,e253e62e6020e7332d260b698dd11079daffeebc@37.27.127.145:42656,8ed7e25b9b2ec3c7ef610d0af8936d3bd1550463@77.90.43.56:26656,1c4667bcf055076f4b31c9d5919ae309d336c9a6@216.244.65.210:26656,5a0191a6bd8f17c9d2fa52386ff409f5d796d112@3.209.222.188:26656,84397d2a53b940acd4f4ca4f4f54b1afd1bae1e6@212.192.222.45:26656,afd20f2a8a47e3da0f1e0f4ab84a5c27b2a20966@157.173.119.105:26656,e5df9f2d38ab335edd61457e18f0b735ab7e1446@157.173.110.238:26656,3833efddd6665ffaf20950abad7c8bb4918c0161@65.109.111.234:26656,947bcd90d244978eb22c63b59e49ebf18a600f54@135.181.240.57:11556,1738c699d7e9e5a41ca82a1392a78117e6ec3c61@212.192.222.76:26656,a2e1b434c0ea7d4c7d90f86c578ea7eceb2320b2@65.109.58.86:29256,f5a282ee74bac46157db7d5763d6efeda18b812a@51.210.195.102:26656,8a40772cc18317653674097a82915b595e6c6922@178.63.118.246:26656,16e108b33a82a1f61ffb99c0d3a9f02c10d9a148@46.105.55.249:26656,bcc50c1f47beaa8f636cb3da1c2cfdbda1a041a7@129.213.50.100:26656,876ac207f504696f7f625e171b1a449cd260eeaf@62.84.185.143:26656,5c3d551822ae0576e4a31ae6979e9f5b626e4dca@91.108.246.111:26656,58e07e11602fa804409489f76eec6fb5192c2edc@150.136.32.205:26656,9e6d1ed7e1b9180f83b60158194f62cf408f48cb@188.40.176.61:26656,6f24e2e8f9869c109f18d25df42727ed72ef4921@178.63.118.251:26656,08c3fde7f6496a98fbe9c5bdc80694c290552d5e@49.82.84.39:26656"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
-e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" \
$HOME/.story/story/config/config.toml

sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/story-testnet-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which geth) --iliad --syncmode full --http --http.api eth,net,web3,engine --http.vhosts '*' --http.addr 0.0.0.0 --http.port ${STORY_PORT_GETH}45 --ws --ws.api eth,web3,net,txpool --ws.addr 0.0.0.0 --ws.port ${STORY_PORT_GETH}46
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/story-testnet.service > /dev/null <<EOF
[Unit]
Description=Story Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=$(which story) run

Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

#addrbook
wget -O $HOME/.story/story/config/addrbook.json "https://snapshots.tarabukin.work/storyfile/addrbook.json"

#geth snapshot
rm -rf $HOME/.story/geth/iliad/geth/chaindata
sudo mkdir -p $HOME/.story/geth/iliad/geth/chaindata
cd $HOME/.story/geth/iliad/geth/chaindata
wget https://snapshots.tarabukin.work/storygeth/storygeth_latest.tar
tar -xvf storygeth_latest.tar
rm storygeth_latest.tar

# enable and start service
# enable and start geth
sudo systemctl daemon-reload
sudo systemctl enable story-testnet-geth.service
sudo systemctl restart story-testnet-geth.service

cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup

story tendermint unsafe-reset-all --home $HOME/.story/story
peers="6127cdd105667912f3953eb9fd441ad5043dbda8@167.235.39.5:26656"  
SNAP_RPC="https://story-rpc.tarabukin.work:443"
sed -i.bak -e  "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" ~/.story/story/config/config.toml
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH && sleep 2

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ~/.story/story/config/config.toml

mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

# enable and start story
sudo systemctl daemon-reload
sudo systemctl enable story-testnet.service
sudo systemctl start story-testnet.service && sudo journalctl -fu story-testnet.service -o cat
