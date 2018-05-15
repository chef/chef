#
# Author:: Joe Williams (<joe@joetify.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

require "chef/resource"

class Chef
  class Resource
    class Mdadm < Chef::Resource
      resource_name :mdadm

      description "Use the mdadm resource to manage RAID devices in a Linux environment using the mdadm utility. The mdadm resource"\
                  " will create and assemble an array, but it will not create the config file that is used to persist the array upon"\
                  " reboot. If the config file is required, it must be done by specifying a template with the correct array layout,"\
                  " and then by using the mount provider to create a file systems table (fstab) entry."

      default_action :create
      allowed_actions :create, :assemble, :stop

      property :chunk, Integer, default: 16
      property :devices, Array, default: lazy { [] }
      property :exists, [ TrueClass, FalseClass ], default: false
      property :level, Integer, default: 1
      property :metadata, String, default: "0.90"
      property :bitmap, String
      property :raid_device, String, identity: true, name_property: true
      property :layout, String
    end
  end
end
