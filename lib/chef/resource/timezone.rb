#
# Author:: Kirill Kouznetsov <agon.smith@gmail.com>
#
# Copyright 2018, Kirill Kouznetsov.
# Copyright 2018, Chef Software, Inc.
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

class Chef
  class Resource
    class Timezone < Chef::Resource
      resource_name :timezone

      description "Use the timezone resource to change the system timezone on Windows, Linux, and macOS hosts. Timezones are specified in tz database format, with a complete list of available TZ values for Linux and macOS here: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones and for Windows here: https://ss64.com/nt/timezones.html."
      introduced "14.6"

      property :timezone, String,
               description: "An optional property to set the timezone value if it differs from the resource block's name.",
               name_property: true

      action :set do
        description "Set the timezone."

        # some linux systems may be missing the timezone data
        if node["os"] == "linux"
          package "tzdata" do
            package_name platform_family?("suse") ? "timezone" : "tzdata"
          end
        end

        # Modern Amazon, Fedora, RHEL, Ubuntu & Debian
        if node["init_package"] == "systemd"
          cmd_set_tz = "/usr/bin/timedatectl --no-ask-password set-timezone #{new_resource.timezone}"

          cmd_check_if_set = "/usr/bin/timedatectl status"
          cmd_check_if_set += " | /usr/bin/awk '/Time.*zone/{print}'"
          cmd_check_if_set += " | grep -q #{new_resource.timezone}"

          execute cmd_set_tz do
            action :run
            not_if cmd_check_if_set
          end
        else
          case node["platform_family"]
          # Old version of RHEL < 7 and Amazon 201X
          when "rhel", "amazon"
            file "/etc/sysconfig/clock" do
              owner "root"
              group "root"
              mode "0644"
              action :create
              content %{ZONE="#{new_resource.timezone}"\nUTC="true"\n}
            end

            execute "tzdata-update" do
              command "/usr/sbin/tzdata-update"
              action :nothing
              only_if { ::File.executable?("/usr/sbin/tzdata-update") }
              subscribes :run, "file[/etc/sysconfig/clock]", :immediately
            end

            link "/etc/localtime" do
              to "/usr/share/zoneinfo/#{new_resource.timezone}"
              not_if { ::File.executable?("/usr/sbin/tzdata-update") }
            end
          # debian < 8 and Ubuntu < 16.04
          when "debian"
            file "/etc/timezone" do
              action :create
              content "#{new_resource.timezone}\n"
            end

            bash "dpkg-reconfigure tzdata" do
              user "root"
              code "/usr/sbin/dpkg-reconfigure -f noninteractive tzdata"
              action :nothing
              subscribes :run, "file[/etc/timezone]", :immediately
            end
          when "mac_os_x"
            unless current_darwin_tz == new_resource.timezone
              converge_by("set timezone to #{new_resource.timezone}") do
                shell_out!("sudo systemsetup -settimezone #{new_resource.timezone}")
              end
            end
          when "windows"
            unless current_windows_tz.casecmp?(new_resource.timezone)
              converge_by("setting timezone to \"#{new_resource.timezone}\"") do
                shell_out!("tzutil /s \"#{new_resource.timezone}\"")
              end
            end
          end
        end
      end

      action_class do
        # detect the current TZ on darwin hosts
        #
        # @since 14.7
        # @return [String] TZ database value
        def current_darwin_tz
          tz_shellout = shell_out!("systemsetup -gettimezone")
          if /You need administrator access/.match?(tz_shellout.stdout)
            raise "The timezone resource requires adminstrative priveleges to run on macOS hosts!"
          else
            /Time Zone: (.*)/.match(tz_shellout.stdout)[1]
          end
        end

        # detect the current timezone on windows hosts
        #
        # @since 14.7
        # @return [String] timezone id
        def current_windows_tz
          tz_shellout = shell_out("tzutil /g")
          raise "There was an error running the tzutil command" if tz_shellout.exitstatus == 1
          tz_shellout.stdout.strip
        end
      end
    end
  end
end
