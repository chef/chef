#
# Author:: Sander Botman <sbotman@schubergphilis.com>
# Author:: Tim Smith <tsmith@chef.io>
#
# Copyright:: 2014-2018, Sander Botman
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
    class CronAccess < Chef::Resource
      unified_mode true
      provides :cron_access
      provides(:cron_manage) # legacy name @todo in Chef 15 we should { true } this so it wins over the cookbook

      introduced "14.4"
      description "Use the **cron_access** resource to manage cron's cron.allow and cron.deny files. Note: This resource previously shipped in the `cron` cookbook as `cron_manage`, which it can still be used as for backwards compatibility with existing Chef Infra Client releases."
      examples <<~DOC
        **Add the mike user to cron.allow**

        ```ruby
        cron_access 'mike'
        ```

        **Add the mike user to cron.deny**

        ```ruby
        cron_access 'mike' do
          action :deny
        end
        ```

        **Specify the username with the user property**

        ```ruby
        cron_access 'Deny the jenkins user access to cron for security purposes' do
          user 'jenkins'
          action :deny
        end
        ```
      DOC

      property :user, String,
        description: "An optional property to set the user name if it differs from the resource block's name.",
        name_property: true

      CRON_PATHS = {
          "aix" => "/var/adm/cron",
          "solaris" => "/etc/cron.d",
          "default" => "/etc",
      }.freeze

      action :allow, description: "Add the user to the cron.allow file." do
        allow_path = ::File.join(value_for_platform_family(CRON_PATHS), "cron.allow")

        with_run_context :root do
          edit_resource(:template, allow_path) do |new_resource|
            source ::File.expand_path("support/cron_access.erb", __dir__)
            local true
            mode "0600"
            variables["users"] ||= []
            variables["users"] << new_resource.user
            action :nothing
            delayed_action :create
          end
        end
      end

      action :deny, description: "Add the user to the cron.deny file." do
        deny_path = ::File.join(value_for_platform_family(CRON_PATHS), "cron.deny")

        with_run_context :root do
          edit_resource(:template, deny_path) do |new_resource|
            source ::File.expand_path("support/cron_access.erb", __dir__)
            local true
            mode "0600"
            variables["users"] ||= []
            variables["users"] << new_resource.user
            action :nothing
            delayed_action :create
          end
        end
      end
    end
  end
end
