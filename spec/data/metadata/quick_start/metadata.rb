maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Example cookbook for quick_start wiki document"
version           "0.7"

%w{
  redhat fedora centos
  ubuntu debian
  macosx freebsd openbsd
  solaris
}.each do |os|
  supports os
end
