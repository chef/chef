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

class Chef
  module Win32
    class Security
      class SID

        def initialize(pointer, owner = nil)
          @pointer = pointer
          # Keep a reference to the actual owner of this memory so we don't get freed
          @owner = owner
        end

        def self.from_account(name)
          domain, sid, use = Chef::Win32::Security.lookup_account_name(name)
          sid
        end

        def self.from_string_sid(string_sid)
          Chef::Win32::Security::convert_string_sid_to_sid(string_sid)
        end

        def ==(other)
          other != nil && Chef::Win32::Security.equal_sid(self, other)
        end

        attr_reader :pointer

        def account
          Chef::Win32::Security.lookup_account_sid(self)
        end

        def account_name
          domain, name, use = account
          (domain != nil && domain.length > 0) ? "#{domain}\\#{name}" : name
        end

        def size
          Chef::Win32::Security.get_length_sid(self)
        end

        def to_s
          Chef::Win32::Security.convert_sid_to_string_sid(self)
        end

        def valid?
          Chef::Win32::Security.is_valid_sid(self)
        end
      end
    end
  end
end