#
# Author:: Sölvi Páll Ásgeirsson (<solvip@gmail.com>)
# Author:: Richard Lavey (richard.lavey@calastone.com)
# Author:: Tim Smith (tsmith@chef.io)
#
# Copyright:: 2014-2017, Sölvi Páll Ásgeirsson.
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    class WindowsUpdateSettings < Chef::Resource

      provides :windows_update_settings

      description "Use the **windows_update_settings** resource to manage the various Windows Update patching options."
      introduced "17.3"
      examples <<~DOC
      **Set Windows Update settings**:

      ```ruby
      windows_update_settings 'Settings to Configure Windows Nodes to automatically receive updates' do
        disable_os_upgrades true
        elevate_non_admins true
        block_windows_update_website true
        automatically_install_minor_updates true
        scheduled_install_day 'Friday'
        scheduled_install_hour 18
        update_other_ms_products true
        action :enable
      end
      ```
      DOC

      # required for the alias to pass validation
      allowed_actions :set, :enable

      DAYS = %w{Everyday Monday Tuesday Wednesday Thursday Friday Saturday Sunday}.freeze
      UPDATE_OPTIONS = {
                        notify: 2,
                        download_and_notify: 3,
                        download_and_schedule: 4,
                        local_admin_decides: 5,
                      }.freeze

      # HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate

      property :disable_os_upgrades, [true, false], default: false, description: "Disable OS upgrades."
      # options: 0 - let windows update update the os - false
      #          1 - don't let windows update update the os - true

      property :elevate_non_admins, [true, false], default: true, description: "Allow normal user accounts to temporarily be elevated to install patches."
      # options: 0 - do not elevate a user to force an install - false
      #          1 - do elevate the logged on user to install an update - true

      property :add_to_target_wsus_group, [true, false], deprecated: "As of Chef Infra Client 17.3 the `add_to_target_wsus_group` property is no longer necessary."
      # we set this registry value now automatically if the group name is set

      property :target_wsus_group_name, String, description: "Add the node to a WSUS Target Group."
      # options: --- a string representing the name of a target group you defined on your wsus server

      property :wsus_server_url, String, description: "The URL of your WSUS server if you use one."
      # options: --- a url for your internal update server in the form of https://my.updateserver.tld:4545 or whatever

      property :wsus_status_server_url, String, deprecated: "As of Chef Infra Client 17.3 the `wsus_status_server_url` no longer needs to be set."
      # this needs to be the same as wsus_server_url so we just set that value in both places now

      # HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer

      property :block_windows_update_website, [true, false], default: false, description: "Block accessing the Windows Update website."
      # options: 0 - allow access to the windows update website - false
      #          1 - do not allow access to the windows update website - true

      # HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU

      property :automatic_update_option, [Integer, Symbol], equal_to: UPDATE_OPTIONS.keys, coerce: proc { |x| UPDATE_OPTIONS.key(x) || x },
                default: :download_and_schedule,
                description: "Control what to do when updates are found. This allows you to notify, automatically download and notify to install, automatically download and schedule the install, or let the local admin decide what action to take."
      # options: 2 - notify before download
      #          3 - auto download and notify
      #          4 - auto download and schedule - must also set day and time (below)
      #          5 - allow the local admin to decide

      property :automatically_install_minor_updates, [true, false], default: false, description: "Automatically install minor updates."
      # options: 0 - do not automatically install minor updates - false
      #          1 - of course, silently install them! - true

      property :enable_detection_frequency, [true, false], default: false, description: "Used to override the OS default of how often to check for updates"
      # do i want my nodes checking for updates at a time interval i chose?
      # options: 0 - do not enable the option for a custom interval - false
      #          1 - yeah, buddy, i want to set my own interval for checking for updates - true

      property :custom_detection_frequency, Integer, default: 22, description: "If you decided to override the OS default detection frequency, specify your choice here. Valid choices are 0 - 22",
      callbacks: {
        "should be a valid detection frequency (0-22)" => lambda { |p|
          p.between?(0, 22)
        },
      }
      # a time period of between 0 and 22 hours to check for new updates
      # this is a hex value - convert it from dec to hex

      property :no_reboot_with_users_logged_on, [true, false], default: true, description: "Prevents the OS from rebooting while someone is on the console."
      # options: 0 - user is notified of pending reboot in xx minutes - false/off
      #          1 - user is notified of pending reboot but can defer - true/on

      property :disable_automatic_updates, [true, false], default: false, description: "Disable Windows Update."
      # options: 0 - enable automatic updates to the local system - false
      #          1 - disable automatic updates - true

      property :scheduled_install_day, String, equal_to: DAYS, default: DAYS.first, description: "A day of the week to tell Windows when to install updates."
      # options: Everyday - install every day
      #          Sunday - Saturday day of the week to install, 1 == sunday

      property :scheduled_install_hour, Integer, description: "If you chose a scheduled day to install, then choose an hour on that day for you installation",
                callbacks: {
                  "should be a valid hour in a 24 hour clock" => lambda { |p|
                    p > 0 && p < 25
                  },
                }
      # options: --- 2-digit number representing an hour of the day, uses a 24-hour clock, 12 == noon, 24 == midnight

      property :update_other_ms_products, [true, false], default: true, description: "Allows for other Microsoft products to get updates too"
      # options: 0 - do not allow wu to update other apps - remove key from hive - false/off
      #          1 - please update all my stuff! - true/on

      # \AU\AllowMUUpdateService dword: 1

      property :custom_wsus_server, [true, false], deprecated: "As of Chef Infra Client 17.3 the `custom_wsus_server` no longer needs to be setup when specifying a WSUS endpoint."
      # not necessary as we set this registry value automatically if a URL is set

      action :set, description: "Set Windows Update settings." do
        actual_day = convert_day(new_resource.scheduled_install_day)

        registry_key "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate" do
          recursive true
          values [{
            name: "DisableOSUpgrade",
            type: :dword,
            data: new_resource.disable_os_upgrades ? 1 : 0,
          },
          {
            name: "ElevateNonAdmins",
            type: :dword,
            data: new_resource.elevate_non_admins ? 1 : 0,
          },
          {
            name: "TargetGroupEnabled",
            type: :dword,
            data: new_resource.target_wsus_group_name ? 1 : 0,
          },
          {
            name: "TargetGroup",
            type: :string,
            data: new_resource.target_wsus_group_name,
          },
          {
            name: "WUServer",
            type: :string,
            data: new_resource.wsus_server_url,
          },
          {
            name: "WUStatusServer",
            type: :string,
            data: new_resource.wsus_server_url, # status server and server need to be the same. Why? Ask Microsoft
          }]
          action :create
        end

        registry_key "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer" do
          recursive true
          values [{
            name: "NoWindowsUpdate",
            type: :dword,
            data: new_resource.block_windows_update_website ? 1 : 0,
          }]
          action :create
        end

        registry_key "HKEY_LOCAL_MACHINE\\Software\\Policies\\Microsoft\\Windows\\WindowsUpdate\\AU" do
          recursive true
          values [{
            name: "AUOptions",
            type: :dword,
            data: UPDATE_OPTIONS[new_resource.automatic_update_option],
          },
          {
            name: "AutoInstallMinorUpdates",
            type: :dword,
            data: new_resource.automatically_install_minor_updates ? 1 : 0,
          },
          {
            name: "DetectionFrequencyEnabled",
            type: :dword,
            data: new_resource.enable_detection_frequency ? 1 : 0,
          },
          {
            name: "DetectionFrequency",
            type: :dword,
            data: new_resource.custom_detection_frequency,
          },
          {
            name: "NoAutoRebootWithLoggedOnUsers",
            type: :dword,
            data: new_resource.no_reboot_with_users_logged_on ? 1 : 0,
          },
          {
            name: "NoAutoUpdate",
            type: :dword,
            data: new_resource.disable_automatic_updates ? 1 : 0,
          },
          {
            name: "ScheduledInstallDay",
            type: :dword,
            data: actual_day,
          },
          {
            name: "ScheduledInstallTime",
            type: :dword,
            data: new_resource.scheduled_install_hour,
          },
          {
            name: "AllowMUUpdateService",
            type: :dword,
            data: new_resource.update_other_ms_products ? 1 : 0,
          },
          {
            name: "UseWUServer",
            type: :dword,
            data: new_resource.wsus_server_url ? 1 : 0, # if we have a URL set then want to turn on WSUS functionality
          }]
          action :create
        end
      end

      action_class do
        def convert_day(day)
          DAYS.index(day)
        end

        # support the old name as well
        alias_method :action_enable, :action_set
      end
    end
  end
end
