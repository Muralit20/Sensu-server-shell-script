#!/bin/bash
printf "installing rabbitmq and redis server \n\n"
apt-get update
apt-get install rabbitmq-server redis-server -y
printf "enabling rabbitmq_management plugin \n\n"
service rabbitmq-server restart
printf "adding rabbitmq virtual host username: sensu pwd: secret \n\n"
rabbitmqctl add_vhost /sensu
rabbitmqctl add_user sensu secret
rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

#get the gpg key
printf "now adding sensu repo \n\n"
wget -q https://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -
CODENAME=$(lsb_release -cd | grep Codename | cut -d ":" -f2)
echo "deb https://sensu.global.ssl.fastly.net/apt $CODENAME main" | sudo tee /etc/apt/sources.list.d/sensu.list

#update repo and install sensu
apt-get update
printf "installing sensu server, client and api \n\n"
apt-get install sensu -y
printf "adding config.json file with rabbitmq, redis and api settings \n\n"
cat <<EOT > /etc/sensu/config.json
{
        "rabbitmq": {
          "host": "localhost",
          "vhost": "/sensu",
          "user": "sensu",
          "password": "secret"
        },
        "redis": {
          "host": "localhost"
        },
        "api": {
          "host": "localhost",
      "port": 4567
        }
}
EOT
printf "adding client \n\n"
ip=$(ip route get 1 | awk '{print $NF;exit}')
hostname=$(hostname -f)
cat <<EOT > /etc/sensu/conf.d/client.json
{
        "client": {
                "name": "$hostname",
                "address": "$ip"
        }
}
EOT

printf "starting sensu server, client and api"

if [[ $CODENAME == "xenial" ]]; then
        service sensu-server start
        service sensu-client start
        service sensu-api start
else
        /etc/init.d/sensu-server start
        /etc/init.d/sensu-client start
        /etc/init.d/sensu-api start
fi


#install uchiwa web interface
apt-get -y install uchiwa
cat <<EOT > /etc/sensu/uchiwa.json
{
  "sensu": [
    {
      "name": "SensuServer",
      "host": "localhost",
      "port": 4567,
      "ssl": false,
      "path": "",
      "user": "sensu",
      "pass": "secret",
      "timeout": 5
    }
  ],
  "uchiwa": {
    "host": "0.0.0.0",
    "port": 7000,
    "user": "sensu",
    "password": "secret",
    "interval": 5
  }
}

EOT
printf "starting Uchiwa web interface on port 7000"
#loging to http://localhost:7000 with user sensu and password secret

if [[ $CODENAME == "xenial" ]]; then
        service uchiwa start
else
        /etc/init.d/uchiwa start
fi
