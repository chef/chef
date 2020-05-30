#
# Cookbook:: end_to_end
# Recipe:: _dmg_package
#
# Copyright:: Copyright (c) Chef Software Inc.
#

dmg_package "Tunnelblick" do
  source   "https://tunnelblick.net/release/Tunnelblick_3.8.2a_build_5481.dmg"
  checksum "3857f395f2c0026943bc76d46cb8bb97f5655e9ea0d9a8d2bdca1e5d82a7325b"
  action   :install
end

dmg_package "virtualbox" do
  app "virtualbox"
  source "http://download.virtualbox.org/virtualbox/6.1.8/VirtualBox-6.1.8-137981-OSX.dmg"
  checksum "569e91eb3c7cb002d407b236a7aa71ac610cf2ad1afa03730dab11fbd4b89e7c"
  type "pkg"
  accept_eula true
  allow_untrusted true
end
