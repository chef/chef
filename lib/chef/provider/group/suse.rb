#
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
      class Suse < Chef::Provider::Group::Groupadd
        provides :group, platform: "opensuse", platform_version: "< 12.3"
        provides :group, platform: "suse", platform_version: "< 12.0"

        def load_current_resource
          super
        end

        def define_resource_requirements
          super
          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exists?("/usr/sbin/groupmod") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/groupmod for #{@new_resource.name}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        def set_members(members)
          to_delete = @current_resource.members - members
          to_delete.each do |member|
            remove_member(member)
          end

          to_add = members - @current_resource.members
          to_add.each do |member|
            add_member(member)
          end
        end

        def add_member(member)
          shell_out!("groupmod -A #{member} #{@new_resource.group_name}")
        end

        def remove_member(member)
          shell_out!("groupmod -R #{member} #{@new_resource.group_name}")
        end

      end
    end
  end
end
