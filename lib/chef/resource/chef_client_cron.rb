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

class Chef
  class Resource
    class ChefClientCron < Chef::Resource
      unified_mode true

      provides :chef_client_cron

      description "Use the chef_client_cron resource to setup the Chef Infra Client to run as a cron job."
      introduced "16.0"

      property :user, String, default: 'root'

      property :minute, [String, Integer], default: '0,30'
      property :hour, [String, Integer], default: '*'
      property :weekday, [String, Integer], default: '*'
      property :mailto, String

      property :job_name, String, default: 'chef-client'
      property :splay, [Integer, String], default: 300

      property :env_vars, Hash

      property :config_directory, String, default: '/etc/chef'
      property :log_directory, String, default: lazy { platform?('mac_os_x') ? '/Library/Logs/Chef' : '/var/log/chef' }
      property :log_file_name, String, default: 'client.log'
      property :append_log_file, [true, false], default: false
      property :chef_binary_path, String, default: '/opt/chef/bin/chef-client'
      property :daemon_options, Array, default: []

      action :add do
        cron_d new_resource.job_name do
          minute  new_resource.minute
          hour    new_resource.hour
          weekday new_resource.weekday
          mailto  new_resource.mailto if new_resource.mailto
          user    new_resource.user
          command cron_command
        end
      end

      action :remove do
        cron_d new_resource.job_name do
          action :delete
        end
      end

      action_class do
        def cron_command
          cmd = ''
          cmd << "/bin/sleep #{splay_sleep_time(new_resource.splay)}; "
          cmd << "#{new_resource.env_vars} " if new_resource.env_vars
          cmd << "#{new_resource.chef_binary_path} #{new_resource.daemon_options.join(' ')}"
          cmd << " #{new_resource.append_log_file ? '>>' : '>'} #{::File.join(new_resource.log_directory, new_resource.log_file_name)} 2>&1"
          cmd << ' || echo "Chef Infra Client execution failed"' if new_resource.mailto
          cmd
        end
      end
    end
  end
end
