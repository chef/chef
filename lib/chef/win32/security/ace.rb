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
require 'chef/win32/security/sid'
require 'chef/win32/memory'

require 'ffi'

class Chef
  module ReservedNames::Win32
    class Security
      class ACE

        def initialize(pointer, owner = nil)
          if Chef::ReservedNames::Win32::API::Security::ACE_WITH_MASK_AND_SID.supports?(pointer.read_uchar)
            @struct = Chef::ReservedNames::Win32::API::Security::ACE_WITH_MASK_AND_SID.new pointer
          else
            # TODO Support ALL the things
            @struct = Chef::ReservedNames::Win32::API::Security::ACE_HEADER.new pointer
          end
          # Keep a reference to the actual owner of this memory so we don't get freed
          @owner = owner
        end

        def self.size_with_sid(sid)
          Chef::ReservedNames::Win32::API::Security::ACE_WITH_MASK_AND_SID.offset_of(:SidStart) + sid.size
        end

        def self.access_allowed(sid, mask, flags = 0)
          create_ace_with_mask_and_sid(Chef::ReservedNames::Win32::API::Security::ACCESS_ALLOWED_ACE_TYPE, flags, mask, sid)
        end

        def self.access_denied(sid, mask, flags = 0)
          create_ace_with_mask_and_sid(Chef::ReservedNames::Win32::API::Security::ACCESS_DENIED_ACE_TYPE, flags, mask, sid)
        end

        attr_reader :struct

        def ==(other)
          type == other.type && flags == other.flags && mask == other.mask && sid == other.sid
        end

        def dup
          ACE.create_ace_with_mask_and_sid(type, flags, mask, sid)
        end

        def flags
          struct[:AceFlags]
        end

        def flags=(val)
          struct[:AceFlags] = val
        end

        def explicit?
          ! inherited?
        end

        def inherited?
          (struct[:AceFlags] & Chef::ReservedNames::Win32::API::Security::INHERITED_ACE) != 0
        end

        def mask
          struct[:Mask]
        end

        def mask=(val)
          struct[:Mask] = val
        end

        def pointer
          struct.pointer
        end

        def size
          struct[:AceSize]
        end

        def sid
          # The SID runs off the end of the structure, starting at :SidStart.
          # Use pointer arithmetic to get a pointer to that location.
          Chef::ReservedNames::Win32::Security::SID.new(struct.pointer + struct.offset_of(:SidStart))
        end

        def to_s
          "#{sid.account_name}/flags:#{flags.to_s(16)}/mask:#{mask.to_s(16)}"
        end

        def type
          struct[:AceType]
        end

        private

        def self.create_ace_with_mask_and_sid(type, flags, mask, sid)
          size_needed = size_with_sid(sid)
          pointer = FFI::MemoryPointer.new size_needed
          struct = Chef::ReservedNames::Win32::API::Security::ACE_WITH_MASK_AND_SID.new pointer
          struct[:AceType] = type
          struct[:AceFlags] = flags
          struct[:AceSize] = size_needed
          struct[:Mask] = mask
          Chef::ReservedNames::Win32::Memory.memcpy(struct.pointer + struct.offset_of(:SidStart), sid.pointer, sid.size)
          ACE.new(struct.pointer)
        end
      end
    end
  end
end