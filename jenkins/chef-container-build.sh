#!/bin/sh

# Expected Inputs
#   $1 - the path to the Dockerfile context folder for this OS (i.e. chef-container/ubuntu_12.04)

##
# Prebuild Steps

# Blow away the /opt/chef directory
sudo rm -rf /opt/chef
sudo mkdir -p /opt/chef
sudo chown -R jenkins-node /opt/chef 

if [ "$RELEASE_BUILD" == "true" ]; then
  bundle exec omnibus build $OMNIBUS_PROJECT_NAME -l debug --no-timestamp
else
  bundle exec omnibus build $OMNIBUS_PROJECT_NAME -l debug
end

##
# Generate the Dockerfile

# get name of project (directory name) 
IMAGE_PATH=$1
IMAGE_NAME=basename $1

# copy package into project directory
cp pkg/*.deb $IMAGE_PATH/chef-container.deb

# build the docker image
docker build -t $IMAGE_NAME $1
