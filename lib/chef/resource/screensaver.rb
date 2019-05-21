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
      default_action :manage

      description "Use the screensaver resource to configure screensaver settings."
      introduced "14.0"

      property :idle_time, Integer,
               description: "The exact name of printer driver installed on the system."

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
          manage_screensaver_osx if node[:platform_family] == "mac_os_x"
        end
      end

      action :unmanage do
        description "Unmanage screensaver settings"

        converge_by("Unmanage #{@new_resource}") do
          unmanage_screensaver_osx if node[:platform_family] == "mac_os_x"
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

        def unmanage_screensaver_osx
          osx_profile_resource(profile_identifier, 'remove', nil)
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
