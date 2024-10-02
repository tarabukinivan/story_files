source <(curl -s https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_snapshot.sh)
wget -O story_snapshot.sh https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_snapshot.sh && chmod a+x story_snapshot.sh

Snapshot
Every 5 hours
Pruning	default, Indexer kv (archive)

sudo systemctl stop story-testnet.service
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
rm -rf $HOME/.story/story/data
cd $HOME/.story/story/
wget https://snapshots.tarabukin.work/story/iliad_latest.tar
tar -xvf iliad_latest.tar

mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
sudo systemctl start story-testnet.service && sudo journalctl -fu story-testnet.service -o cat
