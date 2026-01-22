#  Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
# License:: Apache License, Version 2.0
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
# See the License for the specific language governing

require_relative "../resource"
class Chef
  class Resource
    class HabitatUserToml < Chef::Resource
      provides :habitat_user_toml

      description "Use the **habitat_user_toml** to template a `user.toml` for Chef Habitat services. Configurations set in the  `user.toml` override the `default.toml` for a given package, which makes it an alternative to applying service group level configuration."
      introduced "17.3"
      examples <<~DOC
      **Configure user specific settings to nginx**

      ```ruby
      habitat_user_toml 'nginx' do
        config({
          worker_count: 2,
          http: {
            keepalive_timeout: 120
          }
          })
        end
        ```
      DOC

      property :config, Mash, required: true, coerce: proc { |m| m.is_a?(Hash) ? Mash.new(m) : m },
        description: "Only valid for `:create` action. The configuration to apply as a ruby hash, for example, `{ worker_count: 2, http: { keepalive_timeout: 120 } }`."

      property :service_name, String, name_property: true, desired_state: false,
        description: "The service group to apply the configuration to, for example, `nginx.default`."

      action :create, description: "(default action) Create the user.toml from the specified config." do
        directory config_directory do
          mode "0755"
          owner root_owner
          group node["root_group"]
          recursive true
        end

        file "#{config_directory}/user.toml" do
          mode "0600"
          owner root_owner
          group node["root_group"]
          content render_toml(new_resource.config)
          sensitive true
        end
      end

      action :delete, description: "Delete the user.toml" do
        file "#{config_directory}/user.toml" do
          sensitive true
          action :delete
        end
      end

      action_class do
        def config_directory
          windows? ? "C:/hab/user/#{new_resource.service_name}/config" : "/hab/user/#{new_resource.service_name}/config"
        end

        def wmi_property_from_query(wmi_property, wmi_query)
          @wmi = ::WIN32OLE.connect("winmgmts://")
          result = @wmi.ExecQuery(wmi_query)
          return unless result.each.any?

          result.each.next.send(wmi_property)
        end

        def root_owner
          if windows?
            wmi_property_from_query(:name, "select * from Win32_UserAccount where sid like 'S-1-5-21-%-500' and LocalAccount=True")
          else
            "root"
          end
        end
      end
    end
  end
end
