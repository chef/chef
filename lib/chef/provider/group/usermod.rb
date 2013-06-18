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

          requirements.assert(:modify, :create) do |a|
            a.assertion { @new_resource.members.empty? || @new_resource.append } 
            a.failure_message Chef::Exceptions::Group, "setting group members directly is not supported by #{self.to_s}, must set append true in group"
            # No whyrun alternative - this action is simply not supported.
          end
        end
        
        def modify_group_members
          case node[:platform]
          when "openbsd", "netbsd", "aix", "solaris2", "smartos"
            append_flags = "-G"
          when "solaris", "suse"
            append_flags = "-a -G"
          end

          unless @new_resource.members.empty?
            if(@new_resource.append)
              @new_resource.members.each do |member|
                Chef::Log.debug("#{@new_resource} appending member #{member} to group #{@new_resource.group_name}")
                run_command(:command => "usermod #{append_flags} #{@new_resource.group_name} #{member}" )
              end
            end
          else
            Chef::Log.debug("#{@new_resource} not changing group members, the group has no members")
          end
        end
      end
    end
  end
end
