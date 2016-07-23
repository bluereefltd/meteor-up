#!/bin/bash

APPNAME=<%= appName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list
PORT=<%= port %>
USE_LOCAL_MONGO=<%= useLocalMongo? "1" : "0" %>
USE_EXISTING_MONGO=<%= useExistingLocalMongo? "1" : "0" %>

# Remove previous version of the app, if exists
docker rm -f $APPNAME

# Remove frontend container if exists
docker rm -f $APPNAME-frontend

# We don't need to fail the deployment because of a docker hub downtime
set +e
docker build -t meteorhacks/meteord:app - << EOF1
FROM meteorhacks/meteord:base
RUN cat /etc/*-release
RUN sh -c "echo \
deb http://ftp.cn.debian.org/debian wheezy main '\n' \
deb-src http://ftp.cn.debian.org/debian wheezy main '\n' \
deb http://ftp.cn.debian.org/debian wheezy-updates main '\n' \
deb-src http://ftp.cn.debian.org/debian wheezy-updates main '\n' \
deb http://security.debian.org/ wheezy/updates main '\n' \
deb-src http://security.debian.org/ wheezy/updates main '\n' \
deb http://ftp.debian.org/debian sid main > /etc/apt/sources.list"
RUN cat /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y unifont
RUN apt-get install -y --fix-missing libcairo2-dev libjpeg8-dev libpango1.0-dev libgif-dev build-essential g++ libc6-dev libpng12-0 libjpeg8 libgif4
RUN npm config set registry https://registry.npm.taobao.org
RUN npm config set disturl https://npm.taobao.org/dist
RUN npm install -g node-gyp
RUN ldd --version
EOF1
set -e

if [ "$USE_EXISTING_MONGO" == "1" ]; then
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --env-file=$ENV_FILE \
    --link=mongodb:mongodb \
    --hostname="$HOSTNAME-$APPNAME" \
    --env=MONGO_URL=mongodb://mongodb:27017/meteor \
    --name=$APPNAME \
    meteorhacks/meteord:app
elif [ "$USE_LOCAL_MONGO" == "1" ]; then
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --env-file=$ENV_FILE \
    --link=mongodb:mongodb \
    --hostname="$HOSTNAME-$APPNAME" \
    --env=MONGO_URL=mongodb://mongodb:27017/$APPNAME \
    --name=$APPNAME \
    meteorhacks/meteord:app
else
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --hostname="$HOSTNAME-$APPNAME" \
    --env-file=$ENV_FILE \
    --name=$APPNAME \
    meteorhacks/meteord:app
fi

<% if(typeof sslConfig === "object")  { %>
  # We don't need to fail the deployment because of a docker hub downtime
  set +e
  docker pull meteorhacks/mup-frontend-server:latest
  set -e
  docker run \
    -d \
    --restart=always \
    --volume=/opt/$APPNAME/config/bundle.crt:/bundle.crt \
    --volume=/opt/$APPNAME/config/private.key:/private.key \
    --link=$APPNAME:backend \
    --publish=<%= sslConfig.port %>:443 \
    --name=$APPNAME-frontend \
    meteorhacks/mup-frontend-server /start.sh
<% } %>

# deb http://ftp.debian.org/debian sid main