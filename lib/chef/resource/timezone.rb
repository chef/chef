#
# Author:: Kirill Kouznetsov <agon.smith@gmail.com>
#
# Copyright:: 2018, Kirill Kouznetsov.
# Copyright:: Copyright (c) Chef Software Inc.
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
      unified_mode true

      provides :timezone

      description "Use the **timezone** resource to change the system timezone on Windows, Linux, and macOS hosts. Timezones are specified in tz database format, with a complete list of available TZ values for Linux and macOS here: <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>. On Windows systems run `tzutil /l` for a complete list of valid timezones."
      introduced "14.6"
      examples <<~DOC
      **Set the timezone to UTC**

      ```ruby
      timezone 'UTC'
      ```

      **Set the timezone to America/Los_Angeles with a friendly resource name on Linux/macOS**

      ```ruby
      timezone 'Set the host's timezone to America/Los_Angeles' do
        timezone 'America/Los_Angeles'
      end
      ```

      **Set the timezone to PST with a friendly resource name on Windows**

      ```ruby
      timezone 'Set the host's timezone to PST' do
        timezone 'Pacific Standard time'
      end
      ```
      DOC

      property :timezone, String,
        description: "An optional property to set the timezone value if it differs from the resource block's name.",
        name_property: true

      # detect the current TZ on darwin hosts
      #
      # @since 14.7
      # @return [String] TZ database value
      def current_macos_tz
        tz_shellout = shell_out!(["systemsetup", "-gettimezone"])
        if /You need administrator access/.match?(tz_shellout.stdout)
          raise "The timezone resource requires administrative privileges to run on macOS hosts!"
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
        raise "There was an error running the tzutil command" if tz_shellout.error?

        tz_shellout.stdout.strip
      end

      # detect the current timezone on systemd hosts
      #
      # @since 16.5
      # @return [String] timezone id
      def current_systemd_tz
        tz_shellout = shell_out(["/usr/bin/timedatectl", "status"])
        raise "There was an error running the timedatectl command" if tz_shellout.error?

        # https://rubular.com/r/eV68MX9XXbyG4k
        /Time zone: (.*) \(.*/.match(tz_shellout.stdout)[1]
      end

      # detect the current timezone on non-systemd RHEL-ish hosts
      #
      # @since 16.5
      # @return [String] timezone id
      def current_rhel_tz
        return nil unless ::File.exist?("/etc/sysconfig/clock")

        # https://rubular.com/r/aoj01L3bKBM7wh
        /ZONE="(.*)"/.match(::File.read("/etc/sysconfig/clock"))[1]
      end

      load_current_value do
        if systemd?
          timezone current_systemd_tz
        else
          case node["platform_family"]
          # Old version of RHEL < 7 and Amazon 201X
          when "rhel", "amazon"
            timezone current_rhel_tz
          when "mac_os_x"
            timezone current_macos_tz
          when "windows"
            timezone current_windows_tz
          end
        end
      end

      action :set, description: "Set the system timezone." do
        # we have to check windows first since the value isn't case sensitive here
        if windows?
          unless current_windows_tz.casecmp?(new_resource.timezone)
            converge_by("setting timezone to '#{new_resource.timezone}'") do
              shell_out!(["tzutil", "/s", new_resource.timezone])
            end
          end
        else # linux / macos
          converge_if_changed(:timezone) do
            # Modern SUSE, Amazon, Fedora, RHEL, Ubuntu & Debian
            if systemd?
              # make sure we have the tzdata files
              package suse? ? "timezone" : "tzdata"

              shell_out!(["/usr/bin/timedatectl", "--no-ask-password", "set-timezone", new_resource.timezone])
            else
              case node["platform_family"]
              # Old version of RHEL < 7 and Amazon 201X
              when "rhel", "amazon"
                # make sure we have the tzdata files
                package "tzdata"

                file "/etc/sysconfig/clock" do
                  owner "root"
                  group "root"
                  mode "0644"
                  action :create
                  content <<~CONTENT
                    ZONE="#{new_resource.timezone}"
                    UTC="true"
                  CONTENT
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
              when "mac_os_x"
                shell_out!(["sudo", "systemsetup", "-settimezone", new_resource.timezone])
              end
            end
          end
        end
      end
    end
  end
end
