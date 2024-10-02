#!/bin/bash

# Step 1: Update and Upgrade
sudo apt update && sudo apt upgrade -y

read -p "Enter WALLET name:" WALLET
echo 'export WALLET='$WALLET
read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" STORY_PORT
echo 'export STORY_PORT='$STORY_PORT

# set vars
echo "export WALLET="$WALLET"" >> $HOME/.bash_profile
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export STORY_CHAIN_ID="iliad"" >> $HOME/.bash_profile
echo "export STORY_PORT="$PORT"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
echo -e "Wallet:         \e[1m\e[32m$WALLET\e[0m"
echo -e "Chain id:       \e[1m\e[32m$STORY_CHAIN_ID\e[0m"
echo -e "Node custom port:  \e[1m\e[32m$STORY_PORT\e[0m"
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
git checkout v0.10.1
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

sleep 1
echo done

# create service file
sudo tee /etc/systemd/system/story-testnet-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which geth) --iliad --syncmode full --http --http.api eth,net,web3,engine --http.vhosts '*' --http.addr 0.0.0.0 --http.port 8545 --ws --ws.api eth,web3,net,txpool --ws.addr 0.0.0.0 --ws.port 8546
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

# enable and start service
# enable and start geth
sudo systemctl daemon-reload
sudo systemctl enable story-testnet-geth.service
sudo systemctl restart story-testnet-geth.service && sudo journalctl -u story-testnet-geth.service -f

# enable and start story
sudo systemctl daemon-reload
sudo systemctl enable story-testnet.service
sudo systemctl restart story-testnet.service && sudo journalctl -u story-testnet.service -f
