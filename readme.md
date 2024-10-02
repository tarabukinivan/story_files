```
source <(curl -s https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_snapshot.sh)
wget -O story_snapshot.sh https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_snapshot.sh && chmod a+x story_snapshot.sh
```
<h2>Snapshot</h2>
<p>Every 5 hours</p>
<p>Latest sanap: Info</p>
<p>Pruning	default, Indexer kv (archive)</p>
```
sudo systemctl stop story-testnet.service
cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
rm -rf $HOME/.story/story/data
cd $HOME/.story/story/
wget https://snapshots.tarabukin.work/story/iliad_latest.tar
mkdir data
tar -xvf iliad_latest.tar -C $HOME/.story/story/data
rm iliad_latest.tar
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
sudo systemctl start story-testnet.service && sudo journalctl -fu story-testnet.service -o cat
```
