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
      class Usermod < Chef::Provider::Group::Groupadd

        provides :group, os: "openbsd"
        provides :group, platform: %w(opensuse) do |node|
          if node[:platform_version]
            Chef::VersionConstraint::Platform.new('>= 12.3').include?(node[:platform_version])
          end
        end
        provides :group, platform: %w(openindiana opensolaris nexentacore omnios solaris2 smartos hpux)

        def load_current_resource
          super
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exists?("/usr/sbin/usermod") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/usermod for #{@new_resource}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end

          requirements.assert(:modify, :manage) do |a|
            a.assertion { @new_resource.members.empty? || @new_resource.append }
            a.failure_message Chef::Exceptions::Group, "setting group members directly is not supported by #{self.to_s}, must set append true in group"
            # No whyrun alternative - this action is simply not supported.
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @new_resource.excluded_members.empty? }
            a.failure_message Chef::Exceptions::Group, "excluded_members is not supported by #{self.to_s}"
            # No whyrun alternative - this action is simply not supported.
          end
        end

        def set_members(members)
          return if members.empty?
          # This provider only supports adding members with
          # append. Only if the action is create we will go
          # ahead and add members.
          if @new_resource.action == :create
            members.each do |member|
              add_member(member)
            end
          else
            raise Chef::Exceptions::UnsupportedAction, "Setting members directly is not supported by #{self.to_s}"
          end
        end

        def add_member(member)
          shell_out!("usermod #{append_flags} #{@new_resource.group_name} #{member}")
        end

        def remove_member(member)
          # This provider only supports adding members with
          # append. This function should never be called.
          raise Chef::Exceptions::UnsupportedAction, "Removing members members is not supported by #{self.to_s}"
        end

        def append_flags
          case node[:platform]
          when "openbsd", "netbsd", "aix", "solaris2", "smartos", "omnios"
            "-G"
          when "solaris", "suse", "opensuse"
            "-a -G"
          end
        end

      end
    end
  end
end
