#!/bin/bash

set -x

SERVER_IP="$1"
SERVER_PORT=$2
FRONT_PORT=$3

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 SERVER_IP SERVER_PORT FRONT_PORT" >&2
    exit 1
fi

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 20
nvm use 20

git clone https://github.com/spring-petclinic/spring-petclinic-angular.git

cd spring-petclinic-angular/

sed -i "s/localhost/$SERVER_IP/g" src/environments/environment.ts src/environments/environment.prod.ts
sed -i "s/9966/$SERVER_PORT/g" src/environments/environment.ts src/environments/environment.prod.ts

npm install -g @angular/cli@latest
npm install

npm install angular-http-server

printf 'y' | ng build
printf 'n' | ng build

npx angular-http-server --path ./dist -p $FRONT_PORT &

echo DONE
