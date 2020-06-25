#
# Author:: Ashwini Nehate (<anehate@chef.io>)
# Author:: Davin Taddeo (<davin@chef.io>)
# Author:: Jeff Brimager (<jbrimager@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
      provides :windows_security_policy

      # The valid policy_names options found here
      # https://github.com/ChrisAWalker/cSecurityOptions under 'AccountSettings'
      policy_names = %w{LockoutDuration
                        MaximumPasswordAge
                        MinimumPasswordAge
                        MinimumPasswordLength
                        PasswordComplexity
                        PasswordHistorySize
                        LockoutBadCount
                        ResetLockoutCount
                        RequireLogonToChangePassword
                        ForceLogoffWhenHourExpire
                        NewAdministratorName
                        NewGuestName
                        ClearTextPassword
                        LSAAnonymousNameLookup
                        EnableAdminAccount
                        EnableGuestAccount
                       }
      description "Use the **windows_security_policy** resource to set a security policy on the Microsoft Windows platform."
      introduced "16.0"

      examples <<~DOC
      **Set Administrator Account to Enabled**:

      ```ruby
      windows_security_policy 'EnableAdminAccount' do
        secvalue       '1'
        action         :set
      end
      ```

      **Rename Administrator Account**:

      ```ruby
      windows_security_policy 'NewAdministratorName' do
        secvalue       'AwesomeChefGuy'
        action         :set
      end
      ```

      **Set Guest Account to Disabled**:

      ```ruby
      windows_security_policy 'EnableGuestAccount' do
        secvalue       '0'
        action         :set
      end
      ```
      DOC

      property :secoption, String, name_property: true, required: true, equal_to: policy_names,
      description: "The name of the policy to be set on windows platform to maintain its security."

      property :secvalue, String, required: true,
      description: "Policy value to be set for policy name."

      load_current_value do |desired|
        secopt_values = load_secopts_state
        output = powershell_out(secopt_values)
        if output.stdout.empty?
          current_value_does_not_exist!
        else
          state = Chef::JSONCompat.from_json(output.stdout)
        end
        secvalue state[desired.secoption.to_s]
      end

      action :set do
        converge_if_changed :secvalue do
          security_option = new_resource.secoption
          security_value = new_resource.secvalue

          cmd = <<-EOH
            $security_option = "#{security_option}"
            C:\\Windows\\System32\\secedit /export /cfg $env:TEMP\\#{security_option}_Export.inf
            if ( ($security_option -match "NewGuestName") -Or ($security_option -match "NewAdministratorName") )
              {
                $#{security_option}_Remediation = (Get-Content $env:TEMP\\#{security_option}_Export.inf) | Foreach-Object { $_ -replace '#{security_option}\\s*=\\s*\\"\\w*\\"', '#{security_option} = "#{security_value}"' } | Set-Content $env:TEMP\\#{security_option}_Export.inf
                C:\\Windows\\System32\\secedit /configure /db $env:windir\\security\\new.sdb /cfg $env:TEMP\\#{security_option}_Export.inf /areas SECURITYPOLICY
              }
            else
              {
                $#{security_option}_Remediation = (Get-Content $env:TEMP\\#{security_option}_Export.inf) | Foreach-Object { $_ -replace "#{security_option}\\s*=\\s*\\d*", "#{security_option} = #{security_value}" } | Set-Content $env:TEMP\\#{security_option}_Export.inf
                C:\\Windows\\System32\\secedit /configure /db $env:windir\\security\\new.sdb /cfg $env:TEMP\\#{security_option}_Export.inf /areas SECURITYPOLICY
              }
            Remove-Item $env:TEMP\\#{security_option}_Export.inf -force
          EOH

          powershell_exec!(cmd)
        end
      end

      action_class do
        def load_secopts_state
          <<-EOH
            C:\\Windows\\System32\\secedit /export /cfg $env:TEMP\\secopts_export.inf | Out-Null
            $secopts_data = (Get-Content $env:TEMP\\secopts_export.inf | Select-String -Pattern "^[CEFLMNPR].* =.*$" | Out-String)
            Remove-Item $env:TEMP\\secopts_export.inf -force
            $secopts_hash = ($secopts_data -Replace '"'| ConvertFrom-StringData)
            ([PSCustomObject]@{
              RequireLogonToChangePassword = $secopts_hash.RequireLogonToChangePassword
              PasswordComplexity = $secopts_hash.PasswordComplexity
              LSAAnonymousNameLookup = $secopts_hash.LSAAnonymousNameLookup
              EnableAdminAccount = $secopts_hash.EnableAdminAccount
              PasswordHistorySize = $secopts_hash.PasswordHistorySize
              MinimumPasswordLength = $secopts_hash.MinimumPasswordLength
              ResetLockoutCount = $secopts_hash.ResetLockoutCount
              MaximumPasswordAge = $secopts_hash.MaximumPasswordAge
              ClearTextPassword = $secopts_hash.ClearTextPassword
              NewAdministratorName = $secopts_hash.NewAdministratorName
              LockoutDuration = $secopts_hash.LockoutDuration
              EnableGuestAccount = $secopts_hash.EnableGuestAccount
              ForceLogoffWhenHourExpire = $secopts_hash.ForceLogoffWhenHourExpire
              MinimumPasswordAge = $secopts_hash.MinimumPasswordAge
              NewGuestName = $secopts_hash.NewGuestName
              LockoutBadCount = $secopts_hash.LockoutBadCount
            }) | ConvertTo-Json
          EOH
        end
      end
    end
  end
end
