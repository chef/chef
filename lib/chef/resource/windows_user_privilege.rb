#
# Author:: Jared Kauppila (<jared@kauppi.la>)
# Author:: Vasundhara Jagdale(<vasundhara.jagdale@chef.io>)
# Copyright 2008-2019, Chef Software, Inc.

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
      privilege_opts = %w{SeTrustedCredManAccessPrivilege
                          SeNetworkLogonRight
                          SeTcbPrivilege
                          SeMachineAccountPrivilege
                          SeIncreaseQuotaPrivilege
                          SeInteractiveLogonRight
                          SeRemoteInteractiveLogonRight
                          SeBackupPrivilege
                          SeChangeNotifyPrivilege
                          SeSystemtimePrivilege
                          SeTimeZonePrivilege
                          SeCreatePagefilePrivilege
                          SeCreateTokenPrivilege
                          SeCreateGlobalPrivilege
                          SeCreatePermanentPrivilege
                          SeCreateSymbolicLinkPrivilege
                          SeDebugPrivilege
                          SeDenyNetworkLogonRight
                          SeDenyBatchLogonRight
                          SeDenyServiceLogonRight
                          SeDenyInteractiveLogonRight
                          SeDenyRemoteInteractiveLogonRight
                          SeEnableDelegationPrivilege
                          SeRemoteShutdownPrivilege
                          SeAuditPrivilege
                          SeImpersonatePrivilege
                          SeIncreaseWorkingSetPrivilege
                          SeIncreaseBasePriorityPrivilege
                          SeLoadDriverPrivilege
                          SeLockMemoryPrivilege
                          SeBatchLogonRight
                          SeServiceLogonRight
                          SeSecurityPrivilege
                          SeRelabelPrivilege
                          SeSystemEnvironmentPrivilege
                          SeManageVolumePrivilege
                          SeProfileSingleProcessPrivilege
                          SeSystemProfilePrivilege
                          SeUndockPrivilege
                          SeAssignPrimaryTokenPrivilege
                          SeRestorePrivilege
                          SeShutdownPrivilege
                          SeSyncAgentPrivilege
                          SeTakeOwnershipPrivilege
                        }

      resource_name :windows_user_privilege
      description "The windows_user_privilege resource allows to add and set principal (User/Group) to the specified privilege. \n Ref: https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment"

      introduced "16.0"

      property :principal, String,
        description: "An optional property to add the user to the given privilege. Use only with add and remove action.",
        name_property: true

      property :users, Array,
        description: "An optional property to set the privilege for given users. Use only with set action."

      property :privilege, [Array, String],
        description: "Privilege to set for users.",
        required: true,
        callbacks: {
           "Option privilege must include any of the: #{privilege_opts}" => lambda {
             |v| v.is_a?(Array) ? (privilege_opts & v).size == v.size : privilege_opts.include?(v)
           },
         }

      property :sensitive, [true, false], default: true

      load_current_value do |new_resource|
        unless new_resource.principal.nil?
          privilege Chef::ReservedNames::Win32::Security.get_account_right(new_resource.principal) unless new_resource.action.include?(:set)
        end
      end

      action :add do
        ([*new_resource.privilege] - [*current_resource.privilege]).each do |user_right|
          converge_by("adding user privilege #{user_right}") do
            Chef::ReservedNames::Win32::Security.add_account_right(new_resource.principal, user_right)
          end
        end
      end

      action :set do
        uras = new_resource.privilege

        if new_resource.users.nil? || new_resource.users.empty?
          raise Chef::Exceptions::ValidationFailed, "Users are required property with set action."
        end

        if powershell_out!("Get-PackageSource -Name PSGallery").stdout.empty? || powershell_out!("(Get-Package -Name cSecurityOptions -WarningAction SilentlyContinue).name").stdout.empty?
          raise "This resource needs Powershell module cSecurityOptions to be installed. \n Please install it and then re-run the recipe. \n https://www.powershellgallery.com/packages/cSecurityOptions/3.1.3"
        end

        uras.each do |ura|
          dsc_resource "URA" do
            module_name "cSecurityOptions"
            resource :UserRightsAssignment
            property :Ensure, "Present"
            property :Privilege, ura
            property :Identity, new_resource.users
            sensitive new_resource.sensitive
          end
        end
      end

      action :remove do
        curr_res_privilege = current_resource.privilege
        new_res_privilege = new_resource.privilege

        new_res_privilege = [] << new_res_privilege if new_resource.privilege.is_a?(String)
        missing_res_privileges = (new_res_privilege - curr_res_privilege)

        unless missing_res_privileges.empty?
          Chef::Log.info("Privilege: #{missing_res_privileges.join(", ")} not present. Unable to delete")
        end

        (new_res_privilege - missing_res_privileges).each do |user_right|
          converge_by("removing user privilege #{user_right}") do
            Chef::ReservedNames::Win32::Security.remove_account_right(new_resource.principal, user_right)
          end
        end
      end
    end
  end
end
