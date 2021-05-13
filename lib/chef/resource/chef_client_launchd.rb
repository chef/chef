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
    class ChefClientLaunchd < Chef::Resource
      unified_mode true

      provides :chef_client_launchd

      description "Use the **chef_client_launchd** resource to configure the #{ChefUtils::Dist::Infra::PRODUCT} to run on a schedule on macOS systems."
      introduced "16.5"
      examples <<~DOC
        **Set the #{ChefUtils::Dist::Infra::PRODUCT} to run on a schedule**:

        ```ruby
        chef_client_launchd 'Setup the #{ChefUtils::Dist::Infra::PRODUCT} to run every 30 minutes' do
          interval 30
          action :enable
        end
        ```

        **Disable the #{ChefUtils::Dist::Infra::PRODUCT} running on a schedule**:

        ```ruby
        chef_client_launchd 'Prevent the #{ChefUtils::Dist::Infra::PRODUCT} from running on a schedule' do
          action :disable
        end
        ```
      DOC

      property :user, String,
        description: "The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as.",
        default: "root"

      property :working_directory, String,
        description: "The working directory to run the #{ChefUtils::Dist::Infra::PRODUCT} from.",
        default: "/var/root"

      property :interval, [Integer, String],
        description: "Time in minutes between #{ChefUtils::Dist::Infra::PRODUCT} executions.",
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be a positive number" => proc { |v| v > 0 } },
        default: 30

      property :splay, [Integer, String],
        default: 300,
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be a positive number" => proc { |v| v > 0 } },
        description: "A random number of seconds between 0 and X to add to interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time."

      property :accept_chef_license, [true, false],
        description: "Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement/>",
        default: false

      property :config_directory, String,
        description: "The path of the config directory.",
        default: ChefConfig::Config.etc_chef_dir

      property :log_directory, String,
        description: "The path of the directory to create the log file in.",
        default: "/Library/Logs/Chef"

      property :log_file_name, String,
        description: "The name of the log file to use.",
        default: "client.log"

      property :chef_binary_path, String,
        description: "The path to the #{ChefUtils::Dist::Infra::CLIENT} binary.",
        default: "/opt/#{ChefUtils::Dist::Infra::DIR_SUFFIX}/bin/#{ChefUtils::Dist::Infra::CLIENT}"

      property :daemon_options, Array,
        description: "An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command.",
        default: []

      property :environment, Hash,
        description: "A Hash containing additional arbitrary environment variables under which the launchd daemon will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`.",
        default: {}

      property :nice, [Integer, String],
        description: "The process priority to run the #{ChefUtils::Dist::Infra::CLIENT} process at. A value of -20 is the highest priority and 19 is the lowest priority.",
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be an Integer between -20 and 19" => proc { |v| v >= -20 && v <= 19 } }

      property :low_priority_io, [true, false],
        description: "Run the #{ChefUtils::Dist::Infra::CLIENT} process with low priority disk IO",
        default: true

      action :enable, description: "Enable running #{ChefUtils::Dist::Infra::PRODUCT} on a schedule using launchd." do
        unless ::Dir.exist?(new_resource.log_directory)
          directory new_resource.log_directory do
            owner new_resource.user
            mode "0750"
            recursive true
          end
        end

        launchd "com.#{ChefUtils::Dist::Infra::SHORT}.#{ChefUtils::Dist::Infra::CLIENT}" do
          username new_resource.user
          working_directory new_resource.working_directory
          start_interval new_resource.interval * 60
          program_arguments ["/bin/bash", "-c", client_command]
          environment_variables new_resource.environment unless new_resource.environment.empty?
          nice new_resource.nice
          low_priority_io true
          notifies :sleep, "chef_sleep[Sleep before client restart]", :immediately
          action :create # create only creates the file. No service restart triggering
        end

        # Launchd doesn't have the concept of a reload aka restart. Instead to update a daemon config you have
        # to unload it and then reload the new plist. That's usually fine, but not if chef-client is trying
        # to restart itself. If the chef-client process uses launchd or macosx_service resources to restart itself
        # we'll end up with a stopped service that will never get started back up. Instead we use this daemon
        # that triggers when the chef-client plist file is updated, and handles the restart outside the run.
        launchd "com.#{ChefUtils::Dist::Infra::SHORT}.restarter" do
          username "root"
          watch_paths ["/Library/LaunchDaemons/com.#{ChefUtils::Dist::Infra::SHORT}.#{ChefUtils::Dist::Infra::CLIENT}.plist"]
          standard_out_path ::File.join(new_resource.log_directory, new_resource.log_file_name)
          standard_error_path ::File.join(new_resource.log_directory, new_resource.log_file_name)
          program_arguments ["/bin/bash",
                             "-c",
                             "echo; echo #{ChefUtils::Dist::Infra::PRODUCT} launchd daemon config has been updated. Manually unloading and reloading the daemon; echo Now unloading the daemon; /bin/launchctl unload /Library/LaunchDaemons/com.#{ChefUtils::Dist::Infra::SHORT}.#{ChefUtils::Dist::Infra::CLIENT}.plist; sleep 2; echo Now loading the daemon; /bin/launchctl load /Library/LaunchDaemons/com.#{ChefUtils::Dist::Infra::SHORT}.#{ChefUtils::Dist::Infra::CLIENT}.plist"]
          action :enable # enable creates the plist & triggers service restarts on change
        end

        # We want to make sure that after we update the chef-client launchd config that we don't move on to another recipe
        # before the restarter daemon can do its thing. This sleep avoids killing the client while it's doing something like
        # installing a package, which could be problematic. It also makes it a bit more clear in the log that the killed process
        # was intentional.
        chef_sleep "Sleep before client restart" do
          seconds 10
          action :nothing
        end
      end

      action :disable, description: "Disable running #{ChefUtils::Dist::Infra::PRODUCT} on a schedule using launchd" do
        service ChefUtils::Dist::Infra::PRODUCT do
          service_name "com.#{ChefUtils::Dist::Infra::SHORT}.#{ChefUtils::Dist::Infra::CLIENT}"
          action :disable
        end

        service "com.#{ChefUtils::Dist::Infra::SHORT}.restarter" do
          action :disable
        end
      end

      action_class do
        #
        # Generate a uniformly distributed unique number to sleep from 0 to the splay time
        #
        # @param [Integer] splay The number of seconds to splay
        #
        # @return [Integer]
        #
        def splay_sleep_time(splay)
          seed = node["shard_seed"] || Digest::MD5.hexdigest(node.name).to_s.hex
          random = Random.new(seed.to_i)
          random.rand(splay)
        end

        #
        # random sleep time + chef-client + daemon option properties + license acceptance
        #
        # @return [String]
        #
        def client_command
          cmd = ""
          cmd << "/bin/sleep #{splay_sleep_time(new_resource.splay)};"
          cmd << " #{new_resource.chef_binary_path}"
          cmd << " #{new_resource.daemon_options.join(" ")}" unless new_resource.daemon_options.empty?
          cmd << " -c #{::File.join(new_resource.config_directory, "client.rb")}"
          cmd << " -L #{::File.join(new_resource.log_directory, new_resource.log_file_name)}"
          cmd << " --chef-license accept" if new_resource.accept_chef_license
          cmd
        end
      end
    end
  end
end
