#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

class Chef
  class Resource
    class WindowsEnv < Chef::Resource
      resource_name :windows_env
      provides :windows_env
      provides :env # backwards compat with the pre-Chef 14 resource name

      description "Use the env resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler."

      default_action :create
      allowed_actions :create, :delete, :modify

      property :key_name, String,
               description: "An optional property to set the name of the key that is to be created, deleted, or modified if it differs from the resource block's name.",
               identity: true, name_property: true

      property :value, String,
               description: "The value of the environmental variable to set.",
               required: true

      property :delim, [ String, nil, false ],
               description: "The delimiter that is used to separate multiple values for a single key.",
               desired_state: false

      property :user, String, default: "<System>"
    end
  end
end
