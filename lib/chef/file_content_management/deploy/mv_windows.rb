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

require 'chef/platform/query_helpers'
if Chef::Platform.windows?
  require 'chef/win32/security'
end

class Chef
  class FileContentManagement
    class Deploy
      class MvWindows

        Security = Chef::ReservedNames::Win32::Security
        ACL = Security::ACL

        def create(file)
          Chef::Log.debug("touching #{file} to create it")
          FileUtils.touch(file)
        end

        def deploy(src, dst)
          #
          # At the time of deploy ACLs are correctly configured on the
          # dst. This would be a simple atomic move operations in
          # windows was not converting inherited ACLs of src to
          # non-inherited ACLs in certain cases.See:
          # http://blogs.msdn.com/b/oldnewthing/archive/2006/08/24/717181.aspx
          #

          #
          # First cache the ACLs of dst file
          #

          dst_so = Security::SecurableObject.new(dst)
          begin
            # get the sd with the SACL
            dst_sd = dst_so.security_descriptor(true)
          rescue Chef::Exceptions::Win32APIError
            # Catch and raise if the user is not elevated enough.
            # At this point we can't configure the file as expected so
            # we're failing action on the resource.
            raise Chef::Exceptions::WindowsNotAdmin, "can not get the security information for '#{dst}' due to missing Administrator privilages."
          end

          if dst_sd.dacl_present?
            apply_dacl = ACL.create(dst_sd.dacl.select { |ace| !ace.inherited? })
          end

          if dst_sd.sacl_present?
            apply_sacl = ACL.create(dst_sd.sacl.select { |ace| !ace.inherited? })
          end

          #
          # Then deploy the file
          #

          FileUtils.mv(src, dst)

          #
          # Then apply the cached acls to the new dst file
          #

          dst_so = Security::SecurableObject.new(dst)
          dst_so.group = dst_sd.group
          dst_so.owner = dst_sd.owner
          dst_so.set_dacl(apply_dacl, dst_sd.dacl_inherits?) if dst_sd.dacl_present?
          dst_so.set_sacl(apply_sacl, dst_sd.sacl_inherits?) if dst_sd.sacl_present?

        end
      end
    end
  end
end

