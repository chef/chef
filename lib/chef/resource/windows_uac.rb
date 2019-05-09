#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2019, Chef Software, Inc.
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
#

require_relative "../resource"

class Chef
  class Resource
    class WindowsUac < Chef::Resource
      resource_name :windows_uac
      provides :windows_uac

      description 'The windows_uac resource configures UAC on Windows hosts by setting registry keys at \'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\''
      introduced "15.0"

      # https://docs.microsoft.com/en-us/windows/security/identity-protection/user-account-control/user-account-control-group-policy-and-registry-key-settings#user-account-control-virtualize-file-and-registry-write-failures-to-per-user-locations
      property :enable_uac, [TrueClass, FalseClass],
               description: 'Enable or disable UAC Admin Approval Mode. If this is changed a system restart is required. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA.',
               default: true # EnableLUA

      property :require_signed_binaries, [TrueClass, FalseClass],
               description: 'Only elevate executables that are signed and validated. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA\ValidateAdminCodeSignatures.',
               default: false

      property :prompt_on_secure_desktop, [TrueClass, FalseClass],
               description: 'Switch to the secure desktop when prompting for elevation. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA\PromptOnSecureDesktop.',
               default: true

      property :detect_installers, [TrueClass, FalseClass],
               description: 'Detect application installations and prompt for elevation. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA\EnableInstallerDetection.'

      property :consent_behavior_admins, Symbol,
               description: 'Behavior of the elevation prompt for administrators in Admin Approval Mode. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA\ConsentPromptBehaviorAdmin.',
               equal_to: [:no_prompt, :secure_prompt_for_creds, :secure_prompt_for_consent, :prompt_for_creds, :prompt_for_consent, :prompt_for_consent_non_windows_binaries],
               default: :prompt_for_consent_non_windows_binaries

      property :consent_behavior_users, Symbol,
               description: 'Behavior of the elevation prompt for standard users. Sets HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA\ConsentPromptBehaviorUser.',
               equal_to: [:auto_deny, :secure_prompt_for_creds, :prompt_for_creds],
               default: :prompt_for_creds

      action :configure do
        description 'Configures UAC by setting registry keys at \'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\''

        registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' do
          values [{ name: "EnableLUA", type: :dword, data: bool_to_reg(new_resource.enable_uac) },
                  { name: "ValidateAdminCodeSignatures", type: :dword, data: bool_to_reg(new_resource.require_signed_binaries) },
                  { name: "PromptOnSecureDesktop", type: :dword, data: bool_to_reg(new_resource.prompt_on_secure_desktop) },
                  { name: "ConsentPromptBehaviorAdmin", type: :dword, data: consent_behavior_admins_symbol_to_reg(new_resource.consent_behavior_admins) },
                  { name: "ConsentPromptBehaviorUser", type: :dword, data: consent_behavior_users_symbol_to_reg(new_resource.consent_behavior_users) },
                  { name: "EnableInstallerDetection", type: :dword, data: bool_to_reg(new_resource.detect_installers) },
               ]
          action :create
        end
      end

      action_class do
        # converts a Ruby true/false to a 1 or 0
        #
        # @return [Integer] 1:true, 0: false
        def bool_to_reg(bool)
          bool ? 1 : 0
        end

        # converts the symbols we use in the consent_behavior_admins property into numbers 0-5 based on their array index
        #
        # @return [Integer]
        def consent_behavior_admins_symbol_to_reg(sym)
          [:no_prompt, :secure_prompt_for_creds, :secure_prompt_for_consent, :prompt_for_creds, :prompt_for_consent, :prompt_for_consent_non_windows_binaries].index(sym)
        end

        # converts the symbols we use in the consent_behavior_users property into numbers 0-2 based on their array index
        #
        # @return [Integer]
        def consent_behavior_users_symbol_to_reg(sym)
          [:auto_deny, :secure_prompt_for_creds, :prompt_for_creds].index(sym)
        end
      end
    end
  end
end
