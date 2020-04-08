#
# Copyright:: 2020, Chef Software Inc.
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
require_relative "../dist"

class Chef
  class Resource
    class ChefClientSystemdTimer < Chef::Resource
      unified_mode true

      provides :chef_client_systemd_timer

      description "Use the chef_client_systemd_timer resource to setup the #{Chef::Dist::PRODUCT} to run as a systemd timer."
      introduced "16.0"
      examples <<~DOC
      Setup #{Chef::Dist::PRODUCT} to run using the default 30 minute cadence
      ```ruby
      chef_client_systemd_timer "Run chef-client as a systemd timer"
      ```

      Run #{Chef::Dist::PRODUCT} every 1 hour
      ```ruby
      chef_client_systemd_timer "Run chef-client every 1 hour" do
        interval "1hr"
      end
      ```

      Run #{Chef::Dist::PRODUCT} with extra options passed to the client
      ```ruby
      chef_client_systemd_timer "Run an override recipe" do
        daemon_options ["--override-runlist mycorp_base::default"]
      end
      ```
      DOC

      property :job_name, String,
        default: Chef::Dist::CLIENT,
        description: "The name of the system timer to create."
      property :description, String, default: "Chef Infra Client periodic execution"

      property :user, String,
        description: "The name of the user that #{Chef::Dist::PRODUCT} runs as.",
        default: "root"

      property :delay_after_boot, String, default: "1min"
      property :interval, String, default: "30min"
      property :splay, [Integer, String],
        default: 300,
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be a positive number" => proc { |v| v > 0 } },
        description: "A random number of seconds between 0 and X to add to interval so that all #{Chef::Dist::CLIENT} commands don't execute at the same time."

      property :accept_chef_license, [true, false],
        description: "Accept the Chef Online Master License and Services Agreement. See https://www.chef.io/online-master-agreement/",
        default: false

      property :run_on_battery, [true, false], default: true

      property :config_directory, String,
        default: Chef::Dist::CONF_DIR,
        description: "The path of the config directory."

      property :chef_binary_path, String,
        default: "/opt/#{Chef::Dist::DIR_SUFFIX}/bin/#{Chef::Dist::CLIENT}",
        description: "The path to the #{Chef::Dist::CLIENT} binary."

      property :daemon_options, Array,
        default: lazy { [] },
        description: "An array of options to pass to the #{Chef::Dist::CLIENT} command."

      property :environment, Hash,
        default: lazy { {} },
        description: "A Hash containing additional arbitrary environment variables under which the systemd timer will be run in the form of ``({'ENV_VARIABLE' => 'VALUE'})``."

      action :add do
        systemd_unit "#{new_resource.job_name}.service" do
          content service_content
          action :create
        end

        systemd_unit "#{new_resource.job_name}.timer" do
          content timer_content
          action %i{create enable start}
        end
      end

      action :remove do
        systemd_unit "#{new_resource.job_name}.service" do
          action :remove
        end

        systemd_unit "#{new_resource.job_name}.timer" do
          action :remove
        end
      end

      action_class do
        #
        # The chef-client command to run in the systemd unit.
        #
        # @return [String]
        #
        def chef_client_cmd
          cmd = "#{new_resource.chef_binary_path}"
          cmd << " #{new_resource.daemon_options.join(" ")}" unless new_resource.daemon_options.empty?
          cmd << " --chef-license accept" if new_resource.accept_chef_license
          cmd << " -c #{::File.join(new_resource.config_directory, "client.rb")}"
          cmd
        end

        #
        # The timer content to pass to the systemd_unit
        #
        # @return [Hash]
        #
        def timer_content
          {
          "Unit" => { "Description" => new_resource.description },
          "Timer" => {
            "OnBootSec" => new_resource.delay_after_boot,
            "OnUnitActiveSec" => new_resource.interval,
            "RandomizedDelaySec" => new_resource.splay,
            },
          "Install" => { "WantedBy" => "timers.target" },
          }
        end

        #
        # The service content to pass to the systemd_unit
        #
        # @return [Hash]
        #
        def service_content
          unit = {
            "Unit" => {
              "Description" => new_resource.description,
              "After" => "network.target auditd.service",
            },
            "Service" => {
              "Type" => "oneshot",
              "ExecStart" => chef_client_cmd,
              "SuccessExitStatus" => [3, 213, 35, 37, 41],
            },
            "Install" => { "WantedBy" => "multi-user.target" },
          }

          unit["Service"]["ConditionACPower"] = "true" unless new_resource.run_on_battery
          unit["Service"]["Environment"] = new_resource.environment.collect { |k, v| "\"#{k}=#{v}\"" } unless new_resource.environment.empty?
          unit
        end
      end
    end
  end
end
