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

class Chef
  class Resource
    # Sets the hostname and updates /etc/hosts on *nix systems
    # @since 14.0.0
    class Hostname < Chef::Resource
      resource_name :hostname
      provides :hostname

      description "Use the hostname resource to set the system's hostname, configure hostname and hosts config"\
                  " file, and re-run the Ohai hostname plugin so the hostname will be available in subsequent cookbooks."
      introduced "14.0"

      property :hostname, String,
               description: "Used to specify the hostname if it is different than the resource's name.",
               name_property: true

      property :compile_time, [ TrueClass, FalseClass ],
               description: "Determines whether or not the resource shoul be run at compile time.",
               default: true

      property :ipaddress, String,
               description: "The IP address to use when configuring the hosts file.",
               default: lazy { node["ipaddress"] }

      property :aliases, [ Array, nil ],
               description: "An array of hostname aliases to use when configuring the hosts file.",
               default: nil

      property :windows_reboot, [ TrueClass, FalseClass ],
               description: "Determines whether or not Windows should be reboot after changing the hostname, as this is required for the change to take effect.",
               default: true

      action_class do
        def append_replacing_matching_lines(path, regex, string)
          text = IO.read(path).split("\n")
          text.reject! { |s| s =~ regex }
          text += [ string ]
          file path do
            content text.join("\n") + "\n"
            owner "root"
            group node["root_group"]
            mode "0644"
            not_if { IO.read(path).split("\n").include?(string) }
          end
        end

        # read in the xml file used by Ec2ConfigService and update the Ec2SetComputerName
        # setting to disable updating the computer name so we don't revert our change on reboot
        # @return [String]
        def updated_ec2_config_xml
          begin
            require "rexml/document"
            config_file = 'C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml'
            config = REXML::Document.new(::File.read(config_file))
            # find an element named State with a sibling element whose value is Ec2SetComputerName
            REXML::XPath.each(config, "//Plugin/State[../Name/text() = 'Ec2SetComputerName']") do |element|
              element.text = "Disabled"
            end
          rescue
            return ""
          end
          config.to_s
        end
      end

      action :set do
        description "Sets the node's hostname."

        if node["platform_family"] != "windows"
          ohai "reload hostname" do
            plugin "hostname"
            action :nothing
          end

          # set the hostname via /bin/hostname
          declare_resource(:execute, "set hostname to #{new_resource.hostname}") do
            command "/bin/hostname #{new_resource.hostname}"
            not_if { shell_out!("hostname").stdout.chomp == new_resource.hostname }
            notifies :reload, "ohai[reload hostname]"
          end

          # make sure node['fqdn'] resolves via /etc/hosts
          unless new_resource.ipaddress.nil?
            newline = "#{new_resource.ipaddress} #{new_resource.hostname}"
            newline << " #{new_resource.aliases.join(" ")}" if new_resource.aliases && !new_resource.aliases.empty?
            newline << " #{new_resource.hostname[/[^\.]*/]}"
            r = append_replacing_matching_lines("/etc/hosts", /^#{new_resource.ipaddress}\s+|\s+#{new_resource.hostname}\s+/, newline)
            r.atomic_update false if docker?
            r.notifies :reload, "ohai[reload hostname]"
          end

          # setup the hostname to perist on a reboot
          case
          when ::File.exist?("/usr/sbin/scutil")
            # darwin
            declare_resource(:execute, "set HostName via scutil") do
              command "/usr/sbin/scutil --set HostName #{new_resource.hostname}"
              not_if { shell_out!("/usr/sbin/scutil --get HostName").stdout.chomp == new_resource.hostname }
              notifies :reload, "ohai[reload hostname]"
            end
            declare_resource(:execute, "set ComputerName via scutil") do
              command "/usr/sbin/scutil --set ComputerName  #{new_resource.hostname}"
              not_if { shell_out!("/usr/sbin/scutil --get ComputerName").stdout.chomp == new_resource.hostname }
              notifies :reload, "ohai[reload hostname]"
            end
            shortname = new_resource.hostname[/[^\.]*/]
            declare_resource(:execute, "set LocalHostName via scutil") do
              command "/usr/sbin/scutil --set LocalHostName #{shortname}"
              not_if { shell_out!("/usr/sbin/scutil --get LocalHostName").stdout.chomp == shortname }
              notifies :reload, "ohai[reload hostname]"
            end
          when node["os"] == "linux"
            case
            when ::File.exist?("/usr/bin/hostnamectl") && !docker?
              # use hostnamectl whenever we find it on linux (as systemd takes over the world)
              # this must come before other methods like /etc/hostname and /etc/sysconfig/network
              declare_resource(:execute, "hostnamectl set-hostname #{new_resource.hostname}") do
                notifies :reload, "ohai[reload hostname]"
                not_if { shell_out!("hostnamectl status", { returns: [0, 1] }).stdout =~ /Static hostname:\s*#{new_resource.hostname}\s*$/ }
              end
            when ::File.exist?("/etc/hostname")
              # debian family uses /etc/hostname
              # arch also uses /etc/hostname
              # the "platform: iox_xr, platform_family: wrlinux, os: linux" platform also hits this
              # the "platform: nexus, platform_family: wrlinux, os: linux" platform also hits this
              # this is also fallback for any linux systemd host in a docker container (where /usr/bin/hostnamectl will fail)
              declare_resource(:file, "/etc/hostname") do
                atomic_update false if docker?
                content "#{new_resource.hostname}\n"
                owner "root"
                group node["root_group"]
                mode "0644"
              end
            when ::File.file?("/etc/sysconfig/network")
              # older non-systemd RHEL/Fedora derived
              append_replacing_matching_lines("/etc/sysconfig/network", /^HOSTNAME\s*=/, "HOSTNAME=#{new_resource.hostname}")
            when ::File.exist?("/etc/HOSTNAME")
              # SuSE/OpenSUSE uses /etc/HOSTNAME
              declare_resource(:file, "/etc/HOSTNAME") do
                content "#{new_resource.hostname}\n"
                owner "root"
                group node["root_group"]
                mode "0644"
              end
            when ::File.exist?("/etc/conf.d/hostname")
              # Gentoo
              declare_resource(:file, "/etc/conf.d/hostname") do
                content "hostname=\"#{new_resource.hostname}\"\n"
                owner "root"
                group node["root_group"]
                mode "0644"
              end
            else
              # This is a failsafe for all other linux distributions where we set the hostname
              # via /etc/sysctl.conf on reboot.  This may get into a fight with other cookbooks
              # that manage sysctls on linux.
              append_replacing_matching_lines("/etc/sysctl.conf", /^\s+kernel\.hostname\s+=/, "kernel.hostname=#{new_resource.hostname}")
            end
          when ::File.exist?("/etc/rc.conf")
            # *BSD systems with /etc/rc.conf + /etc/myname
            append_replacing_matching_lines("/etc/rc.conf", /^\s+hostname\s+=/, "hostname=#{new_resource.hostname}")

            declare_resource(:file, "/etc/myname") do
              content "#{new_resource.hostname}\n"
              owner "root"
              group node["root_group"]
              mode "0644"
            end
          when ::File.exist?("/etc/nodename")
            # Solaris <= 5.10 systems prior to svccfg taking over this functionality (must come before svccfg handling)
            declare_resource(:file, "/etc/nodename") do
              content "#{new_resource.hostname}\n"
              owner "root"
              group node["root_group"]
              mode "0644"
            end
            # Solaris also has /etc/inet/hosts (copypasta alert)
            unless new_resource.ipaddress.nil?
              newline = "#{new_resource.ipaddress} #{new_resource.hostname}"
              newline << " #{new_resource.aliases.join(" ")}" if new_resource.aliases && !new_resource.aliases.empty?
              newline << " #{new_resource.hostname[/[^\.]*/]}"
              r = append_replacing_matching_lines("/etc/inet/hosts", /^#{new_resource.ipaddress}\s+|\s+#{new_resource.hostname}\s+/, newline)
              r.notifies :reload, "ohai[reload hostname]"
            end
          when ::File.exist?("/usr/sbin/svccfg")
            # Solaris >= 5.11 systems using svccfg (must come after /etc/nodename handling)
            declare_resource(:execute, "svccfg -s system/identity:node setprop config/nodename=\'#{new_resource.hostname}\'") do
              notifies :run, "execute[svcadm refresh]", :immediately
              notifies :run, "execute[svcadm restart]", :immediately
              not_if { shell_out!("svccfg -s system/identity:node listprop config/nodename").stdout.chomp =~ /config\/nodename\s+astring\s+#{new_resource.hostname}/ }
            end
            declare_resource(:execute, "svcadm refresh") do
              command "svcadm refresh system/identity:node"
              action :nothing
            end
            declare_resource(:execute, "svcadm restart") do
              command "svcadm restart system/identity:node"
              action :nothing
            end
          else
            raise "Do not know how to set hostname on os #{node["os"]}, platform #{node["platform"]},"\
              "platform_version #{node["platform_version"]}, platform_family #{node["platform_family"]}"
          end

        else # windows
          raise "Windows hostnames cannot contain a period." if new_resource.hostname.match?(/\./)

          # suppress EC2 config service from setting our hostname
          if ::File.exist?('C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml')
            xml_contents = updated_ec2_config_xml
            if xml_contents.empty?
              Chef::Log.warn('Unable to properly parse and update C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml contents. Skipping file update.')
            else
              declare_resource(:file, 'C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml') do
                content xml_contents
              end
            end
          end

          # update via netdom
          declare_resource(:powershell_script, "set hostname") do
            code <<-EOH
              $sysInfo = Get-WmiObject -Class Win32_ComputerSystem
              $sysInfo.Rename("#{new_resource.hostname}")
            EOH
            notifies :request_reboot, "reboot[setting hostname]"
            not_if { Socket.gethostbyname(Socket.gethostname).first == new_resource.hostname }
          end

          # reboot because $windows
          declare_resource(:reboot, "setting hostname") do
            reason "chef setting hostname"
            action :nothing
            only_if { new_resource.windows_reboot }
          end
        end
      end

      # this resource forces itself to run at compile_time
      def after_created
        if compile_time
          Array(action).each do |action|
            run_action(action)
          end
        end
      end
    end
  end
end
