#!/bin/sh -v

echo "${EXPEDITOR_CHANNEL}"
echo "${EXPEDITOR_VERSION}"
echo "${EXPEDITOR_PRODUCT_NAME}"
echo "${EXPEDITOR_PRODUCT_KEY}"

mkdir -p ./stage/pkg/tmp/chef-pkgs
mkdir -p ./stage/script

pushd ./stage/pkg/tmp/chef-pkgs

curl -O https://packages.chef.io/files/current/chef/18.0.92/mac_os_x/11/chef-18.0.92-1.x86_64.dmg
hdiutil attach -quiet chef-18.0.92-1.x86_64.dmg
cp /Volumes/Chef\ Infra\ Client/chef-18.0.92-1.x86_64.pkg ./
hdiutil detach -quiet /Volumes/Chef\ Infra\ Client
rm chef-18.0.92-1.x86_64.dmg

curl -O https://packages.chef.io/files/current/chef/18.0.92/mac_os_x/11/chef-18.0.92-1.arm64.dmg
hdiutil attach -quiet chef-18.0.92-1.arm64.dmg
cp /Volumes/Chef\ Infra\ Client/chef-18.0.92-1.arm64.pkg ./
hdiutil detach -quiet /Volumes/Chef\ Infra\ Client
rm chef-18.0.92-1.arm64.dmg

popd

cat << EOF > ./stage/script/postinstall 
#!/bin/sh
if [ `uname -m` == 'x86_64' ]
then
  installer -pkg /tmp/chef-pkgs/chef-18.0.92-1.x86_64.pkg -target LocalSystem -verbose
elif [ `uname -m` == 'arm64' ]
then
  installer -pkg /tmp/chef-pkgs/chef-18.0.92-1.arm64.pkg -target LocalSystem -verbose
fi
EOF

chmod +x ./stage/script/postinstall

pkgbuild --root stage/pkg --scripts stage/script --identifier "io.chef.infra-client.wrapper" \
 --version "18.0.92" --install-location / --sign "Chef Software, Inc. (EU3VF8YLX2)" \
 stage/pkg/chef-18.0.92-1.universal.pkg
