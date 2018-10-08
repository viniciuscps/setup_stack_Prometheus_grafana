
#!/bin/bash
# create user
useradd --no-create-home --shell /bin/false blackbox_exporter
BLACKBOX_EXPORTER_VERSION="0.12.0"
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_EXPORTER_VERSION}/blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzvf blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv ./blackbox_exporter-0.12.0.linux-amd64/blackbox_exporter /usr/local/bin
sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter
rm -rf ~/blackbox_exporter-0.12.0.linux-amd64.tar.gz ~/blackbox_exporter-0.12.0.linux-amd64

#create a dir 
sudo mkdir /etc/blackbox_exporter

sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox_exporter
sudo touch /etc/blackbox_exporter/blackbox.yml

#Inserir em /etc/blackbox_exporter/blackbox.yml
echo "modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:      
      valid_status_codes: []
      method: GET" >> /etc/blackbox_exporter/blackbox.yml

sudo chown blackbox_exporter:blackbox_exporter /etc/blackbox_exporter/blackbox.yml

############################################
#Criar o serviço blackbox_exporter.service #

echo '[Unit]
Description=Blackbox Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=blackbox_exporter
Group=blackbox_exporter
Type=simple
ExecStart=/usr/local/bin/blackbox_exporter --config.file /etc/blackbox_exporter/blackbox.yml
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/blackbox_exporter.service


systemctl daemon-reload
systemctl start blackbox_exporter
systemctl enable blackbox_exporter
systemctl status blackbox_exporter

###################################################
## INSERIR NO PROMETHEUS-SERVER (prometheus.yml) ##
###################################################

"sudo vi /etc/prometheus/prometheus.yml
 - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://localhost:8080
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115"


###################FIM###################
