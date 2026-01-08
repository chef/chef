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

require_relative "habitat_sup"

class Chef
  class Resource
    class HabitatSupSystemd < HabitatSup
      provides :habitat_sup, os: "linux", target_mode: true
      provides :habitat_sup_systemd, target_mode: true
      target_mode support: :full

      action :run do
        super()

        service_environment = []
        service_environment.push("HAB_BLDR_URL=#{new_resource.bldr_url}") if new_resource.bldr_url
        service_environment.push("HAB_AUTH_TOKEN=#{new_resource.auth_token}") if new_resource.auth_token
        service_environment.push("HAB_SUP_GATEWAY_AUTH_TOKEN=#{new_resource.gateway_auth_token}") if new_resource.gateway_auth_token
        systemd_unit "hab-sup.service" do
          content(Unit: {
                    Description: "The Habitat Supervisor",
                  },
                  Service: {
                    LimitNOFILE: new_resource.limit_no_files,
                    Environment: service_environment,
                    ExecStart: "/bin/hab sup run #{exec_start_options}",
                    ExecStop: "/bin/hab sup term",
                    Restart: "on-failure",
                  }.compact,
                  Install: {
                    WantedBy: "default.target",
                  })
          action :create
        end

        service "hab-sup" do
          subscribes :restart, "systemd_unit[hab-sup.service]"
          subscribes :restart, "habitat_package[core/hab-sup]"
          subscribes :restart, "habitat_package[core/hab-launcher]"
          subscribes :restart, "template[/hab/sup/default/config/sup.toml]"
          action %i{enable start}
          not_if { node["chef_packages"]["chef"]["chef_root"].include?("/pkgs/chef/chef-infra-client") }
        end
      end

      action :stop do
        service "hab-sup" do
          action :stop
        end
      end
    end
  end
end
