#
# Copyright:: Copyright 2018, Chef Software, Inc
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
require "ipaddr"
require "iniparse"

require "chef/mixin/which"
require "chef/mixin/shell_out"

class Chef
  class Provider
    class Ifconfig
      class Systemd < Chef::Provider::Ifconfig
        extend Chef::Mixin::Which
        include Chef::Mixin::ShellOut
        extend Chef::Mixin::ShellOut

        provides :ifconfig do
          systemd_unit_enabled?("systemd-networkd")
        end

        def load_current_resource
          @current_resource = Chef::Resource::Ifconfig.new(new_resource.name)

          @status = shell_out_with_systems_locale!("ip", "-json", "addr", "list")
          json = JSON.parse @status.stdout
          interfaces = json.each_with_object({}) { |iface, acc| acc[iface["ifname"]] = iface }

          iface = driver_name
          interface = interfaces.fetch(iface, nil)
          if !interface.nil?
            current_resource.target(new_resource.target)
            current_resource.device(new_resource.device)
            current_resource.hwaddr(interface["address"])
            current_resource.mtu(interface["mtu"])
            address = interface["addr_info"].select { |i| i["label"] == new_resource.device && i["family"] == new_resource.family }.first
            return current_resource if address.nil?
            netmask = get_netmask(address["prefixlen"])
            current_resource.inet_addr(address["local"])
            current_resource.bcast(address["broadcast"])
            current_resource.mask(netmask)
          end
          current_resource
        end

        def action_add
          unit = generate_network_unit
          converge_by "Creating network unit: #{unit_name}" do
            declare_resource(:directory, unit_dir) do
              mode "0755"
              owner "root"
              group "root"
            end

            declare_resource(:file, ::File.join(unit_dir, unit_name)) do
              content unit
              owner "root"
              group "root"
              mode "0644"
              # It appears that systemd-analyze doesn't currently support network units
              # verify :systemd_unit
            end
          end
        end

        def self.systemd_unit_enabled?(unit)
          systemctl_execute!("is-enabled", unit).exitstatus == 0
        end

        def self.systemctl_execute!(action, unit)
          systemctl_path = which("systemctl")
          systemctl_cmd = "#{systemctl_path} --system"
          shell_out_with_systems_locale!("#{systemctl_cmd} #{action} #{Shellwords.escape(unit)}")
        end

        private

        def unit_dir
          "/etc/systemd/network"
        end

        def generate_network_unit
          unit = {
            "Match" => {
              "Name" => driver_name,
            },
            "Address" => {
              "Label" => new_resource.device,
            },
          }
          if new_resource.bootproto == "dhcp"
            unit["Network"] ||= {}
            unit["Network"]["DHCP"] = "YES"
            return unit
          end
          unit["Address"]["Address"] = target
          if new_resource.hwaddr
            unit["Link"] ||= {}
            unit["Link"]["MACAddress"] = new_resource.hwaddr
          end
          if new_resource.mtu
            unit["Link"] ||= {}
            unit["Link"]["MTUBytes"] = new_resource.mtu
          end
          to_systemd_unit(unit)
        end

        def to_systemd_unit(content)
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

        def target
          prefix = mask_to_prefix(new_resource.mask)
          "#{new_resource.target}/#{prefix}"
        end

        def safe_device_name
          new_resource.device.tr(":", "_")
        end

        def unit_name
          "01-chef-#{driver_name}.network"
        end

        def mask_to_prefix(mask)
          return 32 if mask.nil?
          mask_int = IPAddr.new(mask).to_i
          n = IPAddr::IN4MASK ^ mask_int
          i = 32
          while n > 0
            n >>= 1
            i -= 1
          end
          i
        end

        def prefix_to_mask(prefix)
          mask_int = ((IPAddr::IN4MASK >> prefix) << prefix)
          (0..3).map { |i| (mask_int >> (24 - 8 * i)) & 0xff }.join(".")
        end

        def driver_name
          new_resource.device.split(":")[0]
        end
      end
    end
  end
end
