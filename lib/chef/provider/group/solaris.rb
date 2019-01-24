#
# Author:: Joshua Justice (<jjustice6@bloomberg.net>)
# Copyright:: Copyright 2008-2019, Chef Software Inc.
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

require "chef/provider/group/groupadd"

class Chef
  class Provider
    class Group
      class Solaris < Chef::Provider::Group::Groupadd

        provides :group, os: "solaris2"

        def load_current_resource
          super
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exist?("/usr/sbin/usermod") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/usermod for #{new_resource}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end

          requirements.assert(:modify, :manage) do |a|
            a.assertion { (new_resource.members.empty?  && new_resource.excluded_members.empty?) || new_resource.append }
            a.failure_message Chef::Exceptions::Group, "setting group members directly is not supported by #{self}, must set append true in group"
            # No whyrun alternative - this action is simply not supported.
          end

        end

        def set_members(members)
          unless members.empty?
            members.each do |member|
              add_member(member)
            end
          end
          unless excluded_members.empty?
            excluded_members.each do |excluded_member|
              remove_member(excluded_member)
            end
          end
        end

        def add_member(member)
          shell_out!("usermod", "-G", "+#{new_resource.group_name}", member)
        end

        def remove_member(member)
          shell_out!("usermod", "-G", "-#{new_resource.group_name}", member)
        end

      end
    end
  end
end
