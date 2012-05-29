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
  module ReservedNames::Win32
    class Security
      class SID

        def initialize(pointer, owner = nil)
          @pointer = pointer
          # Keep a reference to the actual owner of this memory so we don't get freed
          @owner = owner
        end

        def self.from_account(name)
          domain, sid, use = Chef::ReservedNames::Win32::Security.lookup_account_name(name)
          sid
        end

        def self.from_string_sid(string_sid)
          Chef::ReservedNames::Win32::Security::convert_string_sid_to_sid(string_sid)
        end

        def ==(other)
          other != nil && Chef::ReservedNames::Win32::Security.equal_sid(self, other)
        end

        attr_reader :pointer

        def account
          Chef::ReservedNames::Win32::Security.lookup_account_sid(self)
        end

        def account_name
          domain, name, use = account
          (domain != nil && domain.length > 0) ? "#{domain}\\#{name}" : name
        end

        def size
          Chef::ReservedNames::Win32::Security.get_length_sid(self)
        end

        def to_s
          Chef::ReservedNames::Win32::Security.convert_sid_to_string_sid(self)
        end

        def valid?
          Chef::ReservedNames::Win32::Security.is_valid_sid(self)
        end

        # Well-known SIDs
        def self.Null
          SID.from_string_sid('S-1-0')
        end
        def self.Nobody
          SID.from_string_sid('S-1-0-0')
        end
        def self.World
          SID.from_string_sid('S-1-1')
        end
        def self.Everyone
          SID.from_string_sid('S-1-1-0')
        end
        def self.Local
          SID.from_string_sid('S-1-2')
        end
        def self.Creator
          SID.from_string_sid('S-1-3')
        end
        def self.CreatorOwner
          SID.from_string_sid('S-1-3-0')
        end
        def self.CreatorGroup
          SID.from_string_sid('S-1-3-1')
        end
        def self.CreatorOwnerServer
          SID.from_string_sid('S-1-3-2')
        end
        def self.CreatorGroupServer
          SID.from_string_sid('S-1-3-3')
        end
        def self.NonUnique
          SID.from_string_sid('S-1-4')
        end
        def self.Nt
          SID.from_string_sid('S-1-5')
        end
        def self.Dialup
          SID.from_string_sid('S-1-5-1')
        end
        def self.Network
          SID.from_string_sid('S-1-5-2')
        end
        def self.Batch
          SID.from_string_sid('S-1-5-3')
        end
        def self.Interactive
          SID.from_string_sid('S-1-5-4')
        end
        def self.Service
          SID.from_string_sid('S-1-5-6')
        end
        def self.Anonymous
          SID.from_string_sid('S-1-5-7')
        end
        def self.Proxy
          SID.from_string_sid('S-1-5-8')
        end
        def self.EnterpriseDomainControllers
          SID.from_string_sid('S-1-5-9')
        end
        def self.PrincipalSelf
          SID.from_string_sid('S-1-5-10')
        end
        def self.AuthenticatedUsers
          SID.from_string_sid('S-1-5-11')
        end
        def self.RestrictedCode
          SID.from_string_sid('S-1-5-12')
        end
        def self.TerminalServerUsers
          SID.from_string_sid('S-1-5-13')
        end
        def self.LocalSystem
          SID.from_string_sid('S-1-5-18')
        end
        def self.NtLocal
          SID.from_string_sid('S-1-5-19')
        end
        def self.NtNetwork
          SID.from_string_sid('S-1-5-20')
        end
        def self.BuiltinAdministrators
          SID.from_string_sid('S-1-5-32-544')
        end
        def self.BuiltinUsers
          SID.from_string_sid('S-1-5-32-545')
        end
        def self.Guests
          SID.from_string_sid('S-1-5-32-546')
        end
        def self.PowerUsers
          SID.from_string_sid('S-1-5-32-547')
        end
        def self.AccountOperators
          SID.from_string_sid('S-1-5-32-548')
        end
        def self.ServerOperators
          SID.from_string_sid('S-1-5-32-549')
        end
        def self.PrintOperators
          SID.from_string_sid('S-1-5-32-550')
        end
        def self.BackupOperators
          SID.from_string_sid('S-1-5-32-551')
        end
        def self.Replicators
          SID.from_string_sid('S-1-5-32-552')
        end
        def self.Administrators
          SID.from_string_sid('S-1-5-32-544')
        end

        # Machine-specific, well-known SIDs
        # TODO: don't use strings, dummy
        def self.None
          SID.from_account("#{::ENV['COMPUTERNAME']}\\None")
        end
        def self.Administrator
          SID.from_account("#{::ENV['COMPUTERNAME']}\\Administrator")
        end
        def self.Guest
          SID.from_account("#{::ENV['COMPUTERNAME']}\\Guest")
        end

        def self.current_user
          SID.from_account("#{::ENV['USERDOMAIN']}\\#{::ENV['USERNAME']}")
        end
      end
    end
  end
end