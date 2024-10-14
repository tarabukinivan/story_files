from prometheus_client import start_http_server, Gauge
import requests
import time
import subprocess
import json

#enter your rpc and valoper.
#Note: It is advisable to use python-dotenv
#your valoper
valoper = "storyvaloper1x9c7xr8x4du2e926cgztthaq8cydnvcvvypesa"
#your rpc
myrpc = "https://story-rpc.tarabukin.work"
#story api
apistory = "https://api.testnet.storyscan.app"

# metrics
latest_block_height = Gauge('latest_block_height', 'Latest block height of the node')
feature_enabled = Gauge('feature_enabled', 'Indicates synchronization')
tend_peers = Gauge('tend_peers', 'Tendermint peers')
eth_peers = Gauge('eth_peers', 'Geth peers')
active_validators = Gauge('active_validators', 'Number of active validators', ['story_network', 'story_alias'])
total_validators = Gauge('total_validators', 'Total number of validators', ['valoper'])

api_height = Gauge('api_height', 'Api height')

validatorinfo = f"{apistory}/validators/{valoper}"
urldelegators = f"{validatorinfo}/delegations"
netinfostory = f"{apistory}/chain/network"

pushgateway_url = 'http://localhost:9091/metrics/job/pushgateway'
geth_sync_info = Gauge('geth_sync_info', 'Indicates synchronization Geth')
bash_geth_peers = "geth --exec 'admin.peers' attach ~/.story/geth/iliad/geth.ipc"
bash_synceth = "geth --exec 'eth.syncing' attach ~/.story/geth/iliad/geth.ipc"

def fetch_and_export_height():
    while True:
        try:
            # curl query
            response = requests.get(f"{myrpc}/status")
            netinfo = requests.get(f"{myrpc}/net_info")
            data = response.json()
            netinfoj = netinfo.json()
            
            block_height = int(data["result"]["sync_info"]["latest_block_height"])
            print(f"block height: {block_height}")
            tenderm_peers = int(netinfoj["result"]["n_peers"])            
            syncinfo = data["result"]["sync_info"]["catching_up"]
            try:
                syncinfogeth = subprocess.check_output(bash_synceth, shell=True, text=True)
                syncinfogeth = syncinfogeth.strip()
                gethpeersinfo = subprocess.check_output(bash_geth_peers, shell=True, text=True)
                gethpeersinfo = gethpeersinfo.strip()
                enode_count = gethpeersinfo.count('enode: "enode')
                enode_count = int(enode_count)
            except subprocess.CalledProcessError as e:
                # error
                print(f"Ошибка выполнения команды: {e}")
            
            latest_block_height.set(block_height)
            # 1 if true, 0 if false
            feature_enabled.set(1 if syncinfo else 0)
            geth_sync_info.set(1 if syncinfogeth.lower() == "true" else 0)
            tend_peers.set(tenderm_peers)
            eth_peers.set(enode_count)
            
            sync_status = "true" if syncinfo else "false"
            
            
            try:
                
                response = requests.get(urldelegators)
                responsevalinfo = requests.get(validatorinfo)
                resnetinfo = requests.get(netinfostory)
                
                # 
                response.raise_for_status()
                responsevalinfo.raise_for_status()
                
                # 
                data = response.json()
                netinfdata = resnetinfo.json()
                
                #network                
                story_network = netinfdata['network']
                
                #alias                
                story_alias = netinfdata['token']['alias']
                
                api_height.set(int(netinfdata['latestBlock']['height']))
                
                active_validators.labels(story_network, story_alias).set(int(netinfdata['validators']['active']))
                total_validators.labels(valoper).set(int(netinfdata['validators']['total']))
                
                datavalinfo = responsevalinfo.json()
                
                push_data = ""
                for item in data['items']:
                    address = item['delegator']['address']
                    amount = float(item['amount'])
                    push_data += f"delegator_amount{{address=\"{address}\"}} {amount}\n"
                

                valinfo_data = f"""
delegator_tokens{{accountAddress="{datavalinfo['accountAddress']}", moniker="{datavalinfo['moniker']}"}} {datavalinfo['tokens']}
tombstoned{{accountAddress="{datavalinfo['accountAddress']}"}} {1 if datavalinfo['signingInfo']['tombstoned'] else 0}
jailed{{accountAddress="{datavalinfo['accountAddress']}"}} {0 if datavalinfo['jailed'] is None else 1}
"""
                    
                print(push_data)
                print(valinfo_data)
                response = requests.post(pushgateway_url, data=push_data)
                if response.status_code == 202:
                    print("Data successfully pushed to Prometheus Pushgateway.")
                else:
                    print("Status to push data:", response.status_code, response.text)
                
                response = requests.post(pushgateway_url, data=valinfo_data)
                if response.status_code == 202:
                    print("Data successfully pushed to Prometheus Pushgateway.")
                else:
                    print("Status to push data:", response.status_code, response.text)
                
            except requests.exceptions.HTTPError as err:
                print(f"HTTP error occurred: {err}")
            except Exception as err:
                print(f"An error occurred: {err}")
                        
        except Exception as e:
            print(f"Error fetching block height: {e}")
        # updatetime
        time.sleep(3)

if __name__ == '__main__':
    # http server:
    start_http_server(8008)
    fetch_and_export_height()
