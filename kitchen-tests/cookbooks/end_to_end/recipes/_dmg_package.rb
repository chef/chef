#
# Cookbook:: end_to_end
# Recipe:: _dmg_package
#
# Copyright:: Copyright (c) Chef Software Inc.
#

dmg_package "LittleSecrets" do
  source   "https://www.mani.de/download/littlesecrets/LittleSecrets1.9.4.dmg"
  checksum "8281c1f648c038b296a02940126c29032ff387b90a880d63834e303e1b3a5ff7"
  action   :install
end

dmg_package "InSpec" do
  app "InSpec"
  source "https://packages.chef.io/files/stable/inspec/4.41.20/mac_os_x/11/inspec-4.41.20-1.x86_64.dmg"
  checksum "e18cecc1b5827b172a0be3f12da71746b9b731c60248577163e63498b7afb050"
  type "pkg"
  accept_eula true
  allow_untrusted true
end
