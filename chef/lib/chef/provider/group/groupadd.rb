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

class Chef
  class Provider
    class Group
      class Groupadd < Chef::Provider::Group
        
        def load_current_resource
          super
          
          [ "/usr/sbin/groupadd",
            "/usr/sbin/groupmod",
            "/usr/sbin/groupdel",
            "/usr/bin/gpasswd" ].each do |required_binary|
            raise Chef::Exceptions::Group, "Could not find binary #{required_binary} for #{@new_resource}" unless ::File.exists?(required_binary)
          end
        end

        # Create the group
        def create_group
          command = "groupadd"
          command << set_options
          run_command(:command => command)
          modify_group_members    
        end
        
        # Manage the group when it already exists
        def manage_group
          command = "groupmod"
          command << set_options
          run_command(:command => command)
          modify_group_members
        end
        
        # Remove the group
        def remove_group
          run_command(:command => "groupdel #{@new_resource.group_name}")
        end
        
        def modify_group_members
          unless @new_resource.members.empty?
            if(@new_resource.append)
              @new_resource.members.each do |member|
                Chef::Log.debug("#{@new_resource}: appending member #{member} to group #{@new_resource.group_name}")
                run_command(:command => "gpasswd -a #{member} #{@new_resource.group_name}")
              end
            else
              Chef::Log.debug("#{@new_resource}: setting group members to #{@new_resource.members.join(', ')}")
              run_command(:command => "gpasswd -M #{@new_resource.members.join(',')} #{@new_resource.group_name}")
            end
          else
            Chef::Log.debug("#{@new_resource}: not changing group members, the group has no members")
          end
        end
        
        # Little bit of magic as per Adam's useradd provider to pull the assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options
          opts = ""
          { :gid => "-g" }.sort { |a,b| a[0] <=> b[0] }.each do |field, option|
            if @current_resource.send(field) != @new_resource.send(field)
              if @new_resource.send(field)
                Chef::Log.debug("#{@new_resource}: setting #{field.to_s} to #{@new_resource.send(field)}")
                opts << " #{option} '#{@new_resource.send(field)}'"
              end
            end
          end
          opts << " #{@new_resource.group_name}"
        end
        
      end
    end
  end
end
