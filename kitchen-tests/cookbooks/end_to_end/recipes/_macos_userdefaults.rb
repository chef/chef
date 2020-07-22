#
# Cookbook:: end_to_end
# Recipe:: _macos_userdefaults
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# test that we can autodetect the type
mac_os_x_userdefaults "Disable fast user switching" do
  domain "/Library/Preferences/.GlobalPreferences"
  key "MultipleSessionEnabled"
  value 0
end

# test full path to the domain
macos_userdefaults "Enable macOS firewall" do
  domain "/Library/Preferences/com.apple.alf"
  key "globalstate"
  value "1"
  type "int"
end

# test short domain name
macos_userdefaults "Set the dock size" do
  domain "com.apple.dock"
  type "int"
  key "tilesize"
  value "20"
end

# test that we can properly handle spaces
macos_userdefaults "Value with space" do
  domain "/Library/Preferences/ManagedInstalls"
  type "string"
  key "LogFile"
  value "/Library/Managed Installs/Logs/ManagedSoftwareUpdate2.log"
end

# test that we can set an array
macos_userdefaults "Bogus key with array value" do
  domain "/Library/Preferences/ManagedInstalls"
  type "array"
  key "LogFileArray"
  value [ "/Library/Managed Installs/fake.log", "/Library/Managed Installs/also_fake.log"]
end

# test that we can set a dict
macos_userdefaults "Bogus key with dict value" do
  domain "/Library/Preferences/ManagedInstalls"
  type "dict"
  key "LogFileDict"
  value "User": "/Library/Managed Installs/way_fake.log"
end

# test that we can set a bool
macos_userdefaults "Bogus key with boolean value" do
  domain "/Library/Preferences/ManagedInstalls"
  key "LoggingIsTheThingToDoRight"
  value "yes"
  type "bool"
end

# test that we can handle the 2nd client run with :delete
macos_userdefaults "bogus key" do
  domain "/Library/Preferences/com.apple.alf"
  key "GlobalStateNope"
  action :delete
end

# try to delete a key we known is there
macos_userdefaults "delete a key" do
  domain "/Library/Preferences/ManagedInstalls"
  key "LoggingIsTheThingToDoRight"
  action :delete
end
