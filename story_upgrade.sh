cd $HOME
rm -rf story
git clone https://github.com/piplabs/story
cd story
git checkout v0.10.1
go build -o story ./client
sudo systemctl stop story-testnet.service
sudo mv ~/story/story ~/go/bin/
sudo systemctl start story-testnet.service && sudo journalctl -fu story-testnet.service -o cat
