#
# Author:: Jason K. Jackson (jasonjackson@gmail.com)
# Copyright:: Copyright (c) 2009 Jason K. Jackson
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
require 'chef/exceptions'
require 'erb'

#  Recipe example:
#
#    int = {Hash with your network settings...}
#
#    ifconfig  int['ip'] do 
#      ignore_failure  true 
#      device  int['dev'] 
#      mask    int['mask']  
#      gateway int['gateway'] 
#      mtu     int['mtu']
#    end

class Chef
  class Provider
    class Ifconfig < Chef::Provider
      include Chef::Mixin::Command

      def whyrun_supported?
        true
      end

      def load_current_resource
        @current_resource = Chef::Resource::Ifconfig.new(@new_resource.name)

        @ifconfig_success = true
        @interfaces = {}

        @status = popen4("ifconfig") do |pid, stdin, stdout, stderr|
          stdout.each do |line|

            if !line[0..9].strip.empty?
              @int_name = line[0..9].strip
              @interfaces[@int_name] = {"hwaddr" => (line =~ /(HWaddr)/ ? ($') : "nil").strip.chomp }
            else
              @interfaces[@int_name]["inet_addr"] = (line =~ /inet addr:(\S+)/ ? ($1) : "nil") if line =~ /inet addr:/
              @interfaces[@int_name]["bcast"] = (line =~ /Bcast:(\S+)/ ? ($1) : "nil") if line =~ /Bcast:/
              @interfaces[@int_name]["mask"] = (line =~ /Mask:(\S+)/ ? ($1) : "nil") if line =~ /Mask:/
              @interfaces[@int_name]["mtu"] = (line =~ /MTU:(\S+)/ ? ($1) : "nil") if line =~ /MTU:/
              @interfaces[@int_name]["metric"] = (line =~ /Metric:(\S+)/ ? ($1) : "nil") if line =~ /Metric:/
            end

            if @interfaces.has_key?(@new_resource.device)
              @interface = @interfaces.fetch(@new_resource.device)

              @current_resource.target(@new_resource.target)
              @current_resource.device(@int_name)
              @current_resource.inet_addr(@interface["inet_addr"])
              @current_resource.hwaddr(@interface["hwaddr"])
              @current_resource.bcast(@interface["bcast"])
              @current_resource.mask(@interface["mask"])
              @current_resource.mtu(@interface["mtu"])
              @current_resource.metric(@interface["metric"])
            end
          end
        end
        @current_resource
      end

      def define_resource_requirements 
        requirements.assert(:all_actions) do |a| 
          a.assertion { @status.exitstatus == 0 }
          a.failure_message Chef::Exceptions::Ifconfig, "ifconfig failed - #{@status.inspect}!"
          # no whyrun - if the base ifconfig used in load_current_resource fails
          # there's no reasonable action that could have been taken in the course of 
          # a chef run to fix it.
        end
      end

      def action_add
        # check to see if load_current_resource found interface in ifconfig
        unless @current_resource.inet_addr
          unless @new_resource.device == "lo"
            command = "ifconfig #{@new_resource.device} #{@new_resource.name}"
            command << " netmask #{@new_resource.mask}" if @new_resource.mask
            command << " metric #{@new_resource.metric}" if @new_resource.metric
            command << " mtu #{@new_resource.mtu}" if @new_resource.mtu
          end
          converge_by ("run #{command} to add #{@new_resource}") do
            run_command(
              :command => command
            )
            Chef::Log.info("#{@new_resource} added")
          end
        end

        # Write out the config files
        generate_config
      end

      def action_enable
        # check to see if load_current_resource found ifconfig
        # enables, but does not manage config files
        unless @current_resource.inet_addr
          unless @new_resource.device == "lo"
            command = "ifconfig #{@new_resource.device} #{@new_resource.name}"
            command << " netmask #{@new_resource.mask}" if @new_resource.mask
            command << " metric #{@new_resource.metric}" if @new_resource.metric
            command << " mtu #{@new_resource.mtu}" if @new_resource.mtu
          end

          converge_by ("run #{command} to enable #{@new_resource}") do
            run_command(
              :command => command
            )
            Chef::Log.info("#{@new_resource} enabled")
          end
        end
      end

      def action_delete
        # check to see if load_current_resource found the interface
        if @current_resource.device
          command = "ifconfig #{@new_resource.device} down"
          converge_by ("run #{command} to delete #{@new_resource}") do
            run_command(
              :command => command
            )
            delete_config
            Chef::Log.info("#{@new_resource} deleted")
          end
        else
          Chef::Log.debug("#{@new_resource} does not exist - nothing to do")
        end
      end

      def action_disable
        # check to see if load_current_resource found the interface
        # disables, but leaves config files in place.
        if @current_resource.device
          command = "ifconfig #{@new_resource.device} down"
          converge_by ("run #{command} to disable #{@new_resource}") do
            run_command(
              :command => command
            )
            Chef::Log.info("#{@new_resource} disabled")
          end
        else
          Chef::Log.debug("#{@new_resource} does not exist - nothing to do")
        end
      end

      def generate_config
        b = binding
        case node[:platform]
        when "centos","redhat","fedora"
          content = %{
<% if @new_resource.device %>DEVICE=<%= @new_resource.device %><% end %>
<% if @new_resource.onboot %>ONBOOT=<%= @new_resource.onboot %><% end %>
<% if @new_resource.bootproto %>BOOTPROTO=<%= @new_resource.bootproto %><% end %>
<% if @new_resource.target %>IPADDR=<%= @new_resource.target %><% end %>
<% if @new_resource.mask %>NETMASK=<%= @new_resource.mask %><% end %>
<% if @new_resource.network %>NETWORK=<%= @new_resource.network %><% end %>
<% if @new_resource.bcast %>BROADCAST=<%= @new_resource.bcast %><% end %>
<% if @new_resource.onparent %>ONPARENT=<%= @new_resource.onparent %><% end %>
          }
          template = ::ERB.new(content)
          network_file_name = "/etc/sysconfig/network-scripts/ifcfg-#{@new_resource.device}"
          converge_by ("generate configuration file : #{network_file_name}") do
            network_file = ::File.new(network_file_name, "w")
            network_file.puts(template.result(b))
            network_file.close
          end
          Chef::Log.info("#{@new_resource} created configuration file")
        when "debian","ubuntu"
          # template
        when "slackware"
          # template
        end
      end

      def delete_config
        require 'fileutils'
        case node[:platform]
        when "centos","redhat","fedora"
          ifcfg_file = "/etc/sysconfig/network-scripts/ifcfg-#{@new_resource.device}"
          if ::File.exist?(ifcfg_file)
            converge_by ("delete the #{ifcfg_file}") do
              FileUtils.rm_f(ifcfg_file, :verbose => false)
            end
          end
        when "debian","ubuntu"
          # delete configs
        when "slackware"
          # delete configs
        end
      end

    end
  end
end
