#
# Author:: Bryan McLellan (btm@loftninjas.org), Jesse Nelson (spheromak@gmail.com)
# Copyright:: Copyright 2009-2016, Bryan McLellan
# Copyright:: Copyright (c) Chef Software Inc.
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
autoload :IPAddr, "ipaddr"

class Chef
  class Provider
    class Route < Chef::Provider

      provides :route

      attr_accessor :is_running

      MASK = { "0.0.0.0" => "0",
               "128.0.0.0" => "1",
               "192.0.0.0" => "2",
               "224.0.0.0" => "3",
               "240.0.0.0" => "4",
               "248.0.0.0" => "5",
               "252.0.0.0" => "6",
               "254.0.0.0" => "7",
               "255.0.0.0" => "8",
               "255.128.0.0" => "9",
               "255.192.0.0" => "10",
               "255.224.0.0" => "11",
               "255.240.0.0" => "12",
               "255.248.0.0" => "13",
               "255.252.0.0" => "14",
               "255.254.0.0" => "15",
               "255.255.0.0" => "16",
               "255.255.128.0" => "17",
               "255.255.192.0" => "18",
               "255.255.224.0" => "19",
               "255.255.240.0" => "20",
               "255.255.248.0" => "21",
               "255.255.252.0" => "22",
               "255.255.254.0" => "23",
               "255.255.255.0" => "24",
               "255.255.255.128" => "25",
               "255.255.255.192" => "26",
               "255.255.255.224" => "27",
               "255.255.255.240" => "28",
               "255.255.255.248" => "29",
               "255.255.255.252" => "30",
               "255.255.255.254" => "31",
               "255.255.255.255" => "32" }.freeze

      def hex2ip(hex_data)
        # Cleanup hex data
        hex_ip = hex_data.to_s.downcase.gsub(/[^0-9a-f]/, "")

        # Check hex data format (IP is a 32bit integer, so should be 8 chars long)
        return nil if hex_ip.length != hex_data.length || hex_ip.length != 8

        # Extract octets from hex data
        octets = hex_ip.scan(/../).reverse.collect { |octet| [octet].pack("H2").unpack("C").first }

        # Validate IP
        ip = octets.join(".")
        begin
          IPAddr.new(ip, Socket::AF_INET).to_s
        rescue ArgumentError
          logger.trace("Invalid IP address data: hex=#{hex_ip}, ip=#{ip}")
          nil
        end
      end

      def load_current_resource
        self.is_running = false

        # cidr or quad dot mask
        new_ip = if new_resource.target == "default"
                   IPAddr.new(new_resource.gateway)
                 elsif new_resource.netmask
                   IPAddr.new("#{new_resource.target}/#{new_resource.netmask}")
                 else
                   IPAddr.new(new_resource.target)
                 end

        # For linux, we use /proc/net/route file to read proc table info
        return unless linux?

        route_file = ::File.open("/proc/net/route", "r")

        # Read all routes
        while (line = route_file.gets)
          # Get all the fields for a route
          _, destination, gateway, _, _, _, _, mask = line.split

          # Convert hex-encoded values to quad-dotted notation (e.g. 0064A8C0 => 192.168.100.0)
          destination = hex2ip(destination)
          gateway = hex2ip(gateway)
          mask = hex2ip(mask)

          # Skip formatting lines (header, etc)
          next unless destination && gateway && mask

          logger.trace("#{new_resource} system has route: dest=#{destination} mask=#{mask} gw=#{gateway}")

          # check if what were trying to configure is already there
          # use an ipaddr object with ip/mask this way we can have
          # a new resource be in cidr format (i don't feel like
          # expanding bitmask by hand.
          #
          running_ip = IPAddr.new("#{destination}/#{mask}")
          logger.trace("#{new_resource} new ip: #{new_ip.inspect} running ip: #{running_ip.inspect}")
          self.is_running = true if running_ip == new_ip && gateway == new_resource.gateway
        end

        route_file.close
      end

      action :add do
        # check to see if load_current_resource found the route
        if is_running
          logger.debug("#{new_resource} route already active - nothing to do")
        else
          command = generate_command(:add)
          converge_by("run #{command.join(" ")} to add route") do
            shell_out!(*command)
            logger.info("#{new_resource} added")
          end
        end

        # for now we always write the file (ugly but its what it is)
        generate_config
      end

      action :delete do
        if is_running
          command = generate_command(:delete)
          converge_by("run #{command.join(" ")} to delete route ") do
            shell_out!(*command)
            logger.info("#{new_resource} removed")
          end
        else
          logger.debug("#{new_resource} route does not exist - nothing to do")
        end

        # for now we always write the file (ugly but its what it is)
        generate_config
      end

      def generate_config
        if platform_family?("rhel", "amazon", "fedora")
          conf = {}
          # FIXME FIXME FIXME FIXME: whatever this walking-the-run-context API is, it needs to be removed.
          # walk the collection
          rc = run_context.parent_run_context || run_context
          rc.resource_collection.each do |resource|
            next unless resource.is_a? Chef::Resource::Route

            # default to eth0
            dev = resource.device || "eth0"

            conf[dev] = "" if conf[dev].nil?
            case @action
            when :add
              conf[dev] << config_file_contents(:add, comment: resource.comment, device: resource.device, target: resource.target, metric: resource.metric, netmask: resource.netmask, gateway: resource.gateway) if resource.action == [:add]
            when :delete
              # need to do this for the case when the last route on an int
              # is removed
              conf[dev] << config_file_contents(:delete)
            end
          end
          conf.each_key do |k|
            if new_resource.target == "default"
              network_file_name = "/etc/sysconfig/network"
              converge_by("write route default route to #{network_file_name}") do
                logger.trace("#{new_resource} writing default route #{new_resource.gateway} to #{network_file_name}")
                if ::File.exist?(network_file_name)
                  network_file = ::Chef::Util::FileEdit.new(network_file_name)
                  network_file.search_file_replace_line(/^GATEWAY=/, "GATEWAY=#{new_resource.gateway}")
                  network_file.insert_line_if_no_match(/^GATEWAY=/, "GATEWAY=#{new_resource.gateway}")
                  network_file.write_file
                else
                  network_file = ::File.new(network_file_name, "w")
                  network_file.puts("GATEWAY=#{new_resource.gateway}")
                  network_file.close
                end
              end
            else
              network_file_name = "/etc/sysconfig/network-scripts/route-#{k}"
              converge_by("write route route.#{k}\n#{conf[k]} to #{network_file_name}") do
                network_file = ::File.new(network_file_name, "w")
                network_file.puts(conf[k])
                logger.trace("#{new_resource} writing route.#{k}\n#{conf[k]}")
                network_file.close
              end
            end
          end
        end
      end

      def generate_command(action)
        target = new_resource.target
        target = "#{target}/#{MASK[new_resource.netmask.to_s]}" if new_resource.netmask

        case action
        when :add
          command = [ "ip", "route", "replace", target ]
          command += [ "via", new_resource.gateway ] if new_resource.gateway
          command += [ "dev", new_resource.device ] if new_resource.device
          command += [ "metric", new_resource.metric ] if new_resource.metric
        when :delete
          command = [ "ip", "route", "delete", target ]
          command += [ "via", new_resource.gateway ] if new_resource.gateway
        end

        command
      end

      def config_file_contents(action, options = {})
        content = ""
        case action
        when :add
          content << "# #{options[:comment]}\n" if options[:comment]
          content << (options[:target]).to_s
          content << "/#{MASK[options[:netmask].to_s]}" if options[:netmask]
          content << " via #{options[:gateway]}" if options[:gateway]
          content << " dev #{options[:device]}" if options[:device]
          content << " metric #{options[:metric]}" if options[:metric]
          content << "\n"
        end

        content
      end
    end
  end
end
