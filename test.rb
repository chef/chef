# macos_userdefaults 'Delete non-existent domain' do
#   domain '/Library/Preferences/TimTest'
#   key 'File'
#   action :delete
# end

# macos_userdefaults 'Add key to new domain' do
#   domain '/Library/Preferences/TimTest'
#   key 'File'
#   value '/usr/local/tim'
# end

# macos_userdefaults 'Add key to new domain' do
#   domain '/Library/Preferences/TimTest'
#   key 'File'
#   value '/usr/local/tim'
# end

macos_userdefaults 'Add String key' do
  domain '~/Library/Preferences/unity.BrickLink.Studio.plist'
  key 'StringKey2'
  value '/usr/local/tim2'
end

macos_userdefaults 'Add boolean key' do
  domain '~/Library/Preferences/unity.BrickLink.Studio.plist'
  key 'BooleanKey'
  value true
end

macos_userdefaults 'Add array key' do
  domain '~/Library/Preferences/unity.BrickLink.Studio.plist'
  key 'ArrayKey'
  value %w(one two three)
end


# macos_userdefaults 'enable macOS firewall' do
#   domain '/Library/Preferences/com.apple.alf'
#   key 'globalstate'
#   value '1'
#   type 'int'
# end

# macos_userdefaults 'Bad string test' do
#   domain '/Library/Preferences/ManagedInstalls'
#   key 'Log File'
#   value '/Library/Managed Installs/Logs/ManagedSoftwareUpdate.log'
# end



# Bugs:
# Create/Delete on domain that doesn't exist fails
