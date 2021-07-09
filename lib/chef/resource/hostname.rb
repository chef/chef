#
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

require_relative "../resource"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    # Sets the hostname and updates /etc/hosts on *nix systems
    # @since 14.0.0
    class Hostname < Chef::Resource
      unified_mode true

      provides :hostname

      description "Use the **hostname** resource to set the system's hostname, configure hostname and hosts config file, and re-run the Ohai hostname plugin so the hostname will be available in subsequent cookbooks."
      introduced "14.0"
      examples <<~DOC
        **Set the hostname using the IP address, as detected by Ohai**:

        ```ruby
        hostname 'example'
        ```

        **Manually specify the hostname and IP address**:

        ```ruby
        hostname 'statically_configured_host' do
          hostname 'example'
          ipaddress '198.51.100.2'
        end
        ```

        **Change the hostname of a Windows, Non-Domain joined node**:

        ```ruby
        hostname 'renaming a workgroup computer' do
          hostname 'Foo'
        end
        ```

        **Change the hostname of a Windows, Domain-joined node (new in 17.2)**:

        ```ruby
        hostname 'renaming a domain-joined computer' do
          hostname 'Foo'
          domain_user "Domain\\Someone"
          domain_password 'SomePassword'
        end
        ```
      DOC

      property :hostname, String,
        description: "An optional property to set the hostname if it differs from the resource block's name.",
        name_property: true

      property :fqdn, String,
        description: "An optional property to set the fqdn if it differs from the resource block's hostname.",
        introduced: "17.0"

      property :ipaddress, String,
        description: "The IP address to use when configuring the hosts file.",
        default: lazy { node["ipaddress"] }, default_description: "The node's IP address as determined by Ohai."

      property :aliases, [ Array, nil ],
        description: "An array of hostname aliases to use when configuring the hosts file.",
        default: nil

      # override compile_time property to be true by default
      property :compile_time, [ TrueClass, FalseClass ],
        description: "Determines whether or not the resource should be run at compile time.",
        default: true, desired_state: false

      property :windows_reboot, [ TrueClass, FalseClass ],
        description: "Determines whether or not Windows should be reboot after changing the hostname, as this is required for the change to take effect.",
        default: true

      property :domain_user, String,
        description: "A domain account specified in the form of DOMAIN\\user used when renaming a domain-joined device",
        introduced: "17.2"

      property :domain_password, String,
        description: "The password to accompany the domain_user parameter",
        sensitive: true,
        introduced: "17.2"

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
            require "rexml/document" unless defined?(REXML::Document)
            config = REXML::Document.new(::File.read(WINDOWS_EC2_CONFIG))
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

      def is_domain_joined?
        powershell_exec!("(Get-CIMInstance -Class Win32_ComputerSystem).PartofDomain").result
      end

      action :set, description: "Sets the node's hostname." do
        if !windows?
          ohai "reload hostname" do
            plugin "hostname"
            action :nothing
          end

          # set the hostname via /bin/hostname
          execute "set hostname to #{new_resource.hostname}" do
            command "/bin/hostname #{new_resource.hostname}"
            not_if { shell_out!("hostname").stdout.chomp == new_resource.hostname }
            notifies :reload, "ohai[reload hostname]"
          end

          # make sure node['fqdn'] resolves via /etc/hosts
          unless new_resource.ipaddress.nil?
            newline = "#{new_resource.ipaddress}"
            newline << " #{new_resource.fqdn}" unless new_resource.fqdn.to_s.empty?
            newline << " #{new_resource.hostname}"
            newline << " #{new_resource.aliases.join(" ")}" if new_resource.aliases && !new_resource.aliases.empty?
            newline << " #{new_resource.hostname[/[^\.]*/]}"
            r = append_replacing_matching_lines("/etc/hosts", /^#{new_resource.ipaddress}\s+|\s+#{new_resource.hostname}\s+/, newline)
            r.atomic_update false if docker?
            r.notifies :reload, "ohai[reload hostname]"
          end

          # setup the hostname to persist on a reboot
          case
          when darwin?
            # darwin
            execute "set HostName via scutil" do
              command "/usr/sbin/scutil --set HostName #{new_resource.hostname}"
              not_if { shell_out("/usr/sbin/scutil --get HostName").stdout.chomp == new_resource.hostname }
              notifies :reload, "ohai[reload hostname]"
            end
            execute "set ComputerName via scutil" do
              command "/usr/sbin/scutil --set ComputerName  #{new_resource.hostname}"
              not_if { shell_out("/usr/sbin/scutil --get ComputerName").stdout.chomp == new_resource.hostname }
              notifies :reload, "ohai[reload hostname]"
            end
            shortname = new_resource.hostname[/[^\.]*/]
            execute "set LocalHostName via scutil" do
              command "/usr/sbin/scutil --set LocalHostName #{shortname}"
              not_if { shell_out("/usr/sbin/scutil --get LocalHostName").stdout.chomp == shortname }
              notifies :reload, "ohai[reload hostname]"
            end
          when linux?
            case
            when ::File.exist?("/usr/bin/hostnamectl") && !docker?
              # use hostnamectl whenever we find it on linux (as systemd takes over the world)
              # this must come before other methods like /etc/hostname and /etc/sysconfig/network
              execute "hostnamectl set-hostname #{new_resource.hostname}" do
                notifies :reload, "ohai[reload hostname]"
                not_if { shell_out!("hostnamectl status", returns: [0, 1]).stdout =~ /Static hostname:\s*#{new_resource.hostname}\s*$/ }
              end
            when ::File.exist?("/etc/hostname")
              # debian family uses /etc/hostname
              # arch also uses /etc/hostname
              # the "platform: iox_xr, platform_family: wrlinux, os: linux" platform also hits this
              # the "platform: nexus, platform_family: wrlinux, os: linux" platform also hits this
              # this is also fallback for any linux systemd host in a docker container (where /usr/bin/hostnamectl will fail)
              file "/etc/hostname" do
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
              # SuSE/openSUSE uses /etc/HOSTNAME
              file "/etc/HOSTNAME" do
                content "#{new_resource.hostname}\n"
                owner "root"
                group node["root_group"]
                mode "0644"
              end
            when ::File.exist?("/etc/conf.d/hostname")
              # Gentoo
              file "/etc/conf.d/hostname" do
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

            file "/etc/myname" do
              content "#{new_resource.hostname}\n"
              owner "root"
              group node["root_group"]
              mode "0644"
            end
          when ::File.exist?("/usr/sbin/svccfg") # solaris 5.11
            execute "svccfg -s system/identity:node setprop config/nodename=\'#{new_resource.hostname}\'" do
              notifies :run, "execute[svcadm refresh]", :immediately
              notifies :run, "execute[svcadm restart]", :immediately
              not_if { shell_out!("svccfg -s system/identity:node listprop config/nodename").stdout.chomp =~ %r{config/nodename\s+astring\s+#{new_resource.hostname}} }
            end
            execute "svcadm refresh" do
              command "svcadm refresh system/identity:node"
              action :nothing
            end
            execute "svcadm restart" do
              command "svcadm restart system/identity:node"
              action :nothing
            end
          else
            raise "Do not know how to set hostname on os #{node["os"]}, platform #{node["platform"]},"\
              "platform_version #{node["platform_version"]}, platform_family #{node["platform_family"]}"
          end

        else # windows
          WINDOWS_EC2_CONFIG = 'C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml'.freeze

          raise "Windows hostnames cannot contain a period." if new_resource.hostname.include?(".")

          # suppress EC2 config service from setting our hostname
          if ::File.exist?(WINDOWS_EC2_CONFIG)
            xml_contents = updated_ec2_config_xml
            if xml_contents.empty?
              Chef::Log.warn('Unable to properly parse and update C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml contents. Skipping file update.')
            else
              file WINDOWS_EC2_CONFIG do
                content xml_contents
              end
            end
          end

          unless Socket.gethostbyname(Socket.gethostname).first == new_resource.hostname
            if is_domain_joined?
              if new_resource.domain_user.nil? || new_resource.domain_password.nil?
                raise "The `domain_user` and `domain_password` properties are required to change the hostname of a domain-connected Windows system."
              else
                converge_by "set hostname to #{new_resource.hostname}" do
                  powershell_exec! <<~EOH
                    $user = #{new_resource.domain_user}
                    $secure_password = #{new_resource.domain_password} | Convertto-SecureString -AsPlainText -Force
                    $Credentials = New-Object System.Management.Automation.PSCredential -Argumentlist ($user, $secure_password)
                    Rename-Computer -NewName #{new_resource.hostname} -DomainCredential $Credentials
                  EOH
                end
              end
            else
              converge_by "set hostname to #{new_resource.hostname}" do
                powershell_exec!("Rename-Computer -NewName #{new_resource.hostname}")
              end
            end
            # reboot because $windows
            reboot "setting hostname" do
              reason "#{ChefUtils::Dist::Infra::PRODUCT} updated system hostname"
              only_if { new_resource.windows_reboot }
              action :request_reboot
            end
          end
        end
      end
    end
  end
end
