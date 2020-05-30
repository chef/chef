#
# Cookbook:: end_to_end
# Recipe:: _macos_userdefaults
#
# Copyright:: Copyright (c) Chef Software Inc.
#

mac_os_x_userdefaults "Disable fast user switching" do
  domain "/Library/Preferences/.GlobalPreferences"
  key "MultipleSessionEnabled"
  value 0
end

macos_userdefaults "enable macOS firewall" do
  domain "/Library/Preferences/com.apple.alf"
  key "globalstate"
  value "1"
  type "int"
end

macos_userdefaults "set dock size" do
  domain "com.apple.dock"
  type "integer"
  key "tilesize"
  value "20"
end

macos_userdefaults "disable time machine normal schedule" do
  domain "/System/Library/LaunchDaemons/com.apple.backupd-auto"
  key "Disabled"
  value "TRUE"
  sudo true
end
