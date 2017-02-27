#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright 2013-2016, Onddo Labs, SL.
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

require "chef/provider/ifconfig"
require "chef/util/file_edit"

class Chef
  class Provider
    class Ifconfig
      class Debian < Chef::Provider::Ifconfig
        provides :ifconfig, platform: %w{ubuntu}, platform_version: ">= 11.10"
        provides :ifconfig, platform: %w{debian}, platform_version: ">= 7.0"

        INTERFACES_FILE = "/etc/network/interfaces".freeze
        INTERFACES_DOT_D_DIR = "/etc/network/interfaces.d".freeze

        def initialize(new_resource, run_context)
          super(new_resource, run_context)
          @config_template = %{
<% if new_resource.device %>
<% if new_resource.onboot == "yes" %>auto <%= new_resource.device %><% end %>
<% case new_resource.bootproto
   when "dhcp" %>
iface <%= new_resource.device %> inet dhcp
<% when "bootp" %>
iface <%= new_resource.device %> inet bootp
<% else %>
iface <%= new_resource.device %> inet static
    <% if new_resource.target %>address <%= new_resource.target %><% end %>
    <% if new_resource.mask %>netmask <%= new_resource.mask %><% end %>
    <% if new_resource.network %>network <%= new_resource.network %><% end %>
    <% if new_resource.bcast %>broadcast <%= new_resource.bcast %><% end %>
    <% if new_resource.metric %>metric <%= new_resource.metric %><% end %>
    <% if new_resource.hwaddr %>hwaddress <%= new_resource.hwaddr %><% end %>
    <% if new_resource.mtu %>mtu <%= new_resource.mtu %><% end %>
<% end %>
<% end %>
          }
          @config_path = "#{INTERFACES_DOT_D_DIR}/ifcfg-#{new_resource.device}"
        end

        def generate_config
          enforce_interfaces_dot_d_sanity
          super
        end

        protected

        def enforce_interfaces_dot_d_sanity
          # create /etc/network/interfaces.d via dir resource (to get reporting, etc)
          dir = Chef::Resource::Directory.new(INTERFACES_DOT_D_DIR, run_context)
          dir.run_action(:create)
          new_resource.updated_by_last_action(true) if dir.updated_by_last_action?
          # roll our own file_edit resource, this will not get reported until we have a file_edit resource
          interfaces_dot_d_for_regexp = INTERFACES_DOT_D_DIR.gsub(/\./, '\.') # escape dots for the regexp
          regexp = %r{^\s*source\s+#{interfaces_dot_d_for_regexp}/\*\s*$}

          return if ::File.exist?(INTERFACES_FILE) && regexp.match(IO.read(INTERFACES_FILE))

          converge_by("modifying #{INTERFACES_FILE} to source #{INTERFACES_DOT_D_DIR}") do
            conf = Chef::Util::FileEdit.new(INTERFACES_FILE)
            conf.insert_line_if_no_match(regexp, "source #{INTERFACES_DOT_D_DIR}/*")
            conf.write_file
          end
        end

      end
    end
  end
end
