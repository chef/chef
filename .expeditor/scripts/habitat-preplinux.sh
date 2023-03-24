 #!/usr/bin/env bash

 export EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64LINUX="chef/chef-infra-client/18.2.0/20230323102446"
 sudo ./.expeditor/scripts/install-hab.sh x86_64-linux
 echo "--- Installing $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64LINUX"
 sudo hab pkg install $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64LINUX
 sudo ./habitat/tests/test.sh $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64LINUX
 