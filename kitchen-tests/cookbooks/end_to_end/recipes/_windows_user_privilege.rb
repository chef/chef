# Add a user to the system
user 'testuser'

# Update a privilege to include the new user account
windows_user_privilege 'SeNetworkLogonRight' do
  privilege 'SeNetworkLogonRight'
  users ['BUILTIN\\Administrators', 'NT AUTHORITY\\Authenticated Users', 'testuser']
  action :set
end

# Remove the added test user
user 'testuser' do
  action :remove
end

# Attempt to manage the same privilege and an exception will be raised when the resource attempts to remove `testuser` from the listing
windows_user_privilege 'SeNetworkLogonRight' do
  privilege 'SeNetworkLogonRight'
  users ['BUILTIN\\Administrators', 'NT AUTHORITY\\Authenticated Users']
  action :set
end
