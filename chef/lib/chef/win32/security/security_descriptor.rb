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
      class SecurityDescriptor

        include Chef::Win32::Security

        def initialize(pointer)
          @pointer = pointer
        end

        attr_reader :pointer

        def absolute?
          !self_relative?
        end

        def control
          control, version = get_security_descriptor_control(self)
          control
        end

        def dacl
          raise "DACL not present" if !dacl_present?
          present, acl, defaulted = get_security_descriptor_dacl(self)
          acl
        end

        def dacl_inherits?
          (control & SE_DACL_PROTECTED) == 0
        end

        def dacl_present?
          (control & SE_DACL_PRESENT) != 0
        end

        def group
          result, defaulted = get_security_descriptor_group(self)
          result
        end

        def owner
          result, defaulted = get_security_descriptor_owner(self)
          result
        end

        def sacl
          raise "SACL not present" if !sacl_present?
          present, acl, defaulted = get_security_descriptor_sacl(self)
          acl
        end

        def sacl_inherits?
          (control & SE_SACL_PROTECTED) == 0
        end

        def sacl_present?
          (control & SE_SACL_PRESENT) != 0
        end

        def self_relative?
          (control & SE_SELF_RELATIVE) != 0
        end

        def valid?
          is_valid_security_descriptor(self)
        end
      end
    end
  end
end
