#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
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

require 'chef/provider/ifconfig'
require 'chef/util/file_edit'

class Chef
  class Provider
    class Ifconfig
      class Debian < Chef::Provider::Ifconfig

        def initialize(new_resource, run_context)
          super(new_resource, run_context)
          @config_template = %{
<% if @new_resource.device %>
<% if @new_resource.onboot == "yes" %>auto <%= @new_resource.device %><% end %>
<% case @new_resource.bootproto
   when "dhcp" %>
iface <%= @new_resource.device %> inet dhcp
<% when "bootp" %>
iface <%= @new_resource.device %> inet bootp
<% else %>
iface <%= @new_resource.device %> inet static
    <% if @new_resource.target %>address <%= @new_resource.target %><% end %>
    <% if @new_resource.mask %>netmask <%= @new_resource.mask %><% end %>
    <% if @new_resource.network %>network <%= @new_resource.network %><% end %>
    <% if @new_resource.bcast %>broadcast <%= @new_resource.bcast %><% end %>
    <% if @new_resource.metric %>metric <%= @new_resource.metric %><% end %>
    <% if @new_resource.hwaddr %>hwaddress <%= @new_resource.hwaddr %><% end %>
    <% if @new_resource.mtu %>mtu <%= @new_resource.mtu %><% end %>
<% end %>
<% end %>
          }
          @config_path = "/etc/network/interfaces.d/ifcfg-#{@new_resource.device}"
        end

        def generate_config
          check_interfaces_config
          super
        end

        protected

        def check_interfaces_config
          converge_by ('modify configuration file : /etc/network/interfaces') do
            Dir.mkdir('/etc/network/interfaces.d') unless ::File.directory?('/etc/network/interfaces.d')
            conf = Chef::Util::FileEdit.new('/etc/network/interfaces')
            conf.insert_line_if_no_match('^\s*source\s+/etc/network/interfaces[.]d/[*]\s*$', 'source /etc/network/interfaces.d/*')
            conf.write_file
          end
        end

      end
    end
  end
end
