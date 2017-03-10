#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

require "chef/provider/user"
if RUBY_PLATFORM =~ /mswin|mingw32|windows/
  require "chef/util/windows/net_group"
end

class Chef
  class Provider
    class Group
      class Windows < Chef::Provider::Group

        provides :group, os: "windows"

        def initialize(new_resource, run_context)
          super
          @net_group = Chef::Util::Windows::NetGroup.new(new_resource.group_name)
        end

        def load_current_resource
          @current_resource = Chef::Resource::Group.new(new_resource.name)
          current_resource.group_name(new_resource.group_name)

          members = nil
          begin
            members = @net_group.local_get_members
          rescue
            @group_exists = false
            Chef::Log.debug("#{new_resource} group does not exist")
          end

          if members
            current_resource.members(members)
          end

          current_resource
        end

        def create_group
          @net_group.local_add
          manage_group
        end

        def manage_group
          if new_resource.append
            members_to_be_added = [ ]
            new_resource.members.each do |member|
              members_to_be_added << member if !has_current_group_member?(member) && validate_member!(member)
            end

            # local_add_members will raise ERROR_MEMBER_IN_ALIAS if a
            # member already exists in the group.
            @net_group.local_add_members(members_to_be_added) unless members_to_be_added.empty?

            members_to_be_removed = [ ]
            new_resource.excluded_members.each do |member|
              lookup_account_name(member)
              members_to_be_removed << member if has_current_group_member?(member)
            end
            @net_group.local_delete_members(members_to_be_removed) unless members_to_be_removed.empty?
          else
            @net_group.local_set_members(new_resource.members)
          end
        end

        def has_current_group_member?(member)
          member_sid = lookup_account_name(member)
          current_resource.members.include?(member_sid)
        end

        def remove_group
          @net_group.local_delete
        end

        def locally_qualified_name(account_name)
          account_name.include?("\\") ? account_name : "#{ENV['COMPUTERNAME']}\\#{account_name}"
        end

        def validate_member!(member)
          Chef::ReservedNames::Win32::Security.lookup_account_name(locally_qualified_name(member))[1].to_s
        end

        def lookup_account_name(account_name)
          Chef::ReservedNames::Win32::Security.lookup_account_name(locally_qualified_name(account_name))[1].to_s
        rescue Chef::Exceptions::Win32APIError
          Chef::Log.warn("SID for '#{locally_qualified_name(account_name)}' could not be found")
          ""
        end

      end
    end
  end
end
