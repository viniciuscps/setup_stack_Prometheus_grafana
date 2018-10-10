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
sudo mkdir /etc/blackbox_exporter/

sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox_exporter
sudo touch /etc/blackbox_exporter/blackbox.yml

#Inserir em /etc/blackbox_exporter/blackbox.yml
echo 'modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      preferred_ip_protocol: "ipv4"
      valid_status_codes: []
      method: GET

  http_2xx_example:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/2.1", "HTTP/2"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
      headers:
        Host: http://localhost:8000
#        Host: avaeduc.com.br
        Accept-Language: en-US
      no_follow_redirects: false
      fail_if_ssl: false
      fail_if_not_ssl: false
      fail_if_matches_regexp:
        - "Could not connect to database"
      fail_if_not_matches_regexp:
        - "Download the latest version here"
      tls_config:
        insecure_skip_verify: false
      preferred_ip_protocol: "ip4" #defaults to "ip6"
  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
 body: '{}'
  http_basic_auth_example:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Host: avaeduc.com.br
      basic_auth:
        username: alunoteste2
        password: 123
  http_custom_ca_example:
    prober: http
    http:
      method: GET
      tls_config:
        ca_file: "/certs/my_cert.crt"
  tls_connect:
    prober: tcp
    timeout: 5s
    tcp:
      tls: true
  tcp_connect_example:
    prober: tcp
    timeout: 5s
  imap_starttls:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
        - expect: "OK.*STARTTLS"
        - send: ". STARTTLS"
        - expect: "OK"
        - starttls: true
        - send: ". capability"
 - expect: "CAPABILITY IMAP4rev1"
  smtp_starttls:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
        - expect: "^220 ([^ ]+) ESMTP (.+)$"
        - send: "EHLO prober"
        - expect: "^250-STARTTLS"
        - send: "STARTTLS"
        - expect: "^220"
        - starttls: true
        - send: "EHLO prober"
        - expect: "^250-AUTH"
        - send: "QUIT"
  irc_banner_example:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
        - send: "NICK prober"
        - send: "USER prober prober prober :prober"
        - expect: "PING :([^ ]+)"
          send: "PONG ${1}"
        - expect: "^:[^ ]+ 001"
  icmp_example:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: "ip6"
      source_ip_address: "127.0.0.1"
  dns_udp_example:
    prober: dns
    timeout: 5s
    dns:
      query_name: "www.avaeduc.com.br"
      query_type: "A"
      valid_rcodes:
      - NOERROR
      validate_answer_rrs:
        fail_if_matches_regexp:
        - ".*127.0.0.1"
        fail_if_not_matches_regexp:
        - "www.avaeduc.com.br\t300\tIN\tA\t127.0.0.1"
      validate_authority_rrs:
        fail_if_matches_regexp:
        - ".*127.0.0.1"
      validate_additional_rrs:
        fail_if_matches_regexp:
        - ".*127.0.0.1"
  dns_soa:
    prober: dns
    dns:
      query_name: "avaeduc.com.br"
      query_type: "SOA"
  dns_tcp_example:
    prober: dns
    dns:
      transport_protocol: "tcp" # defaults to "udp"
      preferred_ip_protocol: "ip4" #  defaults to "ip6"
      query_name: "www.avaeduc.com.br"' >> /etc/blackbox_exporter/blackbox.yml

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
