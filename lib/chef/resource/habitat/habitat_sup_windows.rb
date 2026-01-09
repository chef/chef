#
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
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "win32/service" if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
require_relative "habitat_sup"

class Chef
  class Resource
    class HabitatSupWindows < HabitatSup
      provides :habitat_sup, os: "windows"
      provides :habitat_sup_windows
      target_mode support: false

      service_file = ::File.expand_path("../support/HabService.dll.config.erb")
      win_service_config = "C:/hab/svc/windows-service/HabService.dll.config"

      action :run do
        super()

        # TODO: There has to be a better way to handle auth token on windows
        # than the system wide environment variable
        auth_action = new_resource.auth_token ? :create : :delete
        env "HAB_AUTH_TOKEN" do
          value new_resource.auth_token if new_resource.auth_token
          action auth_action
        end

        gateway_auth_action = new_resource.gateway_auth_token ? :create : :delete
        env "HAB_SUP_GATEWAY_AUTH_TOKEN" do
          value new_resource.gateway_auth_token if new_resource.gateway_auth_token
          action gateway_auth_action
        end

        bldr_action = new_resource.bldr_url ? :create : :delete
        env "HAB_BLDR_URL" do
          value new_resource.bldr_url if new_resource.bldr_url
          action bldr_action
        end

        habitat_package "core/windows-service" do
          bldr_url new_resource.bldr_url if new_resource.bldr_url
          version new_resource.service_version if new_resource.service_version
        end

        execute "hab pkg exec core/windows-service install" do
          not_if { ::Win32::Service.exists?("Habitat") }
        end

        # win_version = `dir /D /B C:\\hab\\pkgs\\core\\hab-launcher`.split().last

        template win_service_config.to_s do
          source ::File.expand_path("../support/HabService.dll.config.erb", __dir__)
          local true
          cookbook "habitat"
          variables exec_start_options: exec_start_options,
                    bldr_url: new_resource.bldr_url,
                    auth_token: new_resource.auth_token,
                    gateway_auth_token: new_resource.gateway_auth_token
          # win_launcher: win_version
          action :touch
        end

        service "Habitat" do
          subscribes :restart, "env[HAB_AUTH_TOKEN]"
          subscribes :restart, "env[HAB_SUP_GATEWAY_AUTH_TOKEN]"
          subscribes :restart, "env[HAB_BLDR_URL]"
          subscribes :restart, "template[#{win_service_config}]"
          subscribes :restart, "habitat_package[core/hab-sup]"
          subscribes :restart, "habitat_package[core/hab-launcher]"
          subscribes :restart, "template[C:/hab/sup/default/config/sup.toml]"
          action %i{enable start}
          not_if { node["chef_packages"]["chef"]["chef_root"].include?("/pkgs/chef/chef-infra-client") }
        end
      end
    end
  end
end
