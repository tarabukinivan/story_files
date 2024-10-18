# Task3: Guide to Setting Up Grafana Dashboard for Node Monitoring
Demo Preview: https://grafana.tarabukin.work/ 
<p>Usually only Node Exporter is used on a server with a node. But in our example everything will be on one server</p>

## System Requirements
* Operating System: Ubuntu 20.04 LTS or newer
* RAM: Minimum 2GB
* CPU: 2 cores or more
* Disk Space: At least 20GB free

## Enable Promethius on the node

```
nano $HOME/.story/story/config/config.toml
```

<p>Ensure that the Prometheus endpoint is enabled:</p>

```
prometheus = true
prometheus_listen_addr = 26660
```

restart Story node  

## Install node exporter
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/bin
chmod +x /usr/local/bin/node_exporter
node_exporter --version
rm -r node_exporter-*
```

### Create service file for node exporter
```
sudo tee /etc/systemd/system/exporterd.service > /dev/null <<EOF
[Unit]
Description=node_exporter
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
```
reload and run service
```
sudo systemctl daemon-reload && \
sudo systemctl enable exporterd && \
sudo systemctl restart exporterd && sudo journalctl -u exporterd -f
```

check if there are metrics
```
curl 'localhost:9100/metrics'
```
or output the exporter address and check it in the browser
```
echo -e "\033[0;32mhttp://$(wget -qO- eth0.me):9100/metrics\033[0m"
```
![exporter metrics](https://raw.githubusercontent.com/tarabukinivan/story_files/47bb4ce202711cc164004c48f970541d83a543ca/images/exporter_metrics.jpg)

## Install Prometheus
```
cd $HOME
wget https://github.com/prometheus/prometheus/releases/download/v3.0.0-beta.0/prometheus-3.0.0-beta.0.linux-amd64.tar.gz
tar xvf prometheus-3.0.0-beta.0.linux-amd64.tar.gz
mv prometheus-3.0.0-beta.0.linux-amd64 prometheus
chmod +x $HOME/prometheus/prometheus
rm prometheus-3.0.0-beta.0.linux-amd64.tar.gz
```
### Prometheus config
in tagrets add ip address and port from exporter metrics
```
nano $HOME/prometheus/prometheus.yml
```
![prometeus config](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/prometeusconfig.png)

### Create service file for Prometheus
```
sudo tee /etc/systemd/system/prometheusd.service > /dev/null <<EOF
[Unit]
Description=prometheus
After=network-online.target
[Service]
User=$USER
ExecStart=$HOME/prometheus/prometheus \
--config.file="$HOME/prometheus/prometheus.yml"
Restart=always
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
```
### Reload and start Prometheus
```
sudo systemctl daemon-reload && \
sudo systemctl enable prometheusd && \
sudo systemctl restart prometheusd && sudo journalctl -u prometheusd -f
```
### open prometheus page
```
echo -e "\033[0;32mhttp://$(wget -qO- eth0.me):9090\033[0m"
```
![prometeus page](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/prometeus_page.png)

### Let's check if the metrics are loading?
```
Status > Target health
```
![prometeus targets](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/prometius_targets.png)

## Install pushgateway
```
wget https://github.com/prometheus/pushgateway/releases/download/v1.10.0/pushgateway-1.10.0.linux-amd64.tar.gz
tar zxvf pushgateway-*.tar.gz
cp pushgateway-*/pushgateway /usr/local/bin/
useradd --no-create-home --shell /bin/false pushgateway
chown pushgateway:pushgateway /usr/local/bin/pushgateway
```
### Create pushgateway service
```
sudo tee /etc/systemd/system/pushgateway.service > /dev/null <<EOF
[Unit]
Description=Pushgateway Service
After=network.target

[Service]
User=pushgateway
Group=pushgateway
Type=simple
ExecStart=/usr/local/bin/pushgateway \
    --web.listen-address=":9091" \
    --web.telemetry-path="/metrics" \
    --persistence.file="/tmp/metric.store" \
    --persistence.interval=5m \
    --log.level="info" \
    --log.format="json"
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```
### Starting pushgateway
```
systemctl daemon-reload
systemctl enable pushgateway --now
systemctl status pushgateway
```

## let's add our own metrics for the story node
Install dependenses
```
sudo apt-get install python3-pip
pip install prometheus_client
pip install requests
```
download exporter
```
wget -O $HOME/prometheus/story_exporter.py "https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_exporter.py"
```
<p>let's set this up</p>
<p>You need to run your Valoper and RPC from the node.</p>

![valoperrpc](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/ValoperRpc.png)

### let's make a service for it 
```
sudo tee /etc/systemd/system/storyexporter.service > /dev/null <<EOF
[Unit]
Description=Storyb Exporter
After=network-online.target
[Service]
User=$USER
ExecStart=/usr/bin/python3 $HOME/prometheus/story_exporter.py
WorkingDirectory=$HOME/prometheus/
Restart=Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
```
### launch
```
sudo systemctl daemon-reload && \
sudo systemctl enable storyexporter.service && \
sudo systemctl restart storyexporter.service && sudo journalctl -u storyexporter.service -f
```
### Let's change the settings of Prometheus
```
nano $HOME/prometheus/prometheus.yml
```

section scrape_configs change:

```
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "story"
    scrape_interval: 5s
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090","localhost:9100"]

  - job_name: 'block_height_exporter'
    scrape_interval: 1s
    static_configs:
      - targets: ['localhost:8008']

  - job_name: 'pushgateway'
    honor_labels: true
    static_configs:
      - targets: ['localhost:9091']

  - job_name: "storynode"
    static_configs:
      - targets: ["<your-ip>:26660"]
```

restart all services

```
sudo systemctl restart  prometheusd.service
sudo systemctl status prometheusd.service
sudo systemctl status pushgateway
sudo systemctl restart storyexporter.service
sudo systemctl restart exporterd && sudo journalctl -u exporterd -f
```
and check pushgateway
```
echo -e "\033[0;32mhttp://$(wget -qO- eth0.me):9091\033[0m"
```
![pushgateway](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/pushgatewaymetrics.png)

## Install Grafana
```
sudo apt-get install -y adduser libfontconfig1 musl
wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.2.2_amd64.deb
sudo dpkg -i grafana-enterprise_11.2.2_amd64.deb
```
launch grafana
```
sudo systemctl daemon-reload && \
sudo systemctl enable grafana-server && \
sudo systemctl restart grafana-server && sudo journalctl -u grafana-server -f
```

### open grafana page
```
echo -e "\033[0;32mhttp://$(wget -qO- eth0.me):3000\033[0m"
```
username: admin <br>
password: admin <br>

<p>Grafana will ask you to enter a password. Come up with any password.</p>

### download the dashboard json file from the link
https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/story_dashboard.json

### Click Dashboards
![dashboard](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/dashboards.png)

<p>New > Import</p>
select the downloaded dashboard and press 'Import'

### Add Data Source
Connection > Data sources > Add data source
<p>We select prometheus and specify the address of our prometheus</p>

![datasource add](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/grafanadatasource.png)

<p>Save. It should turn out succes</p>

![succes](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/successdashboard.png)

## Let's open our dashboard. Voila.

![grafana](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/grafana.png)

## Alert Manager

```
wget -O $HOME/prometheus/rules.yml https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/rules.yml

nano $HOME/prometheus/prometheus.yml
```
Adding lines

```
rule_files:
  - 'rules.yml'

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - localhost:9093
```

<p>We check the created rules. The output should be #SUCCESS</p>

```
$HOME/prometheus/promtool check rules $HOME/prometheus/rules.yml
```

And restart prometeus

```
systemctl restart prometheusd && systemctl status prometheusd
```

### Install binaries

```
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar -zxf alertmanager-0.26.0.linux-amd64.tar.gz

cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/

cp alertmanager-0.26.0.linux-amd64/alertmanager.yml $HOME/prometheus

chmod +x $HOME/prometheus/alertmanager.yml
chmod +x $HOME/prometheus/rules.yml

chmod +x /usr/local/bin/alertmanager
chmod +x /usr/local/bin/amtool
```

Delete unnecessary files

```
cd
rm -r alertmanager-*
```

Setting up alertmanager.yml

```
nano $HOME/prometheus/alertmanager.yml
```

Insert your CHAT_ID and BOT_TOKEN

```
global:
  resolve_timeout: 10s

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 15s
  repeat_interval: 60m
  receiver: 'telegram_bot'

receivers:
- name: 'telegram_bot'
  telegram_configs:
  - bot_token: 'BOT_TOKEN'
    api_url: 'https://api.telegram.org'
    chat_id: CHAT_ID
    parse_mode: ''
```

### Create service for alertmanager

```
tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=alertmanager
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/alertmanager --config.file=$HOME/prometheus/alertmanager.yml --log.level=debug

[Install]
WantedBy=multi-user.target
EOF
```

Run

```
systemctl daemon-reload
systemctl enable alertmanager
systemctl restart alertmanager && systemctl status alertmanager
journalctl -u alertmanager -f -o cat
```

Check the status alert manager in the browser

```
echo -e "\033[0;32mhttp://$(wget -qO- eth0.me):9093/\033[0m"
```

<p>If alerts have worked for Grafana, you can see them in Alerting -> Alert rules </p>

![alertGrafana](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/grafanaalert1.png)

<p>And if you filled in BOT_TOKEN and CHAT_ID correctly, the messages will come to Telegram</p>

![alertTg](https://raw.githubusercontent.com/tarabukinivan/story_files/refs/heads/main/images/alerttg.png)
