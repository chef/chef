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

require_relative "../resource"

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

      property :chunk, Integer,
               default: 16,
               description: "The chunk size. This property should not be used for a RAID 1 mirrored pair (i.e. when the level property is set to 1)."

      property :devices, Array,
               default: lazy { [] },
               description: "The devices to be part of a RAID array."

      # @todo this should get refactored away
      property :exists, [ TrueClass, FalseClass ],
               default: false,
               skip_docs: true

      property :level, Integer,
               default: 1,
               description: "The RAID level."

      property :metadata, String,
               default: "0.90",
               description: "The superblock type for RAID metadata."

      property :bitmap, String,
                description: "The path to a file in which a write-intent bitmap is stored."

      property :raid_device, String,
               identity: true, name_property: true,
               description: "An optional property to specify the name of the RAID device if it differs from the resource block's name."

      property :layout, String,
               description: "The RAID5 parity algorithm. Possible values: left-asymmetric (or la), left-symmetric (or ls), right-asymmetric (or ra), or right-symmetric (or rs)."
    end
  end
end
