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
      class Suse < Chef::Provider::Group::Groupadd
        provides :group, platform: %w(opensuse)
        provides :group, platform: %w(suse) do |node|
          if node[:platform_version]
            Chef::VersionConstraint::Platform.new('< 12.0').include?(node[:platform_version])
          end
        end

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
          unless @current_resource.members.empty?
            shell_out!("groupmod -R #{@current_resource.members.join(',')} #{@new_resource.group_name}")
          end

          unless members.empty?
            shell_out!("groupmod -A #{members.join(',')} #{@new_resource.group_name}")
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
