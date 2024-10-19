#!/bin/bash

# Step 1: Update and Upgrade
sudo apt update && sudo apt upgrade -y

read -p "Enter your MONIKER :" MONIKER
echo 'export MONIKER='$MONIKER
read -p "Enter your PORT (for example 17, default port=26):" STORY_PORT
echo 'export STORY_PORT='$STORY_PORT
read -p "Enter your PORT for GETH (for example 88, default port=85):" STORY_PORT_GETH
echo 'export STORY_PORT_GETH='$STORY_PORT_GETH

# set vars
echo "export MONIKER="$MONIKER"" >> $HOME/.bash_profile
echo "export STORY_CHAIN_ID="iliad"" >> $HOME/.bash_profile
echo "export STORY_PORT="$STORY_PORT"" >> $HOME/.bash_profile
echo "export STORY_PORT_GETH="$STORY_PORT_GETH"" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "Moniker:        \e[1m\e[32m$MONIKER\e[0m"
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
wget -O geth https://github.com/piplabs/story-geth/releases/download/v0.9.4/geth-linux-amd64
chmod +x geth
mv $HOME/bin/geth ~/go/bin/

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
PEERS="cfb6843115338d04a00719a0e41e88ee338d104d@185.205.244.23:26656,09d408ab5cec77b93cec65e32b891983e3110b34@188.245.106.10:26656,cbaa226e66502b6b032f5e648d4d754f26bf9ca6@65.109.84.22:47656,3fc516ce3f717dcba98ff5c284d4537764add8e4@162.55.98.31:23556,359e4420e63db005d8e39c490ad1c1c329a68df3@3.222.216.118:26656,0b512c9a4421c0259813aaa05c865f82365fa7c0@3.1.137.11:26656,f4d96bf0dc67a05a48287ca2c821bc8e1d2b2023@63.35.134.129:26656,8e8c802cecd68d392e372dc8cd99d197fff23ccc@18.190.77.29:26656,aaa8f53d0b7ee4df039859808326ee7f07ab85fa@38.242.149.97:26656,757bbf4a01695e6329198cf6409928b8a8a3681e@91.205.104.84:26666,15c7e2b630c04ee11b2c3cfbfb1ede0379df9407@52.74.117.64:26656,d86e7d2995f3cfde015c51eed474166fa76ab7b6@18.221.130.122:26656,9d8045a6f4143628e671e6f53628575148953a43@109.123.242.114:26656,0b554d4427cb51925e503aca40c25dd0d473e0e9@185.208.207.222:26656,c94125a145da9dccd6b1f035f78a551208b3f682@65.109.68.87:28656,960278d079a111b44c207dca7c2ffac640b477d1@44.223.234.211:26656,bdaef55836c56977b1b33e76c09d283f392b7759@109.123.244.100:26656,c82d2b5fe79e3159768a77f25eee4f22e3841f56@3.209.222.59:26656,f16c644a6d19798e482edcfe5bd5728a22aa5e0d@65.108.103.184:26656,7722bb268ee8b27db003f3e3ece864f4d09984fa@149.102.139.42:26656,d6262ed11a285ac6324ca26a431828ab6f453665@37.27.114.99:24556,a004b01bb1604d134874f4a33fdf21841568fea4@49.12.122.24:21356,d4c5dcfbec11d80399bcf18d83a157259ca3efc7@138.201.200.100:26656,3f9ad4d8cab4cce46de2087e64d7be3252f391d1@65.108.6.41:15656,26fced9240cbf4de6e3685148e0dd27ef82e4a34@185.188.249.184:26656,3b452f8c6217dc7d3ae2d1032714c1fb5fc20631@38.242.137.116:26656,2fb2dabf4656c81082ee939dc0fb27cad8e532bb@185.197.195.212:26656,371ee318d105b0239b3997c287068ccbbcd46a91@3.248.113.42:26656,51444e3429ea6ba72a2d1993409354bff9b5b1c6@207.180.205.21:26656,aac5871efa351872789eef15c2da7a55a68abdad@88.218.226.79:26656,b35fe156b29d457469d71d26f3c35b9e4a215742@86.48.1.19:26656,76efe760a81b6d5953a46231da8c13f130e26224@65.109.28.124:23956,43b0730a66d4da6747fbeb532caa49e47c6ec168@84.247.179.97:26656,8876a2351818d73c73d97dcf53333e6b7a58c114@3.225.157.207:26656,489fd0b2b9ba4e89ea42c82bf2b1fd8668d15e4e@148.251.51.140:21556,afd6e704ed998d567592784c7adac9e1800e458b@194.146.12.225:26656,95c28e5f3087c919be63791f8c5dcede23002d43@77.68.126.91:26656,c5d5626a9da3a3ff7dc65c5b973b758a1a9ee13b@65.108.229.11:53656,f06f358be0934cd4a7250dc7cc081d98402237df@157.173.104.214:26656,3625d99f0be1fca7401115648bc8fe758583dca0@185.190.140.80:26656,581f3bdcd1228e1449d1eb04a52f1be8d18c20a4@84.21.171.120:26656,e33c46d68340f435a6cf548f99e6644342ad829f@65.109.85.166:26056,7ed765311d0b316fda0bb7d824e5894f50338d76@185.250.36.30:26656,d9e4b3ad3c5e52d76c5c4dcfdede7a3567c4205c@45.10.154.250:26656,6bb4ed28b08a186fc1373cfc2e96b83165c1e882@162.55.245.254:33656,a2fe3dfd6396212e8b4210708e878de99307843c@54.209.160.71:26656,07ab4164e1d0ee17c565542856ac58981537156f@37.27.124.51:42656,1ab9c0196b17c6c9297553d22ecbccd290f72ef9@109.123.243.85:26656,5e4f9ce2d20f2d3ef7f5c92796b1b954384cbfe1@34.234.176.168:26656,0dcc9f02b0e6404596e40e55767e2a6c55e8ab0d@146.59.118.198:29256,00119f207d82782f91398eb3ed4bee6453f1dd09@109.123.255.200:26656,5d7507dbb0e04150f800297eaba39c5161c034fe@135.125.188.77:26656,feb6a61b73040de917a7728bd83263d7e02fc52b@65.109.60.108:24956,0576d4cf22288624e01e52a9aa39a68ed3c64274@38.242.158.148:26656,cda5537fff03e00e86f424dd195b31d92ecfe4e6@193.203.15.105:26656,6df2d25510bf05ab74fec850756553e081cdc16a@83.171.248.244:26656,b1c339e70f50d747489c95a679e63d21d60225ce@184.174.39.129:26656,bf55695f3616be7e3133d457778d5d07fd96b28b@45.85.146.254:26656,78e77f248f6beb72c496493a18086ab00f676216@162.55.94.150:21756,22f9cce87bca2dc46896e5646247e2d1c35a81c9@84.46.251.38:26656,627c7ed36292d951639f4aab324d1c5f888775f6@38.242.220.212:26656,6457053fbaaf95814cd369189f24284a7349c63f@45.151.122.167:26656,79e61647246fe85612c7286d8e7a4e475342d429@194.163.181.249:26656"
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
