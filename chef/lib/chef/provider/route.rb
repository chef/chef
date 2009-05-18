#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

require 'chef/log'
require 'chef/mixin/command'
require 'chef/provider'
require 'erb'

class Chef
  class Provider
    class Route < Chef::Provider
      include Chef::Mixin::Command

      def load_current_resource
        @current_resource = Chef::Resource::Route.new(@new_resource.name)

        Chef::Log.debug("Checking routes for #{@current_resource.target}")
        status = popen4("route -n") do |pid, stdin, stdout, stderr|
          stdout.each do |line|
            case line
            # Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
            when /^#{@new_resource.target}\s+([\d.]+)\s+([\d.]+)\s+(.+)\s+(\d+)\s+(.+)\s+(.+)\s+(\w+)$/
              @current_resource.target(@new_resource.target)
              @current_resource.gateway($1)
              @current_resource.netmask($2)
              @current_resource.metric($4.to_i)
              @current_resource.device($7)
              Chef::Log.debug("Found route ip:#{@current_resource.target} gw:#{@current_resource.gateway} nm:#{@current_resource.netmask} " +
                  "metric:#{@current_resource.metric} dev:#{@current_resource.device}")
            end
          end
        end

        unless status.exitstatus == 0
          raise Chef::Exception::Route, "route failed - #{status.inspect}!"
        end

        @current_resource
      end

      def action_add
        # check to see if load_current_resource found the route
        unless @current_resource.gateway
          if @new_resource.route_type == :net
            command = "route add -net #{@new_resource.target}"
          else
            command = "route add #{@new_resource.target}"
          end
          command << " netmask #{@new_resource.netmask}" if @new_resource.netmask
          command << " gw #{@new_resource.gateway}" if @new_resource.gateway
          command << " metric #{@new_resource.metric}" if @new_resource.metric
          command << " dev #{@new_resource.device}" if @new_resource.device
  
          run_command(
            :command => command
          )
          @new_resource.updated = true
        else
          Chef::Log.debug("Route #{@current_resource} already exists")
        end
        # Write out the config files
        generate_config
      end

      def action_delete
        # check to see if load_current_resource found the route
        if @current_resource.gateway 
          command = "route del #{@new_resource.target}"
          command << " netmask #{@new_resource.netmask}" if @new_resource.netmask
          command << " gw #{@new_resource.gateway}" if @new_resource.gateway
          command << " metric #{@new_resource.metric}" if @new_resource.metric
          command << " dev #{@new_resource.device}" if @new_resource.device
  
          run_command(
            :command => command
          )
          @new_resource.updated = true
        else
          Chef::Log.debug("Route #{@current_resource} does not exist")
        end
      end

      def generate_config
        b = binding
        case node[:platform]
        when ("centos" || "redhat" || "fedora")
          content = %{
<% if @new_resource.networking %>NETWORKING=<%= @new_resource.networking %><% end %>
<% if @new_resource.networking_ipv6 %>NETWORKING_IPV6=<%= @new_resource.networking_ipv6 %><% end %>
<% if @new_resource.hostname %>HOSTNAME=<%= @new_resource.hostname %><% end %>
<% if @new_resource.name %>GATEWAY=<%= @new_resource.name %><% end %>
<% if @new_resource.domainname %>DOMAINNAME=<%= @new_resource.domainname %><% end %>
<% if @new_resource.domainname %>DOMAIN=<%= @new_resource.domainname %><% end %>
          }
          template = ::ERB.new(content)
          network_file = ::File.new("/etc/sysconfig/network", "w")
          network_file.puts(template.result(b))
          network_file.close
        end
      end    
    end
  end
end
