#
# Cookbook:: end_to_end
# Recipe:: _dmg_package
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

dmg_package "LittleSecrets" do
  source   "https://www.mani.de/download/littlesecrets/LittleSecrets1.9.4.dmg"
  checksum "8281c1f648c038b296a02940126c29032ff387b90a880d63834e303e1b3a5ff7"
  action   :install
end

# dmg_package "virtualbox" do
#   app "virtualbox"
#   source "http://download.virtualbox.org/virtualbox/6.1.8/VirtualBox-6.1.8-137981-OSX.dmg"
#   checksum "569e91eb3c7cb002d407b236a7aa71ac610cf2ad1afa03730dab11fbd4b89e7c"
#   type "pkg"
#   accept_eula true
#   allow_untrusted true
# end
