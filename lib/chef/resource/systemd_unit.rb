#
# Author:: Nathan Williams (<nath.e.will@gmail.com>)
# Copyright:: Copyright 2016-2018, Nathan Williams
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "iniparse"

class Chef
  class Resource
    class SystemdUnit < Chef::Resource
      unified_mode true

      provides(:systemd_unit) { true }

      description "Use the **systemd_unit** resource to create, manage, and run [systemd units](https://www.freedesktop.org/software/systemd/man/systemd.html#Concepts)."
      introduced "12.11"
      examples <<~DOC
      **Create systemd service unit file from a Hash**

      ```ruby
      systemd_unit 'etcd.service' do
        content(Unit: {
                  Description: 'Etcd',
                  Documentation: ['https://coreos.com/etcd', 'man:etcd(1)'],
                  After: 'network.target',
                },
                Service: {
                  Type: 'notify',
                  ExecStart: '/usr/local/etcd',
                  Restart: 'always',
                },
                Install: {
                  WantedBy: 'multi-user.target',
                })
        action [:create, :enable]
      end
      ```

      **Create systemd service unit file from a String**

      ```ruby
      systemd_unit 'sysstat-collect.timer' do
        content <<~EOU
        [Unit]
        Description=Run system activity accounting tool every 10 minutes

        [Timer]
        OnCalendar=*:00/10

        [Install]
        WantedBy=sysstat.service
        EOU

        action [:create, :enable]
      end
      ```
      DOC

      default_action :nothing
      allowed_actions :create, :delete,
        :preset, :revert,
        :enable, :disable, :reenable,
        :mask, :unmask,
        :start, :stop,
        :restart, :reload,
        :try_restart, :reload_or_restart,
        :reload_or_try_restart

      # Internal provider-managed properties
      property :enabled, [TrueClass, FalseClass], skip_docs: true
      property :active, [TrueClass, FalseClass], skip_docs: true
      property :masked, [TrueClass, FalseClass], skip_docs: true
      property :static, [TrueClass, FalseClass], skip_docs: true
      property :indirect, [TrueClass, FalseClass], skip_docs: true

      # User-provided properties
      property :user, String, desired_state: false,
               description: "The user account that the systemd unit process is run under. The path to the unit for that user would be something like '/etc/systemd/user/sshd.service'. If no user account is specified, the systemd unit will run under a 'system' account, with the path to the unit being something like '/etc/systemd/system/sshd.service'."

      property :content, [String, Hash],
        description: "A string or hash that contains a systemd [unit file](https://www.freedesktop.org/software/systemd/man/systemd.unit.html) definition that describes the properties of systemd-managed entities, such as services, sockets, devices, and so on. In #{ChefUtils::Dist::Infra::PRODUCT} 14.4 or later, repeatable options can be implemented with an array."

      property :triggers_reload, [TrueClass, FalseClass],
        description: "Specifies whether to trigger a daemon reload when creating or deleting a unit.",
        default: true, desired_state: false

      property :verify, [TrueClass, FalseClass],
        default: true, desired_state: false,
        description: "Specifies if the unit will be verified before installation. Systemd can be overly strict when verifying units, so in certain cases it is preferable not to verify the unit."

      property :unit_name, String, desired_state: false,
               name_property: true,
               description: "The name of the unit file if it differs from the resource block's name.",
               introduced: "13.7"

      def to_ini
        case content
        when Hash
          IniParse.gen do |doc|
            content.each_pair do |sect, opts|
              doc.section(sect) do |section|
                opts.each_pair do |opt, val|
                  [val].flatten.each do |v|
                    section.option(opt, v)
                  end
                end
              end
            end
          end.to_s
        else
          content.to_s
        end
      end
    end
  end
end
