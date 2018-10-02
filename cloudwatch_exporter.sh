#!/bin/bash
#create configuration directory
sudo mkdir -p /home/prometheus/cloudwatchexporter
sudo touch /home/prometheus/cloudwatchexporter/cloudwatchexporter.yml

#install Wget (caso o Linux não o possua instalado)
sudo yum install -y wget

#ALTERAÇÃO caminho de instalação do cloudwatch_exporter.jar
CLOUDWATCH_EXPORTER_VERSION="0.4"
sudo wget -O /home/prometheus/cloudwatchexporter/cloudwatch_exporter.jar http://search.maven.org/remotecontent?filepath=io/prometheus/cloudwatch/cloudwatch_exporter/${CLOUDWATCH_EXPORTER_VERSION}/cloudwatch_exporter-${CLOUDWATCH_EXPORTER_VERSION}-jar-with-dependencies.jar

#install java
#-y adicionado para evitar o prompt
sudo yum install -y java-1.8.0
sudo yum install -y java-1.8.0-openjdk-devel

#ainda é necessário pressionar ENTER 2x para confirmar estas alterações
sudo /usr/sbin/alternatives --config java 
sudo /usr/sbin/alternatives --config javac

#cria a pasta e o arquivo com as credenciais para serem inseridas na step abaixo
sudo cd ~
sudo mkdir -p ~/.aws
sudo touch ~/.aws/credentials

#concede as permissões na pasta
sudo chown -R prometheus ~/.aws/

#aws credential template
echo '[default]
aws_access_key_id=Colocar a senha aqui
aws_secret_access_key=Colocar o secret aqui' >> ~/.aws/credentials

#concede as permissões
sudo chown -R ec2-user /home/prometheus

########################################################################################################################
#Este trecho deve ser inserido no caminho/arquivo seguinte: /etc/systemd/system/cloudwatch_exporter.service
echo '[Unit]
Description=Cloudwatch Exporter
Wants=network-online.target
After=network-online.target
[Service]
User=root
Group=root
Type=simple
ExecStart=/usr/bin/java -jar /home/prometheus/cloudwatchexporter/cloudwatch_exporter.jar 9106 /home/prometheus/cloudwatchexporter/cloudwatchexporter.yml
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/cloudwatch_exporter.service

# enable node_exporter in systemctl
sudo systemctl daemon-reload
sudo systemctl enable cloudwatch_exporter
#FIM DO TRECHO
########################################################################################################################

# inserir item abaixo no /home/prometheus/cloudwatchexporter/cloudwatchexporter.yml
# conceder a permissão
sudo chown -R ec2-user /home/prometheus/cloudwatchexporter

sudo echo '---
region: eu-west-1
metrics:
- aws_namespace: AWS/ELB
  aws_metric_name: HealthyHostCount
  aws_dimensions: [AvailabilityZone, LoadBalancerName]
  aws_statistics: [Average]
' >> /home/prometheus/cloudwatchexporter/cloudwatchexporter.yml

sudo systemctl start cloudwatch_exporter

#inserindo dentro do /home/prometheus/prometheus-2.2.1.linux-amd64/prometheus.yml
#concedendo a permissão
sudo chown -R ec2-user /home/prometheus/prometheus-2.2.1.linux-amd64/

sudo echo "
  - job_name: 'cloudwatch_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9106']" >> /home/prometheus/prometheus-2.2.1.linux-amd64/prometheus.yml

#Se faz necessário recarregar as configurações do Prometheus então:
#ps aux | grep prometheus
#sudo kill -HUP numerodoprocesso_prometheus

##MUITO IMPORTANTE##
##MUITO IMPORTANTE##
##MUITO IMPORTANTE##
##CONCEDER PERMISSÃO AO USUÁRIO PROMETHEUS PARA EXECUTAR E LER OS ARQUIVOS##
sudo chown -R prometheus ~/.aws/
sudo chown -R prometheus /home/prometheus/
