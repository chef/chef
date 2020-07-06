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

macos_userdefaults "Enable macOS firewall" do
  domain "/Library/Preferences/com.apple.alf"
  key "globalstate"
  value "1"
  type "int"
end

macos_userdefaults "Set the dock size" do
  domain "com.apple.dock"
  type "integer"
  key "tilesize"
  value "20"
end

macos_userdefaults "value with space" do
  domain "/Library/Preferences/ManagedInstalls"
  key "LogFile"
  value "/Library/Managed Installs/Logs/ManagedSoftwareUpdate2.log"
end
