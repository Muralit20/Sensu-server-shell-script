#!/bin/bash

#Adding the sensu repositories

wget -q http://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -
echo "deb http://sensu.global.ssl.fastly.net/apt xenial main" | sudo tee /etc/apt/sources.list.d/sensu.list

#installing sensu

sudo apt-get  -y update

sudo apt-get -y install sensu

sudo chmod 775 /etc/sensu/ -R

sudo chown sensu:ubuntu /etc/sensu/ -R


#sudo yum update && sudo yum install -y sudo python-pip jq && sudo pip install -U pip

host=$(hostname -f)
#localip=$(wget http://ipecho.net/plain -O - -q ; echo)

#host=$(aws ec2 describe-tags  --region $(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}') --filters "Name=resource-id,Values=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" "Name=key,Values=Name" | jq ".Tags[0].Value" ) &&  host=$(echo "${host//'"'}")

localip=$(hostname -I | awk '{print $1}')

cat <<EOF> /etc/sensu/conf.d/client.json
{
  "client": {
    "name": "$host",
    "address": "$localip",
     "keepalive":
    {
      "handler": "mailer",
        "thresholds": {
        "warning": 250,
        "critical": 300
      }
    },
    "subscriptions": ["Linux"]
  }
}
EOF


# creating the new file for config.json

touch /etc/sensu/config.json

#copying the config.json content

echo '{
  "rabbitmq": {
    "host": "1.2.3.4",
    "vhost": "/sensu",
    "user": "sensu",
	"port": 5676,
    "password": "secret"
  }
}' | sudo tee /etc/sensu/config.json


cd /opt/sensu/embedded/bin

sudo sensu-install -p cpu-checks

sudo sensu-install -p disk-checks

sudo sensu-install -p memory-checks

sudo sensu-install -p process-checks

sudo sensu-install -p load-checks

sudo sensu-install -p uptime-checks

sudo sensu-install -p vmstats

sudo cp metrics-* /etc/sensu/plugins/

sudo cp check-* /etc/sensu/plugins/


#chkconfig sensu-client on

sudo service sensu-client restart
