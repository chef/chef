#
# Author:: Joe Williams (<joe@joetify.com>)
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

require "chef/log"
require "chef/provider"

class Chef
  class Provider
    class Mdadm < Chef::Provider

      provides :mdadm

      def load_current_resource
        @current_resource = Chef::Resource::Mdadm.new(new_resource.name)
        current_resource.raid_device(new_resource.raid_device)
        Chef::Log.debug("#{new_resource} checking for software raid device #{current_resource.raid_device}")

        device_not_found = 4
        mdadm = shell_out!("mdadm --detail --test #{new_resource.raid_device}", :returns => [0, device_not_found])
        exists = (mdadm.status == 0)
        current_resource.exists(exists)
      end

      def action_create
        unless current_resource.exists
          converge_by("create RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --create #{new_resource.raid_device} --level #{new_resource.level}"
            command << " --chunk=#{new_resource.chunk}" unless new_resource.level == 1
            command << " --metadata=#{new_resource.metadata}"
            command << " --bitmap=#{new_resource.bitmap}" if new_resource.bitmap
            command << " --layout=#{new_resource.layout}" if new_resource.layout
            command << " --raid-devices #{new_resource.devices.length} #{new_resource.devices.join(" ")}"
            Chef::Log.debug("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            Chef::Log.info("#{new_resource} created raid device (#{new_resource.raid_device})")
          end
        else
          Chef::Log.debug("#{new_resource} raid device already exists, skipping create (#{new_resource.raid_device})")
        end
      end

      def action_assemble
        unless current_resource.exists
          converge_by("assemble RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --assemble #{new_resource.raid_device} #{new_resource.devices.join(" ")}"
            Chef::Log.debug("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            Chef::Log.info("#{new_resource} assembled raid device (#{new_resource.raid_device})")
          end
        else
          Chef::Log.debug("#{new_resource} raid device already exists, skipping assemble (#{new_resource.raid_device})")
        end
      end

      def action_stop
        if current_resource.exists
          converge_by("stop RAID device #{new_resource.raid_device}") do
            command = "yes | mdadm --stop #{new_resource.raid_device}"
            Chef::Log.debug("#{new_resource} mdadm command: #{command}")
            shell_out!(command)
            Chef::Log.info("#{new_resource} stopped raid device (#{new_resource.raid_device})")
          end
        else
          Chef::Log.debug("#{new_resource} raid device doesn't exist (#{new_resource.raid_device}) - not stopping")
        end
      end

    end
  end
end
