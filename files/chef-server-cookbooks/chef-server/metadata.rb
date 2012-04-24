maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs and configures Chef Server from Omnibus"
long_description       "Installs and configures Chef Server from Omnibus"
version           "0.1.0"
recipe            "chef-server", "Configures the Chef Server from Omnibus"

%w{ ubuntu debian redhat centos }.each do |os|
  supports os
end
