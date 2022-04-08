name             "end_to_end"
license          "Apache-2.0"
description      "Installs/Configures base"
version          "1.0.0"

gem              "chef-sugar"

depends          "logrotate"
depends          "multipackage"
depends          "nscd"
depends          "ntp"
depends          "openssh"
depends          "resolver"
depends          "users", "< 7.1" # 7.1 breaks macos / opensuse
depends          "git"

supports         "ubuntu"
supports         "debian"
supports         "centos"
supports         "opensuseleap"
supports         "fedora"
supports         "amazon"

chef_version     ">= 16"
issues_url       "https://github.com/chef/chef/issues"
source_url       "https://github.com/chef/chef"
