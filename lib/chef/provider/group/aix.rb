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

require "chef/provider/group/groupadd"

class Chef
  class Provider
    class Group
      class Aix < Chef::Provider::Group::Groupadd
        provides :group, platform: "aix"

        def required_binaries
          [ "/usr/bin/mkgroup",
            "/usr/bin/chgroup",
            "/usr/bin/chgrpmem",
            "/usr/sbin/rmgroup" ]
        end

        def create_group
          shell_out_compact!("mkgroup", set_options, new_resource.group_name)
          modify_group_members
        end

        def manage_group
          options = set_options
          if options.size > 0
            shell_out_compact!("chgroup", options, new_resource.group_name)
          end
          modify_group_members
        end

        def remove_group
          shell_out_compact!("rmgroup", new_resource.group_name)
        end

        def add_member(member)
          shell_out_compact!("chgrpmem", "-m", "+", member, new_resource.group_name)
        end

        def set_members(members)
          return if members.empty?
          shell_out_compact!("chgrpmem", "-m", "=", members.join(","), new_resource.group_name)
        end

        def remove_member(member)
          shell_out_compact!("chgrpmem", "-m", "-", member, new_resource.group_name)
        end

        def set_options
          opts = []
          { gid: "id" }.sort { |a, b| a[0] <=> b[0] }.each do |field, option|
            next unless current_resource.send(field) != new_resource.send(field)
            if new_resource.send(field)
              Chef::Log.debug("#{new_resource} setting #{field} to #{new_resource.send(field)}")
              opts << "#{option}=#{new_resource.send(field)}"
            end
          end
          opts
        end

      end
    end
  end
end
