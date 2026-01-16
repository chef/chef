#
# Author:: Joshua Justice (<jjustice6@bloomberg.net>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "groupadd"

class Chef
  class Provider
    class Group
      class Solaris < Chef::Provider::Group::Groupadd

        # this provides line is setup to only catch the solaris2 platform, but
        # NOT other platforms in the Solaris platform_family. (See usermod provider.)
        provides :group, platform: "solaris2", target_mode: true

        def load_current_resource
          super
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ::TargetIO::File.exist?("/usr/sbin/usermod") && ::TargetIO::File.exist?("/usr/sbin/groupmod") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/usermod or /usr/sbin/groupmod for #{new_resource}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        def set_members(members)
          # Set the group to have exactly the list of members passed to it.
          unless members.empty?
            shell_out!("groupmod", "-U", members.join(","), new_resource.group_name)
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
