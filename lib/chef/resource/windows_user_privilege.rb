#
# Author:: Jared Kauppila (<jared@kauppi.la>)
# Author:: Vasundhara Jagdale(<vasundhara.jagdale@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.

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

      provides :windows_user_privilege
      description "Use the **windows_user_privilege** resource to set privileges for a principal, user, or group.\n See [Microsoft's user rights assignment documentation](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment) for more information."

      introduced "16.0"

      examples <<~DOC
      **Set the SeNetworkLogonRight privilege for the Builtin Administrators and Authenticated Users groups**:

      The `:set` action will add this privilege for these two groups and remove this privilege from all other groups or users.

      ```ruby
      windows_user_privilege 'Network Logon Rights' do
        privilege      'SeNetworkLogonRight'
        users          ['BUILTIN\\Administrators', 'NT AUTHORITY\\Authenticated Users']
        action         :set
      end
      ```

      **Set the SeCreatePagefilePrivilege privilege for the Builtin Guests and Administrator groups**:

      The `:set` action will add this privilege for these two groups and remove this privilege from all other groups or users.

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        users          ['BUILTIN\\Guests', 'BUILTIN\\Administrators']
        action         :set
      end
      ```

      **Add the SeDenyRemoteInteractiveLogonRight privilege to the 'Remote interactive logon' principal**:

      ```ruby
      windows_user_privilege 'Remote interactive logon' do
        privilege      'SeDenyRemoteInteractiveLogonRight'
        action         :add
      end
      ```

      **Add the SeCreatePageFilePrivilege privilege to the Builtin Guests group**:

      ```ruby
      windows_user_privilege 'Guests add Create Pagefile' do
        principal      'BUILTIN\\Guests'
        privilege      'SeCreatePagefilePrivilege'
        action         :add
      end
      ```

      **Remove the SeCreatePageFilePrivilege privilege from the Builtin Guests group**:

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        principal      'BUILTIN\\Guests'
        action         :remove
      end
      ```

      **Clear the SeDenyNetworkLogonRight privilege from all users**:

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
                           SeDelegateSessionUserImpersonatePrivilege
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
               description: "An optional property to add the privilege for given principal. Use only with add and remove action. Principal can either be a user, group, or [special identity](https://docs.microsoft.com/en-us/windows/security/identity-protection/access-control/special-identities).",
               name_property: true

      property :users, [Array, String],
               description: "An optional property to set the privilege for the specified users. Use only with `:set` action",
               coerce: proc { |v| Array(v) }

      property :privilege, [Array, String],
               description: "One or more privileges to set for principal or users/groups. For more information, see [Microsoft's documentation on what each privilege does](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment).",
               required: true,
               coerce: proc { |v| Array(v) },
               callbacks: {
                 "Privilege property restricted to the following values: #{PRIVILEGE_OPTS}" => lambda { |n| (n - PRIVILEGE_OPTS).empty? },
               }, identity: true

      load_current_value do |new_resource|
        if new_resource.principal && (new_resource.action.include?(:add) || new_resource.action.include?(:remove))
          privilege Chef::ReservedNames::Win32::Security.get_account_right(new_resource.principal)
        end
      end

      action :add, description: "Add a privileges to a principal." do
        ([*new_resource.privilege] - [*current_resource.privilege]).each do |principal_right|
          converge_by("adding principal '#{new_resource.principal}' privilege #{principal_right}") do
            Chef::ReservedNames::Win32::Security.add_account_right(new_resource.principal, principal_right)
          end
        end
      end

      action :set, description: "Set the privileges that are listed in the `privilege` property for only the users listed in the `users` property. All other users not listed with given privilege will be have the privilege removed." do
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

      action :remove, description: "Remove a principal privilege" do
        curr_res_privilege = current_resource.privilege
        missing_res_privileges = (new_resource.privilege - curr_res_privilege)

        if missing_res_privileges
          Chef::Log.info("User '#{new_resource.principal}' for Privilege: #{missing_res_privileges.join(", ")} not found. Nothing to remove.")
        end

        (new_resource.privilege - missing_res_privileges).each do |principal_right|
          converge_by("removing principal #{new_resource.principal} from privilege #{principal_right}") do
            Chef::ReservedNames::Win32::Security.remove_account_right(new_resource.principal, principal_right)
          end
        end
      end
    end
  end
end
