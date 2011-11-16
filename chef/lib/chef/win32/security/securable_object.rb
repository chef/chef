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
    module Security
      class SecurableObject

        include Chef::Win32::Security

        def initialize(path, type = :SE_FILE_OBJECT)
          @path = path
          @type = type
        end

        attr_reader :pointer

        def security_descriptor(include_sacl = false)
          security_information = OWNER_SECURITY_INFORMATION | GROUP_SECURITY_INFORMATION | DACL_SECURITY_INFORMATION
          security_information |= SACL_SECURITY_INFORMATION if include_sacl
          get_named_security_info(@path, @type, security_information)
        end

        def dacl=(val)
          set_named_security_info(@path, @type, :dacl => val)
        end

        # You don't set dacl_inherits without also setting dacl,
        # because Windows gets angry and denies you access.  So
        # if you want to do that, you may as well do both at once.
        def set_dacl(dacl, dacl_inherits)
          set_named_security_info(@path, @type, :dacl => dacl, :dacl_inherits => dacl_inherits)
        end

        def group=(val)
          set_named_security_info(@path, @type, :group => val)
        end

        def owner=(val)
          set_named_security_info(@path, @type, :owner => val)
        end

        def sacl=(val)
          set_named_security_info(@path, @type, :sacl => val)
        end

        def set_sacl(sacl, sacl_inherits)
          set_named_security_info(@path, @type, :sacl => sacl, :sacl_inherits => sacl_inherits)
        end
      end
    end
  end
end
