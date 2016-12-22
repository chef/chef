#
# Author:: Dreamcat4 (<dreamcat4@gmail.com>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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
      class Dscl < Chef::Provider::Group

        provides :group, os: "darwin"

        def dscl(*args)
          argdup = args.dup
          cmd = argdup.shift
          shellcmd = [ "dscl", ".", "-#{cmd}", argdup ]
          status = shell_out_compact(shellcmd)
          stdout_result = ""
          stderr_result = ""
          status.stdout.each_line { |line| stdout_result << line }
          status.stderr.each_line { |line| stderr_result << line }
          [shellcmd.flatten.compact.join(" "), status, stdout_result, stderr_result]
        end

        def safe_dscl(*args)
          result = dscl(*args)
          return "" if ( args.first =~ /^delete/ ) && ( result[1].exitstatus != 0 )
          raise(Chef::Exceptions::Group, "dscl error: #{result.inspect}") unless result[1].exitstatus == 0
          raise(Chef::Exceptions::Group, "dscl error: #{result.inspect}") if result[2] =~ /No such key: /
          result[2]
        end

        def load_current_resource
          @current_resource = Chef::Resource::Group.new(new_resource.name)
          current_resource.group_name(new_resource.group_name)
          group_info = nil
          begin
            group_info = safe_dscl("read", "/Groups/#{new_resource.group_name}")
          rescue Chef::Exceptions::Group
            @group_exists = false
            Chef::Log.debug("#{new_resource} group does not exist")
          end

          if group_info
            group_info.each_line do |line|
              key, val = line.split(": ")
              val.strip! if val
              case key.downcase
              when "primarygroupid"
                new_resource.gid(val) unless new_resource.gid
                current_resource.gid(val)
              when "groupmembership"
                current_resource.members(val.split(" "))
              end
            end
          end

          current_resource
        end

        # get a free GID greater than 200
        def get_free_gid(search_limit = 1000)
          gid = nil; next_gid_guess = 200
          groups_gids = safe_dscl("list", "/Groups", "gid")
          while next_gid_guess < search_limit + 200
            if groups_gids =~ Regexp.new("#{Regexp.escape(next_gid_guess.to_s)}\n")
              next_gid_guess += 1
            else
              gid = next_gid_guess
              break
            end
          end
          gid || raise("gid not found. Exhausted. Searched #{search_limit} times")
        end

        def gid_used?(gid)
          return false unless gid
          groups_gids = safe_dscl("list", "/Groups", "gid")
          !!( groups_gids =~ Regexp.new("#{Regexp.escape(gid.to_s)}\n") )
        end

        def set_gid
          new_resource.gid(get_free_gid) if [nil, ""].include? new_resource.gid
          raise(Chef::Exceptions::Group, "gid is already in use") if gid_used?(new_resource.gid)
          safe_dscl("create", "/Groups/#{new_resource.group_name}", "PrimaryGroupID", new_resource.gid)
        end

        def set_members
          # First reset the memberships if the append is not set
          unless new_resource.append
            Chef::Log.debug("#{new_resource} removing group members #{current_resource.members.join(' ')}") unless current_resource.members.empty?
            safe_dscl("create", "/Groups/#{new_resource.group_name}", "GroupMembers", "") # clear guid list
            safe_dscl("create", "/Groups/#{new_resource.group_name}", "GroupMembership", "") # clear user list
            current_resource.members([ ])
          end

          # Add any members that need to be added
          if new_resource.members && !new_resource.members.empty?
            members_to_be_added = [ ]
            new_resource.members.each do |member|
              members_to_be_added << member unless current_resource.members.include?(member)
            end
            unless members_to_be_added.empty?
              Chef::Log.debug("#{new_resource} setting group members #{members_to_be_added.join(', ')}")
              safe_dscl("append", "/Groups/#{new_resource.group_name}", "GroupMembership", *members_to_be_added)
            end
          end

          # Remove any members that need to be removed
          if new_resource.excluded_members && !new_resource.excluded_members.empty?
            members_to_be_removed = [ ]
            new_resource.excluded_members.each do |member|
              members_to_be_removed << member if current_resource.members.include?(member)
            end
            unless members_to_be_removed.empty?
              Chef::Log.debug("#{new_resource} removing group members #{members_to_be_removed.join(', ')}")
              safe_dscl("delete", "/Groups/#{new_resource.group_name}", "GroupMembership", *members_to_be_removed)
            end
          end
        end

        def define_resource_requirements
          super
          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exist?("/usr/bin/dscl") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/bin/dscl for #{new_resource.name}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        def create_group
          dscl_create_group
          set_gid
          set_members
        end

        def manage_group
          if new_resource.group_name && (current_resource.group_name != new_resource.group_name)
            dscl_create_group
          end
          if new_resource.gid && (current_resource.gid != new_resource.gid)
            set_gid
          end
          if new_resource.members || new_resource.excluded_members
            set_members
          end
        end

        def dscl_create_group
          safe_dscl("create", "/Groups/#{new_resource.group_name}")
          safe_dscl("create", "/Groups/#{new_resource.group_name}", "Password", "*")
        end

        def remove_group
          safe_dscl("delete", "/Groups/#{new_resource.group_name}")
        end
      end
    end
  end
end
