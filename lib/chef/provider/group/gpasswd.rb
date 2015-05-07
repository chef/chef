#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require 'chef/provider/group/groupadd'

class Chef
  class Provider
    class Group
      class Gpasswd < Chef::Provider::Group::Groupadd
        provides :group, platform: %w(suse default)

        def load_current_resource
          super
        end

        def define_resource_requirements
          super
          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exists?("/usr/bin/gpasswd") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/bin/gpasswd for #{@new_resource}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        def set_members(members)
          unless members.empty?
            shell_out!("gpasswd -M #{members.join(',')} #{@new_resource.group_name}")
          else
            shell_out!("gpasswd -M \"\" #{@new_resource.group_name}")
          end
        end

        def add_member(member)
          shell_out!("gpasswd -a #{member} #{@new_resource.group_name}")
        end

        def remove_member(member)
          shell_out!("gpasswd -d #{member} #{@new_resource.group_name}")
        end
      end
    end
  end
end
