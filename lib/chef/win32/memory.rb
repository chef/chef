#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "chef/win32/error"
require "chef/win32/api/memory"

class Chef
  module ReservedNames::Win32
    class Memory
      include Chef::ReservedNames::Win32::API::Memory
      extend Chef::ReservedNames::Win32::API::Memory

      # local_alloc(length[, flags]) [BLOCK]
      # Allocates memory using LocalAlloc
      # If BLOCK is specified, the memory will be passed
      # to the block and freed afterwards.
      def self.local_alloc(length, flags = LPTR, &block)
        result = LocalAlloc(flags, length)
        if result.null?
          Chef::ReservedNames::Win32::Error.raise!
        end
        # If a block is passed, handle freeing the memory at the end
        if !block.nil?
          begin
            yield result
          ensure
            local_free(result)
          end
        else
          result
        end
      end

      # local_discard(pointer)
      # Discard memory.  Equivalent to local_realloc(pointer, 0)
      def self.local_discard(pointer)
        local_realloc(pointer, 0, LMEM_MOVEABLE)
      end

      # local_flags(pointer)
      # Get lock count and Windows flags for local_alloc allocated memory.
      # Use: flags, lock_count = local_flags(pointer)
      def self.local_flags(pointer)
        result = LocalFlags(pointer)
        if result == LMEM_INVALID_HANDLE
          Chef::ReservedNames::Win32::Error.raise!
        end
        [ result & ~LMEM_LOCKCOUNT, result & LMEM_LOCKCOUNT ]
      end

      # local_free(pointer)
      # Free memory allocated using local_alloc
      def self.local_free(pointer)
        result = LocalFree(pointer)
        if !result.null?
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

      # local_realloc(pointer, size[, flags])
      # Resizes memory allocated using LocalAlloc.
      def self.local_realloc(pointer, size, flags = LMEM_MOVEABLE | LMEM_ZEROINIT)
        result = LocalReAlloc(pointer, size, flags)
        if result.null?
          Chef::ReservedNames::Win32::Error.raise!
        end
        result
      end

      # local_size(pointer)
      # Gets the size of memory allocated using LocalAlloc.
      def self.local_size(pointer)
        result = LocalSize(pointer)
        if result == 0
          Chef::ReservedNames::Win32::Error.raise!
        end
        result
      end

      def self.local_free_finalizer(pointer)
        proc { local_free(pointer) }
      end

    end
  end
end
