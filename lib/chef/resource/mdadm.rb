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
      unified_mode true

      provides :mdadm

      description "Use the **mdadm** resource to manage RAID devices in a Linux environment using the mdadm utility. The mdadm resource"\
                  " will create and assemble an array, but it will not create the config file that is used to persist the array upon"\
                  " reboot. If the config file is required, it must be done by specifying a template with the correct array layout,"\
                  " and then by using the mount provider to create a file systems table (fstab) entry."

      examples <<~DOC
      **Create and assemble a RAID 0 array**

      The mdadm command can be used to create RAID arrays. For example, a RAID 0 array named /dev/md0 with 10 devices would have a command similar to the following:

      ```
      mdadm --create /dev/md0 --level=0 --raid-devices=10 /dev/s01.../dev/s10
      ```

      where /dev/s01 .. /dev/s10 represents 10 devices (01, 02, 03, and so on). This same command, when expressed as a recipe using the mdadm resource, would be similar to:

      ```ruby
      mdadm '/dev/md0' do
        devices [ '/dev/s01', ... '/dev/s10' ]
        level 0
        action :create
      end
      ```

      (again, where /dev/s01 .. /dev/s10 represents devices /dev/s01, /dev/s02, /dev/s03, and so on).

      **Create and assemble a RAID 1 array**

      ```ruby
      mdadm '/dev/md0' do
        devices [ '/dev/sda', '/dev/sdb' ]
        level 1
        action [ :create, :assemble ]
      end
      ```

      **Create and assemble a RAID 5 array**

      The mdadm command can be used to create RAID arrays. For example, a RAID 5 array named /dev/sd0 with 4, and a superblock type of 0.90 would be similar to:

      ```ruby
      mdadm '/dev/sd0' do
        devices [ '/dev/s1', '/dev/s2', '/dev/s3', '/dev/s4' ]
        level 5
        metadata '0.90'
        chunk 32
        action :create
      end
      ```
      DOC

      default_action :create
      allowed_actions :create, :assemble, :stop

      property :chunk, Integer,
        default: 16,
        description: "The chunk size. This property should not be used for a RAID 1 mirrored pair (i.e. when the `level` property is set to `1`)."

      property :devices, Array,
        default: [],
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
        name_property: true,
        description: "An optional property to specify the name of the RAID device if it differs from the resource block's name."

      property :layout, String,
        description: "The RAID5 parity algorithm. Possible values: `left-asymmetric` (or `la`), `left-symmetric` (or ls), `right-asymmetric` (or `ra`), or `right-symmetric` (or `rs`)."

      action_class do
        def load_current_resource
          @current_resource = Chef::Resource::Mdadm.new(new_resource.name)
          current_resource.raid_device(new_resource.raid_device)
          logger.trace("#{new_resource} checking for software raid device #{current_resource.raid_device}")

          device_not_found = 4
          mdadm = shell_out!("mdadm", "--detail", "--test", new_resource.raid_device, returns: [0, device_not_found])
          exists = (mdadm.status == 0)
          current_resource.exists(exists)
        end
      end

      action :create, description: "Create an array with per-device superblocks. If an array already exists (but does not match), update that array to match." do
        unless current_resource.exists
          converge_by("create RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --create #{new_resource.raid_device} --level #{new_resource.level}"
            command << " --chunk=#{new_resource.chunk}" unless new_resource.level == 1
            command << " --metadata=#{new_resource.metadata}"
            command << " --bitmap=#{new_resource.bitmap}" if new_resource.bitmap
            command << " --layout=#{new_resource.layout}" if new_resource.layout
            command << " --raid-devices #{new_resource.devices.length} #{new_resource.devices.join(" ")}"
            logger.trace("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            logger.info("#{new_resource} created raid device (#{new_resource.raid_device})")
          end
        else
          logger.debug("#{new_resource} raid device already exists, skipping create (#{new_resource.raid_device})")
        end
      end

      action :assemble, description: "Assemble a previously created array into an active array." do
        unless current_resource.exists
          converge_by("assemble RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --assemble #{new_resource.raid_device} #{new_resource.devices.join(" ")}"
            logger.trace("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            logger.info("#{new_resource} assembled raid device (#{new_resource.raid_device})")
          end
        else
          logger.debug("#{new_resource} raid device already exists, skipping assemble (#{new_resource.raid_device})")
        end
      end

      action :stop, description: "Stop an active array." do
        if current_resource.exists
          converge_by("stop RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --stop #{new_resource.raid_device}"
            logger.trace("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            logger.info("#{new_resource} stopped raid device (#{new_resource.raid_device})")
          end
        else
          logger.debug("#{new_resource} raid device doesn't exist (#{new_resource.raid_device}) - not stopping")
        end
      end

    end
  end
end
