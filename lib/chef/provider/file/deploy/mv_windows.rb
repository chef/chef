#
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

#
# We update the contents of the file, using mv for atomicity, while maintaining all the
# ACL information on the dst file.
#

require 'chef/win32/security'

class Chef
  class Provider
    class File
      class Deploy
        class MvWindows
          def create(file)
            Chef::Log.debug("touching #{file} to create it")
            FileUtils.touch(file)
          end

          ALL_ACLS =
            Chef::ReservedNames::Win32::Security::OWNER_SECURITY_INFORMATION |
            Chef::ReservedNames::Win32::Security::GROUP_SECURITY_INFORMATION |
            Chef::ReservedNames::Win32::Security::DACL_SECURITY_INFORMATION
            #Chef::ReservedNames::Win32::Security::SACL_SECURITY_INFORMATION

          def deploy(src, dst)
            result = Chef::ReservedNames::Win32::Security.get_named_security_info(dst, :SE_FILE_OBJECT, ALL_ACLS)

            Chef::Log.debug("applying owner #{result.owner} to staged file")
            Chef::Log.debug("applying group #{result.group} to staged file")
            Chef::Log.debug("applying dacl #{result.dacl} to staged file")
            Chef::Log.debug("applying dacl inheritance to staged file") if result.dacl_inherits?

            # FIXME: SACL
            # FIXME: inheritance
            # FIXME: control?
            # FIXME: filter out inherited DACLs

            so = Chef::ReservedNames::Win32::Security::SecurableObject.new(src)

            so.set_dacl(result.dacl, result.dacl_inherits?)

            so.group = result.group

            so.owner = result.owner

            #so.set_sacl(result.sacl, result.sacl_inherits?)

            FileUtils.mv(src, dst)
          end
        end
      end
    end
  end
end
