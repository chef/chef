#
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
#

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class ChefClientSystemdTimer < Chef::Resource
      unified_mode true

      provides :chef_client_systemd_timer

      description "Use the **chef_client_systemd_timer** resource to setup the #{ChefUtils::Dist::Infra::PRODUCT} to run as a systemd timer."
      introduced "16.0"
      examples <<~DOC
      **Setup #{ChefUtils::Dist::Infra::PRODUCT} to run using the default 30 minute cadence**:

      ```ruby
      chef_client_systemd_timer 'Run #{ChefUtils::Dist::Infra::PRODUCT} as a systemd timer'
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} every 1 hour**:

      ```ruby
      chef_client_systemd_timer 'Run #{ChefUtils::Dist::Infra::PRODUCT} every 1 hour' do
        interval '1hr'
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with extra options passed to the client**:

      ```ruby
      chef_client_systemd_timer 'Run an override recipe' do
        daemon_options ['--override-runlist mycorp_base::default']
      end
      ```
      DOC

      property :job_name, String,
        description: "The name of the system timer to create.",
        default: ChefUtils::Dist::Infra::CLIENT

      property :description, String,
        description: "The description to add to the systemd timer. This will be displayed when running `systemctl status` for the timer.",
        default: "#{ChefUtils::Dist::Infra::PRODUCT} periodic execution"

      property :user, String,
        description: "The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as.",
        default: "root"

      property :delay_after_boot, String,
        description: "The time to wait after booting before the interval starts. This is expressed as a systemd time span such as `300seconds`, `1hr`, or `1m`. See <https://www.freedesktop.org/software/systemd/man/systemd.time.html> for a complete list of allowed time span values.",
        default: "1min"

      property :interval, String,
        description: "The interval to wait between executions. This is expressed as a systemd time span such as `300seconds`, `1hr`, or `1m`. See <https://www.freedesktop.org/software/systemd/man/systemd.time.html> for a complete list of allowed time span values.",
        default: "30min"

      property :splay, String,
        description: "A interval between 0 and X to add to the interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time. This is expressed as a systemd time span such as `300seconds`, `1hr`, or `1m`. See <https://www.freedesktop.org/software/systemd/man/systemd.time.html> for a complete list of allowed time span values.",
        default: "5min"

      property :accept_chef_license, [true, false],
        description: "Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement/>",
        default: false

      property :run_on_battery, [true, false],
        description: "Run the timer for #{ChefUtils::Dist::Infra::PRODUCT} if the system is on battery.",
        default: true

      property :config_directory, String,
        description: "The path of the config directory.",
        default: ChefConfig::Config.etc_chef_dir

      property :chef_binary_path, String,
        description: "The path to the #{ChefUtils::Dist::Infra::CLIENT} binary.",
        default: "/opt/#{ChefUtils::Dist::Infra::DIR_SUFFIX}/bin/#{ChefUtils::Dist::Infra::CLIENT}"

      property :daemon_options, Array,
        description: "An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command.",
        default: []

      property :environment, Hash,
        description: "A Hash containing additional arbitrary environment variables under which the systemd timer will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`.",
        default: {}

      property :cpu_quota, [Integer, String],
        description: "The systemd CPUQuota to run the #{ChefUtils::Dist::Infra::CLIENT} process with. This is a percentage value of the total CPU time available on the system. If the system has more than 1 core this may be a value greater than 100.",
        introduced: "16.5",
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be a positive Integer" => proc { |v| v > 0 } }

      action :add, description: "Add a systemd timer that runs #{ChefUtils::Dist::Infra::PRODUCT}." do
        systemd_unit "#{new_resource.job_name}.service" do
          content service_content
          action :create
        end

        systemd_unit "#{new_resource.job_name}.timer" do
          content timer_content
          action %i{create enable start}
        end
      end

      action :remove, description: "Remove a systemd timer that runs #{ChefUtils::Dist::Infra::PRODUCT}." do
        systemd_unit "#{new_resource.job_name}.service" do
          action :delete
        end

        systemd_unit "#{new_resource.job_name}.timer" do
          action :delete
        end
      end

      action_class do
        #
        # The chef-client command to run in the systemd unit.
        #
        # @return [String]
        #
        def chef_client_cmd
          cmd = new_resource.chef_binary_path.dup
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
          unit["Service"]["CPUQuota"] = new_resource.cpu_quota if new_resource.cpu_quota
          unit["Service"]["Environment"] = new_resource.environment.collect { |k, v| "\"#{k}=#{v}\"" } unless new_resource.environment.empty?
          unit
        end
      end
    end
  end
end
