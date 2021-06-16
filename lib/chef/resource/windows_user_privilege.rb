#
# Author:: Jared Kauppila (<jared@kauppi.la>)
# Author:: Vasundhara Jagdale(<vasundhara.jagdale@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../resource"

class Chef
  class Resource
    class WindowsUserPrivilege < Chef::Resource
      unified_mode true

      provides :windows_user_privilege
      description "The windows_user_privilege resource allows to add and set principal (User/Group) to the specified privilege.\n Ref: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment"

      introduced "16.0"

      examples <<~DOC
      **Set the SeNetworkLogonRight Privilege for the Builtin Administrators Group and Authenticated Users**:

      ```ruby
      windows_user_privilege 'Network Logon Rights' do
        privilege      'SeNetworkLogonRight'
        users          ['BUILTIN\\Administrators', 'NT AUTHORITY\\Authenticated Users']
        action         :set
      end
      ```

      **Add the SeDenyRemoteInteractiveLogonRight Privilege to the Builtin Guests and Local Accounts User Groups**:

      ```ruby
      windows_user_privilege 'Remote interactive logon' do
        privilege      'SeDenyRemoteInteractiveLogonRight'
        users          ['Builtin\\Guests', 'NT AUTHORITY\\Local Account']
        action         :add
      end
      ```

      **Provide only the Builtin Guests and Administrator Groups with the SeCreatePageFile Privilege**:

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        users          ['BUILTIN\\Guests', 'BUILTIN\\Administrators']
        action         :set
      end
      ```

      **Remove the SeCreatePageFile Privilege from the Builtin Guests Group**:

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        users          ['BUILTIN\\Guests']
        action         :remove
      end
      ```

      **Clear all users from the SeDenyNetworkLogonRight Privilege**:

      ```ruby
      windows_user_privilege 'Allow any user the Network Logon right' do
        privilege      'SeDenyNetworkLogonRight'
        action         :clear
      end
      ```
      DOC

      PRIVILEGE_OPTS = %w{ SeAssignPrimaryTokenPrivilege
                           SeAuditPrivilege
                           SeBackupPrivilege
                           SeBatchLogonRight
                           SeChangeNotifyPrivilege
                           SeCreateGlobalPrivilege
                           SeCreatePagefilePrivilege
                           SeCreatePermanentPrivilege
                           SeCreateSymbolicLinkPrivilege
                           SeCreateTokenPrivilege
                           SeDebugPrivilege
                           SeDenyBatchLogonRight
                           SeDenyInteractiveLogonRight
                           SeDenyNetworkLogonRight
                           SeDenyRemoteInteractiveLogonRight
                           SeDenyServiceLogonRight
                           SeEnableDelegationPrivilege
                           SeImpersonatePrivilege
                           SeIncreaseBasePriorityPrivilege
                           SeIncreaseQuotaPrivilege
                           SeIncreaseWorkingSetPrivilege
                           SeInteractiveLogonRight
                           SeLoadDriverPrivilege
                           SeLockMemoryPrivilege
                           SeMachineAccountPrivilege
                           SeManageVolumePrivilege
                           SeNetworkLogonRight
                           SeProfileSingleProcessPrivilege
                           SeRelabelPrivilege
                           SeRemoteInteractiveLogonRight
                           SeRemoteShutdownPrivilege
                           SeRestorePrivilege
                           SeSecurityPrivilege
                           SeServiceLogonRight
                           SeShutdownPrivilege
                           SeSyncAgentPrivilege
                           SeSystemEnvironmentPrivilege
                           SeSystemProfilePrivilege
                           SeSystemtimePrivilege
                           SeTakeOwnershipPrivilege
                           SeTcbPrivilege
                           SeTimeZonePrivilege
                           SeTrustedCredManAccessPrivilege
                           SeUndockPrivilege
                          }.freeze

      property :principal, String,
        description: "An optional property to add the user to the given privilege. Use only with add and remove action.",
        name_property: true

      property :users, [Array, String],
        description: "An optional property to set the privilege for given users. Use only with set action.",
        coerce: proc { |v| Array(v) }

      property :privilege, [Array, String],
        description: "One or more privileges to set for users.",
        required: true,
        coerce: proc { |v| Array(v) },
        callbacks: {
          "Privilege property restricted to the following values: #{PRIVILEGE_OPTS}" => lambda { |n| (n - PRIVILEGE_OPTS).empty? },
        }

      load_current_value do |new_resource|
        if new_resource.principal && (new_resource.action.include?(:add) || new_resource.action.include?(:remove))
          privilege Chef::ReservedNames::Win32::Security.get_account_right(new_resource.principal)
        end
      end

      action :add, description: "Add a user privilege." do
        ([*new_resource.privilege] - [*current_resource.privilege]).each do |user_right|
          converge_by("adding user '#{new_resource.principal}' privilege #{user_right}") do
            Chef::ReservedNames::Win32::Security.add_account_right(new_resource.principal, user_right)
          end
        end
      end

      action :set, description: "Set the privileges that are listed in the `privilege` property for only the users listed in the `users` property." do
        if new_resource.users.nil? || new_resource.users.empty?
          raise Chef::Exceptions::ValidationFailed, "Users are required property with set action."
        end

        users = []

        # Getting users with its domain for comparison
        new_resource.users.each do |user|
          user = Chef::ReservedNames::Win32::Security.lookup_account_name(user)
          users << user[1].account_name if user
        end

        new_resource.privilege.each do |privilege|
          accounts = Chef::ReservedNames::Win32::Security.get_account_with_user_rights(privilege)

          # comparing the existing accounts for privilege with users
          unless users == accounts
            # Removing only accounts which is not matching with users in new_resource
            (accounts - users).each do |account|
              converge_by("removing user '#{account}' from privilege #{privilege}") do
                Chef::ReservedNames::Win32::Security.remove_account_right(account, privilege)
              end
            end

            # Adding only users which is not already exist
            (users - accounts).each do |user|
              converge_by("adding user '#{user}' to privilege #{privilege}") do
                Chef::ReservedNames::Win32::Security.add_account_right(user, privilege)
              end
            end
          end
        end
      end

      action :clear, description: "Clear all user privileges" do
        new_resource.privilege.each do |privilege|
          accounts = Chef::ReservedNames::Win32::Security.get_account_with_user_rights(privilege)

          # comparing the existing accounts for privilege with users
          # Removing only accounts which is not matching with users in new_resource
          accounts.each do |account|
            converge_by("removing user '#{account}' from privilege #{privilege}") do
              Chef::ReservedNames::Win32::Security.remove_account_right(account, privilege)
            end
          end
        end
      end

      action :remove, description: "Remove a user privilege" do
        curr_res_privilege = current_resource.privilege
        missing_res_privileges = (new_resource.privilege - curr_res_privilege)

        if missing_res_privileges
          Chef::Log.info("User \'#{new_resource.principal}\' for Privilege: #{missing_res_privileges.join(", ")} not found. Nothing to remove.")
        end

        (new_resource.privilege - missing_res_privileges).each do |user_right|
          converge_by("removing user #{new_resource.principal} from privilege #{user_right}") do
            Chef::ReservedNames::Win32::Security.remove_account_right(new_resource.principal, user_right)
          end
        end
      end
    end
  end
end
