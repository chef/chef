#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/repository/node"
require "chef/chef_fs/file_system/repository/directory"
require "chef/chef_fs/file_system/exceptions"
require "chef/win32/security" if Chef::Platform.windows?

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
            if Chef::Platform.windows?
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
