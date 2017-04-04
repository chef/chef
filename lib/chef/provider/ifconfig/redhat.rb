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

class Chef
  class Provider
    class Ifconfig
      class Redhat < Chef::Provider::Ifconfig
        provides :ifconfig, platform_family: %w{fedora rhel amazon}

        def initialize(new_resource, run_context)
          super(new_resource, run_context)
          @config_template = %{
<% if new_resource.device %>DEVICE=<%= new_resource.device %><% end %>
<% if new_resource.onboot == "yes" %>ONBOOT=<%= new_resource.onboot %><% end %>
<% if new_resource.bootproto %>BOOTPROTO=<%= new_resource.bootproto %><% end %>
<% if new_resource.target %>IPADDR=<%= new_resource.target %><% end %>
<% if new_resource.mask %>NETMASK=<%= new_resource.mask %><% end %>
<% if new_resource.network %>NETWORK=<%= new_resource.network %><% end %>
<% if new_resource.bcast %>BROADCAST=<%= new_resource.bcast %><% end %>
<% if new_resource.onparent %>ONPARENT=<%= new_resource.onparent %><% end %>
<% if new_resource.hwaddr %>HWADDR=<%= new_resource.hwaddr %><% end %>
<% if new_resource.metric %>METRIC=<%= new_resource.metric %><% end %>
<% if new_resource.mtu %>MTU=<%= new_resource.mtu %><% end %>
          }
          @config_path = "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}"
        end

      end
    end
  end
end
