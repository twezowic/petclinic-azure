#!/bin/bash

NGINX_PORT=$1
SERVER_ADDRESS=$2
shift
shift
BACKEND_PORTS=("$@")

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y nginx

cd ~/

cat >loadbalancer.conf <<EOL
upstream backend {
EOL

for PORT in "${BACKEND_PORTS[@]}"; do
    echo "    server $SERVER_ADDRESS:$PORT;"
done >> loadbalancer.conf

cat >>loadbalancer.conf <<EOL
}
server {
    listen      $NGINX_PORT;

    location /petclinic/api {
        proxy_pass http://backend;
    }
}
EOL

sudo mv loadbalancer.conf /etc/nginx/conf.d/loadbalancer.conf

sudo nginx -s reload
