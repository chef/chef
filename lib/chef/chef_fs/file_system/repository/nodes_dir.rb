#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
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

require_relative "node"
require_relative "directory"
require_relative "../exceptions"
require_relative "../../../win32/security" if ChefUtils.windows?

class Chef
  module ChefFS
    module FileSystem
      module Repository
        class NodesDir < Repository::Directory

          def make_child_entry(child_name)
            Node.new(child_name, self)
          end

          def create_child(child_name, file_contents = nil)
            child = super
            File.chmod(0600, child.file_path)
            if ChefUtils.windows?
              read_mask = Chef::ReservedNames::Win32::API::Security::GENERIC_READ
              write_mask = Chef::ReservedNames::Win32::API::Security::GENERIC_WRITE
              administrators = Chef::ReservedNames::Win32::Security::SID.Administrators
              owner = Chef::ReservedNames::Win32::Security::SID.default_security_object_owner
              dacl = Chef::ReservedNames::Win32::Security::ACL.create([
                Chef::ReservedNames::Win32::Security::ACE.access_allowed(owner, read_mask),
                Chef::ReservedNames::Win32::Security::ACE.access_allowed(owner, write_mask),
                Chef::ReservedNames::Win32::Security::ACE.access_allowed(administrators, read_mask),
                Chef::ReservedNames::Win32::Security::ACE.access_allowed(administrators, write_mask),
              ])
              so = Chef::ReservedNames::Win32::Security::SecurableObject.new(child.file_path)
              so.owner = owner
              so.set_dacl(dacl, false)
            end
            child
          end
        end
      end
    end
  end
end
