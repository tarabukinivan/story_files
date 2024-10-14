# Task3: Guide to Setting Up Grafana Dashboard for Node Monitoring
Demo Preview: https://grafana.tarabukin.work/ 
## System Requirements
* Operating System: Ubuntu 20.04 LTS or newer
* RAM: Minimum 2GB
* CPU: 2 cores or more
* Disk Space: At least 20GB free

## Install node exporter
```
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xvf node_exporter-1.8.2.linux-amd64.tar.gz
cp node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin
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
wget https://github.com/prometheus/prometheus/releases/download/v3.0.0-beta.0/prometheus-3.0.0-beta.0.linux-amd64.tar.gz
tar xvf prometheus-3.0.0-beta.0.linux-amd64.tar.gz
mv prometheus-3.0.0-beta.0.linux-amd64 prometheus
chmod +x $HOME/prometheus/prometheus
rm prometheus-3.0.0-beta.0.linux-amd64.tar.gz
```
### prometeus config
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

### Reload and start node service

## Setup Prometheus config

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
```

restart prometeus

```
sudo systemctl restart  prometheusd.service
sudo systemctl status prometheusd.service
```

## Install Grafana
