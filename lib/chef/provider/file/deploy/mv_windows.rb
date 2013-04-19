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

          Security = Chef::ReservedNames::Win32::Security
          ACL = Security::ACL

          def create(file)
            Chef::Log.debug("touching #{file} to create it")
            FileUtils.touch(file)
          end

          ALL_ACLS =
            Security::OWNER_SECURITY_INFORMATION |
            Security::GROUP_SECURITY_INFORMATION |
            Security::DACL_SECURITY_INFORMATION |
            Security::SACL_SECURITY_INFORMATION

          def deploy(src, dst)
            dst_so = Security::SecurableObject.new(dst)

            # FIXME: catch exception when we can't elevate privs?
            dst_sd = dst_so.security_descriptor(true)  # get the sd with the SACL

            if dst_sd.dacl_present?
              apply_dacl = ACL.create(dst_sd.dacl.select { |ace| !ace.inherited? })
            end
            if dst_sd.sacl_present?
              apply_sacl = ACL.create(dst_sd.sacl.select { |ace| !ace.inherited? })
            end

            Chef::Log.debug("applying owner #{dst_sd.owner} to staged file")
            Chef::Log.debug("applying group #{dst_sd.group} to staged file")
            Chef::Log.debug("applying dacl #{dst_sd.dacl} to staged file") if dst_sd.dacl_present?
            Chef::Log.debug("applying dacl inheritance to staged file") if dst_sd.dacl_inherits?
            Chef::Log.debug("applying sacl #{dst_sd.sacl} to staged file") if dst_sd.sacl_present?
            Chef::Log.debug("applying sacl inheritance to staged file") if dst_sd.sacl_inherits?

            so = Security::SecurableObject.new(src)

            so.set_dacl(apply_dacl, dst_sd.dacl_inherits?) if dst_sd.dacl_present?

            so.group = dst_sd.group

            so.owner = dst_sd.owner

            so.set_sacl(apply_sacl, dst_sd.sacl_inherits?) if dst_sd.sacl_present?

            FileUtils.mv(src, dst)
          end
        end
      end
    end
  end
end
