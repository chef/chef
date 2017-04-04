#
# Author:: Nathan Williams (<nath.e.will@gmail.com>)
# Copyright:: Copyright 2016, Nathan Williams
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

require "chef/resource"
require "iniparse"

class Chef
  class Resource
    class SystemdUnit < Chef::Resource
      resource_name :systemd_unit

      default_action :nothing
      allowed_actions :create, :delete,
                      :enable, :disable,
                      :mask, :unmask,
                      :start, :stop,
                      :restart, :reload,
                      :try_restart, :reload_or_restart,
                      :reload_or_try_restart

      # Internal provider-managed properties
      property :enabled, [TrueClass, FalseClass]
      property :active, [TrueClass, FalseClass]
      property :masked, [TrueClass, FalseClass]
      property :static, [TrueClass, FalseClass]

      # User-provided properties
      property :user, String, desired_state: false
      property :content, [String, Hash]
      property :triggers_reload, [TrueClass, FalseClass],
                                 default: true, desired_state: false
      property :verify, [TrueClass, FalseClass],
                        default: true, desired_state: false

      def to_ini
        case content
        when Hash
          IniParse.gen do |doc|
            content.each_pair do |sect, opts|
              doc.section(sect) do |section|
                opts.each_pair do |opt, val|
                  section.option(opt, val)
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
