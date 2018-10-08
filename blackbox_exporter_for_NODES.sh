#!/bin/bash
BLACKBOX_EXPORTER_VERSION="0.12.0"
wget https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_EXPORTER_VERSION}/blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzvf blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-amd64.tar.gz
cd blackbox_exporter-${BLACKBOX_EXPORTER_VERSION}.linux-amd64
# não se faz necessário make ./blackbox_exporter
cp blackbox_exporter /usr/local/bin

# create user
useradd --no-create-home --shell /bin/false blackbox_exporter

chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter

echo '[Unit]
Description=BlackBox Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=blackbox_exporter
Group=blackbox_exporter
Type=simple
ExecStart=/usr/local/bin/blackbox_exporter
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/blackbox_exporter.service

## Após a instalação no PROMETHEUS-SERVER inserir as configurações sobre os NODES e serviços que serão raspados ##

##NO NODE blackbox_exporter.yml##
#caso o arquivo não seja encontrado verificar se o nome é blackbox.yml
#ou se se faz necessário criar o arquivo antes touch blacbox_exporter.yml
echo "modules:
  dcs_results:
    prober: http
    timeout: 5s
    http:
      fail_if_not_matches_regexp:
      - "loginmanualunidade.php" " >> /root/blackbox_exporter-0.12.0.linux-amd64/blackbox.yml

#inserido no fim para testar o start somente após a configuração
# enable blackbox_exporter in systemctl
systemctl daemon-reload
systemctl start blackbox_exporter
systemctl enable blackbox_exporter

#FIM DA EXECUÇÃO
