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
require_relative "helpers/cron_validations"
require "digest/md5" unless defined?(Digest::MD5)

class Chef
  class Resource
    class ChefClientCron < Chef::Resource
      unified_mode true

      provides :chef_client_cron

      description "Use the **chef_client_cron** resource to setup the #{ChefUtils::Dist::Infra::PRODUCT} to run as a cron job. This resource will also create the specified log directory if it doesn't already exist."
      introduced "16.0"
      examples <<~DOC
      **Setup #{ChefUtils::Dist::Infra::PRODUCT} to run using the default 30 minute cadence**:

      ```ruby
      chef_client_cron 'Run #{ChefUtils::Dist::Infra::PRODUCT} as a cron job'
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} twice a day**:

      ```ruby
      chef_client_cron 'Run #{ChefUtils::Dist::Infra::PRODUCT} every 12 hours' do
        minute 0
        hour '0,12'
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with extra options passed to the client**:

      ```ruby
      chef_client_cron 'Run an override recipe' do
        daemon_options ['--override-runlist mycorp_base::default']
      end
      ```
      DOC

      extend Chef::ResourceHelpers::CronValidations

      property :job_name, String,
        default: ChefUtils::Dist::Infra::CLIENT,
        description: "The name of the cron job to create."

      property :comment, String,
        description: "A comment to place in the cron.d file."

      property :user, String,
        description: "The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as.",
        default: "root"

      property :minute, [Integer, String],
        description: "The minute at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0 - 59) or a cron pattern such as '0,30'.",
        default: "0,30", callbacks: {
          "should be a valid minute spec" => method(:validate_minute),
        }

      property :hour, [Integer, String],
        description: "The hour at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0 - 23) or a cron pattern such as '0,12'.",
        default: "*", callbacks: {
          "should be a valid hour spec" => method(:validate_hour),
        }

      property :day, [Integer, String],
        description: "The day of month at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (1 - 31) or a cron pattern such as '1,7,14,21,28'.",
        default: "*", callbacks: {
          "should be a valid day spec" => method(:validate_day),
        }

      property :month, [Integer, String],
        description: "The month in the year on which #{ChefUtils::Dist::Infra::PRODUCT} is to run (1 - 12, jan-dec, or *).",
        default: "*", callbacks: {
          "should be a valid month spec" => method(:validate_month),
        }

      property :weekday, [Integer, String],
        description: "The day of the week on which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0-7, mon-sun, or *), where Sunday is both 0 and 7.",
        default: "*", callbacks: {
          "should be a valid weekday spec" => method(:validate_dow),
        }

      property :splay, [Integer, String],
        default: 300,
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be a positive number" => proc { |v| v > 0 } },
        description: "A random number of seconds between 0 and X to add to interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time."

      property :mailto, String,
        description: "The e-mail address to e-mail any cron task failures to."

      property :accept_chef_license, [true, false],
        description: "Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement/>",
        default: false

      property :config_directory, String,
        default: ChefConfig::Config.etc_chef_dir,
        description: "The path of the config directory."

      property :log_directory, String,
        default: lazy { platform?("mac_os_x") ? "/Library/Logs/#{ChefUtils::Dist::Infra::DIR_SUFFIX.capitalize}" : "/var/log/#{ChefUtils::Dist::Infra::DIR_SUFFIX}" },
        default_description: "/Library/Logs/#{ChefUtils::Dist::Infra::DIR_SUFFIX.capitalize} on macOS and /var/log/#{ChefUtils::Dist::Infra::DIR_SUFFIX} otherwise",
        description: "The path of the directory to create the log file in."

      property :log_file_name, String,
        default: "client.log",
        description: "The name of the log file to use."

      property :append_log_file, [true, false],
        default: true,
        description: "Append to the log file instead of overwriting the log file on each run."

      property :chef_binary_path, String,
        default: "/opt/#{ChefUtils::Dist::Infra::DIR_SUFFIX}/bin/#{ChefUtils::Dist::Infra::CLIENT}",
        description: "The path to the #{ChefUtils::Dist::Infra::CLIENT} binary."

      property :daemon_options, Array,
        default: [],
        description: "An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command."

      property :environment, Hash,
        default: {},
        description: "A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`."

      property :nice, [Integer, String],
        description: "The process priority to run the #{ChefUtils::Dist::Infra::CLIENT} process at. A value of -20 is the highest priority and 19 is the lowest priority.",
        introduced: "16.5",
        coerce: proc { |x| Integer(x) },
        callbacks: { "should be an Integer between -20 and 19" => proc { |v| v >= -20 && v <= 19 } }

      action :add, description: "Add a cron job to run #{ChefUtils::Dist::Infra::PRODUCT}." do
        # TODO: Replace this with a :create_if_missing action on directory when that exists
        unless ::Dir.exist?(new_resource.log_directory)
          directory new_resource.log_directory do
            owner new_resource.user
            mode "0750"
            recursive true
          end
        end

        declare_resource(cron_resource_type, new_resource.job_name) do
          minute new_resource.minute
          hour        new_resource.hour
          day         new_resource.day
          weekday     new_resource.weekday
          month       new_resource.month
          environment new_resource.environment
          mailto      new_resource.mailto if new_resource.mailto
          user        new_resource.user
          comment     new_resource.comment if new_resource.comment
          command     client_command
        end
      end

      action :remove, description: "Remove a cron job for #{ChefUtils::Dist::Infra::PRODUCT}." do
        declare_resource(cron_resource_type, new_resource.job_name) do
          action :delete
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
        # The complete cron command to run
        #
        # @return [String]
        #
        def client_command
          cmd = ""
          cmd << "/bin/sleep #{splay_sleep_time(new_resource.splay)}; "
          cmd << "#{which("nice")} -n #{new_resource.nice} " if new_resource.nice
          cmd << "#{new_resource.chef_binary_path} "
          cmd << "#{new_resource.daemon_options.join(" ")} " unless new_resource.daemon_options.empty?
          cmd << "-c #{::File.join(new_resource.config_directory, "client.rb")} "
          cmd << "--chef-license accept " if new_resource.accept_chef_license
          cmd << log_command
          cmd << " || echo \"#{ChefUtils::Dist::Infra::PRODUCT} execution failed\"" if new_resource.mailto
          cmd
        end

        #
        # The portion of the overall cron job that handles logging based on the append_log_file property
        #
        # @return [String]
        #
        def log_command
          if new_resource.append_log_file
            ">> #{::File.join(new_resource.log_directory, new_resource.log_file_name)} 2>&1"
          else
            "> #{::File.join(new_resource.log_directory, new_resource.log_file_name)} 2>&1"
          end
        end

        #
        # The type of cron resource to run. Linux systems all support the /etc/cron.d directory
        # and can use the cron_d resource, but Solaris / AIX / FreeBSD need to use the crontab
        # via the legacy cron resource.
        #
        # @return [Symbol]
        #
        def cron_resource_type
          linux? ? :cron_d : :cron
        end
      end
    end
  end
end
