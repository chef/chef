#
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
    class NotifyGroup < Chef::Resource
      provides :notify_group, target_mode: true
      target_mode support: :full

      description "The notify_group resource does nothing, and always fires notifications which are set on it.  Use it to DRY blocks of notifications that are common to multiple resources, and provide a single target for other resources to notify.  Unlike most resources, its default action is :nothing."
      introduced "15.8"
      examples <<~DOC
        Wire up a notification from a service resource to stop and start the service with a 60 second delay.

        ```ruby
        service "crude" do
          action [ :enable, :start ]
        end

        chef_sleep "60" do
          action :nothing
        end

        # Example code for a hypothetical badly behaved service that requires
        # 60 seconds between a stop and start in order to restart the service
        # (due to race conditions, bleeding connections down, resources that only
        # slowly unlock in the background, or other poor software behaviors that
        # are sometimes encountered).
        #
        notify_group "crude_stop_and_start" do
          notifies :stop, "service[crude]", :immediately
          notifies :sleep, "chef_sleep[60]", :immediately
          notifies :start, "service[crude]", :immediately
        end

        template "/etc/crude/crude.conf" do
          source "crude.conf.erb"
          variables node["crude"]
          notifies :run, "notify_group[crude_stop_and_start]", :immediately
        end
        ```
      DOC

      action :run do
        new_resource.updated_by_last_action(true)
      end

      # This is deliberate.  Users should be sending a single notification to a notify_group resource which then
      # distributes multiple notifications.  Having a notify_group run by default is unnecessary indirection and
      # should be replaced by just running the resources in order.  If resources need to be batch run multiple times
      # per invocation then the resources themselves are not properly declarative idempotent resources, and the user
      # is attempting to turn Chef into an imperative language using this construct and/or the batch of resources
      # need to be turned into a custom resource.
      #
      default_action :nothing
    end
  end
end
