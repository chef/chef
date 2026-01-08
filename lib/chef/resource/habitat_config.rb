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
require_relative "../http"
require_relative "../json_compat"
require_relative "../resource"

require "tmpdir" unless defined?(Dir::Tmpname)

class Chef
  class Resource
    class HabitatConfig < Chef::Resource

      provides :habitat_config, target_mode: true
      target_mode support: :full

      description "Use the **habitat_config** resource to apply a configuration to a Chef Habitat service."
      introduced "17.3"
      examples <<~DOC
      **Configure your nginx defaults**

      ```ruby
      habitat_config 'nginx.default' do
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
        description: "The configuration to apply as a ruby hash, for example, `{ worker_count: 2, http: { keepalive_timeout: 120 } }`."

      property :service_group, String, name_property: true, desired_state: false,
        description: "The service group to apply the configuration to. For example, `nginx.default`"

      property :remote_sup, String, default: "127.0.0.1:9632", desired_state: false,
        description: "Address to a remote supervisor's control gateway."

      # Http port needed for querying/comparing current config value
      property :remote_sup_http, String, default: "127.0.0.1:9631", desired_state: false,
        description: "Address for remote supervisor http port. Used to pull existing."

      property :gateway_auth_token, String, desired_state: false,
        description: "Auth token for accessing the remote supervisor's http port."

      property :user, String, desired_state: false,
        description: "Name of user key to use for encryption. Passes `--user` to `hab config apply`."

      load_current_value do
        def census(http_uri)
          headers = {}
          headers["Authorization"] = "Bearer #{gateway_auth_token}" if property_is_set?(:gateway_auth_token)

          if Chef::Config.target_mode?
            raw = TargetIO::HTTP.new(http_uri).get("/census", headers)
            response = from_json(raw)
          else
            response = Chef::HTTP::SimpleJSON.new(http_uri).get("/census", headers)
          end

          Mash.new(response)
        end

        http_uri = "http://#{remote_sup_http}"

        begin
          sc = census["census_groups"][service_group]["service_config"]["value"]
        rescue
          # Default to a blank config if anything (http error, json parsing, finding
          # the config object) goes wrong
          sc = {}
        end
        config sc
      end

      action :apply, description: "applies the given configuration" do
        converge_if_changed do
          # Use the current timestamp as the serial number/incarnation
          incarnation = Time.now.tv_sec

          opts = []
          # opts gets flattened by shell_out_compact later
          opts << ["--remote-sup", new_resource.remote_sup] if new_resource.remote_sup
          opts << ["--user", new_resource.user] if new_resource.user

          tempname = Dir::Tmpname.create(["habitat_config", ".toml"]) {}
          TargetIO::File.open(tempname, "w") do |tempfile|
            tempfile.write(render_toml(new_resource.config))
          end

          begin
            hab("config", "apply", opts, new_resource.service_group, incarnation, tempname)
          ensure
            TargetIO::File.unlink(tempname)
          end
        end
      end

      action_class do
        use "../resource/habitat/habitat_shared"
      end
    end
  end
end
