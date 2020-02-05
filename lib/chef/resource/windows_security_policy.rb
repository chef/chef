#
# Author:: Ashwini Nehate (<anehate@chef.io>)
# Author:: Davin Taddeo (<davin@chef.io>)
# Author:: Jeff Brimager (<jbrimager@chef.io>)
# Copyright:: 2019-2020, Chef Software Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative "../resource"

class Chef
  class Resource
    class WindowsSecurityPolicy < Chef::Resource
      resource_name :windows_security_policy

      # The valid policy_names options found here
      # https://github.com/ChrisAWalker/cSecurityOptions under 'AccountSettings'
      policy_names = %w{MinimumPasswordAge
                MaximumPasswordAge
                MinimumPasswordLength
                PasswordComplexity
                PasswordHistorySize
                LockoutBadCount
                RequireLogonToChangePassword
                ForceLogoffWhenHourExpire
                NewAdministratorName
                NewGuestName
                ClearTextPassword
                LSAAnonymousNameLookup
                EnableAdminAccount
                EnableGuestAccount
                }
      description "Use the windows_security_policy resource to set a security policy on the Microsoft Windows platform."
      introduced "16.0"

      property :secoption, String, name_property: true, required: true, equal_to: policy_names,
      description: "The name of the policy to be set on windows platform to maintain its security."

      property :secvalue, String, required: true,
      description: "Policy value to be set for policy name."

      property :sensitive, [true, false], default: true,
      description: "Ensure that sensitive resource data is not logged by Chef Infra Client.",
      default_description: "true"

      action :set do
        security_option = new_resource.secoption
        if powershell_out!("(Get-PackageSource -Name PSGallery -WarningAction SilentlyContinue).name").stdout.empty? || powershell_out!("(Get-Package -Name cSecurityOptions -WarningAction SilentlyContinue).name").stdout.empty?
          raise "This resource needs Powershell module cSecurityOptions to be installed. \n Please install it and then re-run the recipe. \n https://www.powershellgallery.com/packages/cSecurityOptions/3.1.3"
        end

        sec_hash = {
          security_option => new_resource.secvalue,
        }
        dsc_resource "AccountSettings" do
          module_name "cSecurityOptions"
          resource :AccountAndBasicAuditing
          property :Enable, "$true"
          property :AccountAndBasicAuditing, sec_hash
          sensitive new_resource.sensitive
        end
      end
    end
  end
end
