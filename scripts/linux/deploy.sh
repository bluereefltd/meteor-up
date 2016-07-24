#!/bin/bash

revert_app (){
  if [[ -d old_app ]]; then
    sudo rm -rf app
    sudo mv old_app app
    sudo stop <%= appName %> || :
    sudo start <%= appName %> || :

    echo "Latest deployment failed! Reverted back to the previous version." 1>&2
    exit 1
  else
    echo "App did not pick up! Please check app logs." 1>&2
    exit 1
  fi
}

set -e

APP_DIR=/opt/<%=appName %>

# save the last known version
echo "save the last known version"
cd $APP_DIR
if [[ -d current ]]; then
  sudo rm -rf last
  sudo mv current last
fi

# setup the new version
echo "setup the new version"
sudo mkdir current
cp tmp/bundle.tar.gz current/

# We temporarly stopped the binary building
# Instead we are building for linux 64 from locally
# That's just like what meteor do
# We can have option to turn binary building later on, 
# but not now

# # rebuild binary module
echo "rebuild binary modules"
cd current
sudo tar xzf bundle.tar.gz

cd $APP_DIR/current/bundle/programs/server
rm npm-shrinkwrap.json

if [[ -d $APP_DIR/current/bundle/programs/server/npm/node_modules/canvas ]]; then
  cd $APP_DIR/current/bundle/programs/server/npm
  sudo npm uninstall canvas
  sudo npm install canvas@1.4.0
fi

#cd $APP_DIR/current/bundle/programs/server/npm/node_modules/meteor/npm-bcrypt/node_modules
#sudo npm install bcrypt
# cd $APP_DIR/current/bundle/programs/server
# sudo npm uninstall fibers
# sudo npm install fibers
echo "stuff rebuilt"

cd $APP_DIR

# docker run \
#   --rm \
#   --volume=$APP_DIR/current/bundle/programs/server:/bundle \
#   --entrypoint="/bin/bash" \
#   meteorhacks/meteord:app -c \
#     "cd /bundle/ && node npm-rebuild.js"

cd current

sudo rm bundle.tar.gz
sudo tar czf bundle.tar.gz bundle
sudo rm -rf bundle

cd ..

# start app
sudo bash config/start.sh