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
  module Win32
    module Security
      class ACE

        include Chef::Win32::Memory
        include Chef::Win32::Security

        def initialize(pointer, owner = nil)
          if ACE_WITH_MASK_AND_SID.supports?(pointer.read_uchar)
            @struct = ACE_WITH_MASK_AND_SID.new pointer
          else
            # TODO Support ALL the things
            @struct = ACE_HEADER.new pointer
          end
          # Keep a reference to the actual owner of this memory so we don't get freed
          @owner = owner
        end

        def self.size_with_sid(sid)
          ACE_WITH_MASK_AND_SID.offset_of(:SidStart) + sid.size
        end

        def self.access_allowed(sid, access_mask, flags = 0)
          create_ace_with_mask_and_sid(ACCESS_ALLOWED_ACE_TYPE, flags, access_mask, sid)
        end

        def self.access_denied(sid, access_mask, flags = 0)
          create_ace_with_mask_and_sid(ACCESS_DENIED_ACE_TYPE, flags, access_mask, sid)
        end

        attr_reader :struct

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
          (struct[:AceFlags] & INHERITED_ACE) != 0
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
          SID.new(struct.pointer + struct.offset_of(:SidStart))
        end

        def type
          struct[:AceType]
        end

        private

        def self.create_ace_with_mask_and_sid(type, flags, mask, sid)
          size_needed = size_with_sid(sid)
          pointer = FFI::MemoryPointer.new size_needed
          struct = ACE_WITH_MASK_AND_SID.new pointer
          struct[:AceType] = type
          struct[:AceFlags] = flags
          struct[:AceSize] = size_needed
          struct[:Mask] = mask
          memcpy(struct.pointer + struct.offset_of(:SidStart), sid.pointer, sid.size)
          ACE.new(struct.pointer)
        end
      end
    end
  end
end