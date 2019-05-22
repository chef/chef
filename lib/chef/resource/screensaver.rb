#
# Author:: Nate Walck (<n8@uber.com>)
# Copyright:: 2019, Uber, Inc.
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
    class Screensaver < Chef::Resource
      resource_name :screensaver
      provides(:screensaver) { true }

      description "Use the screensaver resource to configure screensaver settings."
      introduced "15.1"

      property :idle_time, Integer,
               description: "Number of seconds before screensaver activates."

      property :ask_for_password, [TrueClass, FalseClass],
               description: "Ask for password to bypass screensaver."

      property :password_delay, Integer,
               description: "How many seconds to wait before asking for password."

      property :organization, String,
               description: "How many seconds to wait before asking for password.",
               default: "Chef"

      property :prefix , String,
               description: "How many seconds to wait before asking for password.",
               default: "com.chef"

      action :manage do
        description "Manage screensaver settings."

        converge_by("Manage #{@new_resource}") do
          case node[:platform_family]
          when "mac_os_x"
            manage_screensaver_osx
          when "windows"
            manage_screensaver_win
          end
        end
      end

      action :unmanage do
        description "Unmanage screensaver settings"

        converge_by("Unmanage #{@new_resource}") do
          case node[:platform_family]
          when "mac_os_x"
            unmanage_screensaver_osx
          when "windows"
            unmanage_screensaver_win
          end
        end
      end

      action_class do
        def profile_identifier
          "#{new_resource.prefix}.chef.screensaver"
        end

        def manage_screensaver_osx
          screensaver_profile = {
            'PayloadIdentifier' => profile_identifier,
            'PayloadRemovalDisallowed' => true,
            'PayloadScope' => 'System',
            'PayloadType' => 'Configuration',
            'PayloadUUID' => 'CEA1E58D-9D0F-453A-AA52-830986A8366C',
            'PayloadOrganization' => new_resource.organization,
            'PayloadVersion' => 1,
            'PayloadDisplayName' => 'Screensaver',
            'PayloadContent' => []
          }
          screensaver_payload = {
            'PayloadType' => 'com.apple.screensaver',
            'PayloadVersion' => 1,
            'PayloadIdentifier' => profile_identifier,
            'PayloadUUID' => '3B2AD6A9-F99E-4813-980A-4147617B2E75',
            'PayloadEnabled' => true,
            'PayloadDisplayName' => 'Screensaver'
          }

          screensaver_payload['idleTime'] = new_resource.idle_time if new_resource.idle_time
          screensaver_payload['askForPassword'] = new_resource.idle_time if new_resource.ask_for_password
          screensaver_payload['askForPasswordDelay'] = new_resource.idle_time if new_resource.password_delay

          screensaver_profile['PayloadContent'].push(screensaver_payload)

          osx_profile_resource(
            profile_identifier,
            'install',
            screensaver_profile
          )
        end

        def manage_screensaver_win
          # password_delay
          registry_key "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" do
            values [{
              name: "ScreenSaverGracePeriod",
              type: :dword,
              data: new_resource.password_delay,
            }]
            action :create
            not_if { new_resource.password_delay.nil? }
          end
          # ask_for_password
          registry_key "HKCU\\Control Panel\\Desktop" do
            values [{name: "ScreenSaveActive", type: :string, data: '1'},
                    {name: "ScreenSaverIsSecure", type: :string, data: '1'},
            ]
            action :create
            only_if { new_resource.ask_for_password }
          end
          # idle_time
          registry_key "HKCU\\Control Panel\\Desktop" do
            values [{
              name: "screensavetimeout",
              type: :string,
              data: new_resource.idle_time
            }]
            action :create
            not_if { new_resource.idle_time.nil? }
          end
        end

        def unmanage_screensaver_osx
          osx_profile_resource(profile_identifier, 'remove', nil)
        end

        def unmanage_screensaver_win
          # Remove screensaver settings
          registry_key "HKCU\\Control Panel\\Desktop" do
            values [{name: "ScreenSaveActive", type: :string, data: ''},
                    {name: "ScreenSaverIsSecure", type: :string, data: ''},
                    {name: "screensavetimeout", type: :string, data: ''},
                   ]
            action :delete
          end
          registry_key "HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon" do
            values [{
              name: "ScreenSaverGracePeriod",
              type: :dword,
              data: '',
            }]
            action :delete
          end
        end

        def osx_profile_resource(identifier, action, profile)
          res = Chef::Resource::OsxProfile.new(identifier, run_context)
          res.send('profile', profile) unless profile.nil?
          res.action(action)
          res.run_action action
          res
        end
      end
    end
  end
end
