#
# Author:: Jason K. Jackson (jasonjackson@gmail.com)
# Copyright:: Copyright 2009-2016, Jason K. Jackson
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

require "chef/log"
require "chef/mixin/shell_out"
require "chef/provider"
require "chef/resource/file"
require "chef/exceptions"
require "erb"

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
      provides :ifconfig

      include Chef::Mixin::ShellOut

      attr_accessor :config_template
      attr_accessor :config_path

      def initialize(new_resource, run_context)
        super(new_resource, run_context)
        @config_template = nil
        @config_path = nil
      end

      def load_current_resource
        @current_resource = Chef::Resource::Ifconfig.new(new_resource.name)

        @ifconfig_success = true
        @interfaces = {}

        @status = shell_out("ifconfig")
        @status.stdout.each_line do |line|
          if !line[0..9].strip.empty?
            @int_name = line[0..9].strip
            @interfaces[@int_name] = { "hwaddr" => (line =~ /(HWaddr)/ ? ($') : "nil").strip.chomp }
          else
            @interfaces[@int_name]["inet_addr"] = (line =~ /inet addr:(\S+)/ ? Regexp.last_match(1) : "nil") if line =~ /inet addr:/
            @interfaces[@int_name]["bcast"] = (line =~ /Bcast:(\S+)/ ? Regexp.last_match(1) : "nil") if line =~ /Bcast:/
            @interfaces[@int_name]["mask"] = (line =~ /Mask:(\S+)/ ? Regexp.last_match(1) : "nil") if line =~ /Mask:/
            @interfaces[@int_name]["mtu"] = (line =~ /MTU:(\S+)/ ? Regexp.last_match(1) : "nil") if line =~ /MTU:/
            @interfaces[@int_name]["metric"] = (line =~ /Metric:(\S+)/ ? Regexp.last_match(1) : "nil") if line =~ /Metric:/
          end

          next unless @interfaces.key?(new_resource.device)
          @interface = @interfaces.fetch(new_resource.device)

          current_resource.target(new_resource.target)
          current_resource.device(new_resource.device)
          current_resource.inet_addr(@interface["inet_addr"])
          current_resource.hwaddr(@interface["hwaddr"])
          current_resource.bcast(@interface["bcast"])
          current_resource.mask(@interface["mask"])
          current_resource.mtu(@interface["mtu"])
          current_resource.metric(@interface["metric"])
        end
        current_resource
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
        unless current_resource.inet_addr
          unless new_resource.device == loopback_device
            command = add_command
            converge_by("run #{command.join(' ')} to add #{new_resource}") do
              shell_out_compact!(command)
              Chef::Log.info("#{new_resource} added")
            end
          end
        end
        # Write out the config files
        generate_config
      end

      def action_enable
        # check to see if load_current_resource found ifconfig
        # enables, but does not manage config files
        return if current_resource.inet_addr
        return if new_resource.device == loopback_device
        command = enable_command
        converge_by("run #{command.join(' ')} to enable #{new_resource}") do
          shell_out_compact!(command)
          Chef::Log.info("#{new_resource} enabled")
        end
      end

      def action_delete
        # check to see if load_current_resource found the interface
        if current_resource.device
          command = delete_command
          converge_by("run #{command.join(' ')} to delete #{new_resource}") do
            shell_out_compact!(command)
            Chef::Log.info("#{new_resource} deleted")
          end
        else
          Chef::Log.debug("#{new_resource} does not exist - nothing to do")
        end
        delete_config
      end

      def action_disable
        # check to see if load_current_resource found the interface
        # disables, but leaves config files in place.
        if current_resource.device
          command = disable_command
          converge_by("run #{command.join(' ')} to disable #{new_resource}") do
            shell_out_compact!(command)
            Chef::Log.info("#{new_resource} disabled")
          end
        else
          Chef::Log.debug("#{new_resource} does not exist - nothing to do")
        end
      end

      def can_generate_config?
        !@config_template.nil? && !@config_path.nil?
      end

      def resource_for_config(path)
        Chef::Resource::File.new(path, run_context)
      end

      def generate_config
        return unless can_generate_config?
        b = binding
        template = ::ERB.new(@config_template)
        config = resource_for_config(@config_path)
        config.content(template.result(b))
        config.run_action(:create)
        new_resource.updated_by_last_action(true) if config.updated?
      end

      def delete_config
        return unless can_generate_config?
        config = resource_for_config(@config_path)
        config.run_action(:delete)
        new_resource.updated_by_last_action(true) if config.updated?
      end

      private

      def add_command
        command = [ "ifconfig", new_resource.device, new_resource.target ]
        command += [ "netmask", new_resource.mask ] if new_resource.mask
        command += [ "metric", new_resource.metric ] if new_resource.metric
        command += [ "mtu", new_resource.mtu ] if new_resource.mtu
        command
      end

      def enable_command
        command = [ "ifconfig", new_resource.device, new_resource.target ]
        command += [ "netmask", new_resource.mask ] if new_resource.mask
        command += [ "metric", new_resource.metric ] if new_resource.metric
        command += [ "mtu", new_resource.mtu ] if new_resource.mtu
        command
      end

      def disable_command
        [ "ifconfig", new_resource.device, "down" ]
      end

      def delete_command
        [ "ifconfig", new_resource.device, "down" ]
      end

      def loopback_device
        "lo"
      end
    end
  end
end
