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
    module Security
      class SID

        include Chef::Win32::Security

        def initialize(pointer, owner = nil)
          @pointer = pointer
          # Keep a reference to the actual owner of this memory so we don't get freed
          @owner = owner
        end

        def self.from_account(name)
          domain, sid, use = lookup_account_name(name)
          sid
        end

        attr_reader :pointer

        def account
          lookup_account_sid(self)
        end

        def account_name
          domain, name, use = account
          (domain != nil && domain.length > 0) ? "#{domain}\\#{name}" : name
        end

        def size
          get_length_sid(self)
        end

        def valid?
          is_valid_sid(self)
        end
      end
    end
  end
end