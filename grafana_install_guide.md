# Task3: Guide to Setting Up Grafana Dashboard for Node Monitoring
Demo Preview: https://grafana.tarabukin.work/ 
## System Requirements
* Operating System: Ubuntu 20.04 LTS or newer
* RAM: Minimum 2GB
* CPU: 2 cores or more
* Disk Space: At least 20GB free

## Install Prometheus

### Create service file for Prometheus

### Reload and start Prometheus

## Install node exporter

### Create service file for node exporter

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
