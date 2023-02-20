#!/bin/sh -v

# this is temporary
echo "${EXPEDITOR_CHANNEL}"
echo "${EXPEDITOR_VERSION}"
echo "${EXPEDITOR_PRODUCT_NAME}"
echo "${EXPEDITOR_PRODUCT_KEY}"
# end temporary

#chef_client_version="{$EXPEDITOR_VERSION}"
chef_client_version="18.1.15"

mkdir stage

pushd stage

curl -O https://packages.chef.io/files/current/chef/${chef_client_version}/mac_os_x/11/chef-${chef_client_version}-1.x86_64.dmg
hdiutil attach -quiet chef-${chef_client_version}-1.x86_64.dmg
cp /Volumes/Chef\ Infra\ Client/chef-${chef_client_version}-1.x86_64.pkg ./
hdiutil detach -quiet /Volumes/Chef\ Infra\ Client
rm chef-${chef_client_version}-1.x86_64.dmg

curl -O https://packages.chef.io/files/current/chef/${chef_client_version}/mac_os_x/11/chef-${chef_client_version}-1.arm64.dmg
hdiutil attach -quiet chef-${chef_client_version}-1.arm64.dmg
cp /Volumes/Chef\ Infra\ Client/chef-${chef_client_version}-1.arm64.pkg ./
hdiutil detach -quiet /Volumes/Chef\ Infra\ Client
rm chef-${chef_client_version}-1.arm64.dmg

popd
