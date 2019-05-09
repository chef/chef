#
# Author:: Sander Botman <sbotman@schubergphilis.com>
# Author:: Tim Smith <tsmith@chef.io>
#
# Copyright:: 2014-2018, Sander Botman
# Copyright:: 2018, Chef Software, Inc.
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
      resource_name :cron_access
      provides(:cron_manage) # legacy name @todo in Chef 15 we should { true } this so it wins over the cookbook

      introduced "14.4"
      description "Use the cron_access resource to manage the /etc/cron.allow and /etc/cron.deny files."

      property :user, String,
               description: "An optional property to set the user name if it differs from the resource block's name.",
               name_property: true

      action :allow do
        description "Add the user to the cron.allow file."

        with_run_context :root do
          edit_resource(:template, "/etc/cron.allow") do |new_resource|
            source ::File.expand_path("../support/cron_access.erb", __FILE__)
            local true
            mode "0600"
            variables["users"] ||= []
            variables["users"] << new_resource.user
            action :nothing
            delayed_action :create
          end
        end
      end

      action :deny do
        description "Add the user to the cron.deny file."

        with_run_context :root do
          edit_resource(:template, "/etc/cron.deny") do |new_resource|
            source ::File.expand_path("../support/cron_access.erb", __FILE__)
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
