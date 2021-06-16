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

require_relative "../log"
require_relative "../provider"
require_relative "../resource/file"
require_relative "../exceptions"
autoload :ERB, "erb"

class Chef
  class Provider
    # use the ifconfig resource to manage interfaces on *nix systems
    #
    # @example set a static ip on eth1
    #   ifconfig '33.33.33.80' do
    #     device 'eth1'
    #   end
    class Ifconfig < Chef::Provider
      provides :ifconfig

      attr_accessor :config_template
      attr_accessor :config_path

      # @api private
      # @return [String] the major.minor of the net-tools version as a string
      attr_accessor :ifconfig_version

      def initialize(new_resource, run_context)
        super(new_resource, run_context)
        @config_template = nil
        @config_path = nil
      end

      def load_current_resource
        @current_resource = Chef::Resource::Ifconfig.new(new_resource.name)

        @ifconfig_success = true
        @interfaces = {}

        @ifconfig_version = nil

        @net_tools_version = shell_out("ifconfig", "--version")
        @net_tools_version.stdout.each_line do |line|
          if /^net-tools (\d+\.\d+)/.match?(line)
            @ifconfig_version = line.match(/^net-tools (\d+\.\d+)/)[1]
          end
        end
        @net_tools_version.stderr.each_line do |line|
          if /^net-tools (\d+\.\d+)/.match?(line)
            @ifconfig_version = line.match(/^net-tools (\d+\.\d+)/)[1]
          end
        end

        if @ifconfig_version.nil?
          raise "net-tools not found - this is required for ifconfig"
        elsif @ifconfig_version.to_i < 2
          # Example output for 1.60 is as follows: (sanitized but format intact)
          # eth0      Link encap:Ethernet  HWaddr 00:00:00:00:00:00
          #           inet addr:192.168.1.1  Bcast:192.168.0.1  Mask:255.255.248.0
          #           inet6 addr: 0000::00:0000:0000:0000/64 Scope:Link
          #           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          #           RX packets:65158911 errors:0 dropped:0 overruns:0 frame:0
          #           TX packets:41723949 errors:0 dropped:0 overruns:0 carrier:0
          #           collisions:0 txqueuelen:1000
          #           RX bytes:42664658792 (39.7 GiB)  TX bytes:52722603938 (49.1 GiB)
          #           Interrupt:30
          @status = shell_out("ifconfig")
          @status.stdout.each_line do |line|
            if !line[0..9].strip.empty?
              @int_name = line[0..9].strip
              @interfaces[@int_name] = { "hwaddr" => (line =~ /(HWaddr)/ ? ($') : "nil").strip.chomp }
            else
              @interfaces[@int_name]["inet_addr"] = (line =~ /inet addr:(\S+)/ ? Regexp.last_match(1) : "nil") if /inet addr:/.match?(line)
              @interfaces[@int_name]["bcast"] = (line =~ /Bcast:(\S+)/ ? Regexp.last_match(1) : "nil") if /Bcast:/.match?(line)
              @interfaces[@int_name]["mask"] = (line =~ /Mask:(\S+)/ ? Regexp.last_match(1) : "nil") if /Mask:/.match?(line)
              @interfaces[@int_name]["mtu"] = (line =~ /MTU:(\S+)/ ? Regexp.last_match(1) : "nil") if /MTU:/.match?(line)
              @interfaces[@int_name]["metric"] = (line =~ /Metric:(\S+)/ ? Regexp.last_match(1) : "nil") if /Metric:/.match?(line)
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
        elsif @ifconfig_version.to_i >= 2
          # Example output for 2.10-alpha is as follows: (sanitized but format intact)
          # eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
          #       inet 192.168.1.1  netmask 255.255.240.0  broadcast 192.168.0.1
          #       inet6 0000::0000:000:0000:0000  prefixlen 64  scopeid 0x20<link>
          #       ether 00:00:00:00:00:00  txqueuelen 1000  (Ethernet)
          #       RX packets 2383836  bytes 1642630840 (1.5 GiB)
          #       RX errors 0  dropped 0  overruns 0  frame 0
          #       TX packets 1244218  bytes 977339327 (932.0 MiB)
          #       TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
          #
          # Permalink for addr_regex : https://rubular.com/r/JrykUpfjRnYeQD
          @status = shell_out("ifconfig")
          @status.stdout.each_line do |line|
            addr_regex = /^((\w|-)+):?(\d*):?\ .+$/
            if line =~ addr_regex
              if line.match(addr_regex).nil?
                @int_name = "nil"
              elsif line.match(addr_regex)[3] == ""
                @int_name = line.match(addr_regex)[1]
                @interfaces[@int_name] = {}
                @interfaces[@int_name]["mtu"] = (line =~ /mtu (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("mtu") && @interfaces[@int_name]["mtu"].nil?
              else
                @int_name = "#{line.match(addr_regex)[1]}:#{line.match(addr_regex)[3]}"
                @interfaces[@int_name] = {}
                @interfaces[@int_name]["mtu"] = (line =~ /mtu (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("mtu") && @interfaces[@int_name]["mtu"].nil?
              end
            else
              @interfaces[@int_name]["inet_addr"] = (line =~ /inet (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("inet") && @interfaces[@int_name]["inet_addr"].nil?
              @interfaces[@int_name]["bcast"] = (line =~ /broadcast (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("broadcast") && @interfaces[@int_name]["bcast"].nil?
              @interfaces[@int_name]["mask"] = (line =~ /netmask (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("netmask") && @interfaces[@int_name]["mask"].nil?
              @interfaces[@int_name]["hwaddr"] = (line =~ /ether (\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("ether") && @interfaces[@int_name]["hwaddr"].nil?
              @interfaces[@int_name]["metric"] = (line =~ /Metric:(\S+)/ ? Regexp.last_match(1) : "nil") if line.include?("Metric:") && @interfaces[@int_name]["metric"].nil?
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

      action :add do
        # check to see if load_current_resource found interface in ifconfig
        unless current_resource.inet_addr
          unless new_resource.device == loopback_device
            command = add_command
            converge_by("run #{command.join(" ")} to add #{new_resource}") do
              shell_out!(command)
              logger.info("#{new_resource} added")
            end
          end
        end
        # Write out the config files
        generate_config
      end

      action :enable do
        # check to see if load_current_resource found ifconfig
        # enables, but does not manage config files
        return if current_resource.inet_addr
        return if new_resource.device == loopback_device

        command = enable_command
        converge_by("run #{command.join(" ")} to enable #{new_resource}") do
          shell_out!(command)
          logger.info("#{new_resource} enabled")
        end
      end

      action :delete do
        # check to see if load_current_resource found the interface
        if current_resource.device
          command = delete_command
          converge_by("run #{command.join(" ")} to delete #{new_resource}") do
            shell_out!(command)
            logger.info("#{new_resource} deleted")
          end
        else
          logger.debug("#{new_resource} does not exist - nothing to do")
        end
        delete_config
      end

      action :disable do
        # check to see if load_current_resource found the interface
        # disables, but leaves config files in place.
        if current_resource.device
          command = disable_command
          converge_by("run #{command.join(" ")} to disable #{new_resource}") do
            shell_out!(command)
            logger.info("#{new_resource} disabled")
          end
        else
          logger.debug("#{new_resource} does not exist - nothing to do")
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
        template = ::ERB.new(@config_template, nil, "-")
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
