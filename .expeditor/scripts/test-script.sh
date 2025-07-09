#!/bin/bash

set -euo pipefail

sudo ./.expeditor/scripts/install-hab.sh x86_64-linux
echo "--- Building Habitat package"
export HAB_ORIGIN=chef
export HAB_LICENSE="accept-no-persist"
export HAB_NONINTERACTIVE="true"
export HAB_BLDR_CHANNEL="LTS-2024"
export CHEF_LICENSE="accept-no-persist"
hab origin key generate
DO_CHECK=true hab pkg build . --refresh-channel LTS-2024
ls -la results/
source results/last_build.env
echo "--- Installing $pkg_ident"
sudo -E hab pkg install results/${pkg_artifact}

# installed crontab on the system
# sudo yum install cronie -y
# sudo systemctl enable crond.service
# sudo systemctl start crond.service

sudo -E ./habitat/tests/test.sh $pkg_ident
