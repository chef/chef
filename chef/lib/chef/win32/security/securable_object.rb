#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright 2011 Opscode, Inc.
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

require 'chef/win32/security'
require 'chef/win32/security/acl'
require 'chef/win32/security/sid'

class Chef
  module Win32
    class Security
      class SecurableObject

        def initialize(path, type = :SE_FILE_OBJECT)
          @path = path
          @type = type
        end

        attr_reader :path
        attr_reader :type

        SecurityConst = Chef::Win32::API::Security

        # This method predicts what the rights mask would be on an object
        # if you created an ACE with the given mask.  Specifically, it looks for
        # generic attributes like GENERIC_READ, and figures out what specific
        # attributes will be set.  This is important if you want to try to
        # compare an existing ACE with one you want to create.
        def predict_rights_mask(generic_mask)
          mask = generic_mask
          #mask |= Chef::Win32::API::Security::STANDARD_RIGHTS_READ if (mask | Chef::Win32::API::Security::GENERIC_READ) != 0
          #mask |= Chef::Win32::API::Security::STANDARD_RIGHTS_WRITE if (mask | Chef::Win32::API::Security::GENERIC_WRITE) != 0
          #mask |= Chef::Win32::API::Security::STANDARD_RIGHTS_EXECUTE if (mask | Chef::Win32::API::Security::GENERIC_EXECUTE) != 0
          #mask |= Chef::Win32::API::Security::STANDARD_RIGHTS_ALL if (mask | Chef::Win32::API::Security::GENERIC_ALL) != 0
          if type == :SE_FILE_OBJECT
            mask |= Chef::Win32::API::Security::FILE_GENERIC_READ if (mask & Chef::Win32::API::Security::GENERIC_READ) != 0
            mask |= Chef::Win32::API::Security::FILE_GENERIC_WRITE if (mask & Chef::Win32::API::Security::GENERIC_WRITE) != 0
            mask |= Chef::Win32::API::Security::FILE_GENERIC_EXECUTE if (mask & Chef::Win32::API::Security::GENERIC_EXECUTE) != 0
            mask |= Chef::Win32::API::Security::FILE_ALL_ACCESS if (mask & Chef::Win32::API::Security::GENERIC_ALL) != 0
          else
            raise "Unimplemented object type for predict_security_mask: #{type}"
          end
          mask &= ~(Chef::Win32::API::Security::GENERIC_READ | Chef::Win32::API::Security::GENERIC_WRITE | Chef::Win32::API::Security::GENERIC_EXECUTE | Chef::Win32::API::Security::GENERIC_ALL)
          mask
        end

        def security_descriptor(include_sacl = false)
          security_information = Chef::Win32::API::Security::OWNER_SECURITY_INFORMATION | Chef::Win32::API::Security::GROUP_SECURITY_INFORMATION | Chef::Win32::API::Security::DACL_SECURITY_INFORMATION
          security_information |= Chef::Win32::API::Security::SACL_SECURITY_INFORMATION if include_sacl
          Security.get_named_security_info(path, type, security_information)
        end

        def dacl=(val)
          Security.set_named_security_info(path, type, :dacl => val)
        end

        # You don't set dacl_inherits without also setting dacl,
        # because Windows gets angry and denies you access.  So
        # if you want to do that, you may as well do both at once.
        def set_dacl(dacl, dacl_inherits)
          Security.set_named_security_info(path, type, :dacl => dacl, :dacl_inherits => dacl_inherits)
        end

        def group=(val)
          Security.set_named_security_info(path, type, :group => val)
        end

        def owner=(val)
          Security.set_named_security_info(path, type, :owner => val)
        end

        def sacl=(val)
          Security.set_named_security_info(path, type, :sacl => val)
        end

        def set_sacl(sacl, sacl_inherits)
          Security.set_named_security_info(path, type, :sacl => sacl, :sacl_inherits => sacl_inherits)
        end
      end
    end
  end
end
