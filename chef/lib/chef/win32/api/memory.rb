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

require 'chef/win32/api'

class Chef
  module ReservedNames::Win32
    module API
      module Memory
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Constants
        ###############################################

        LMEM_FIXED          = 0x0000
        LMEM_MOVEABLE       = 0x0002
        LMEM_NOCOMPACT      = 0x0010
        LMEM_NODISCARD      = 0x0020
        LMEM_ZEROINIT       = 0x0040
        LMEM_MODIFY         = 0x0080
        LMEM_DISCARDABLE    = 0x0F00
        LMEM_VALID_FLAGS    = 0x0F72
        LMEM_INVALID_HANDLE = 0x8000
        LHND                = LMEM_MOVEABLE | LMEM_ZEROINIT
        LPTR                = LMEM_FIXED | LMEM_ZEROINIT
        NONZEROLHND         = LMEM_MOVEABLE
        NONZEROLPTR         = LMEM_FIXED
        LMEM_DISCARDED      = 0x4000
        LMEM_LOCKCOUNT      = 0x00FF

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'kernel32'

=begin
HLOCAL WINAPI LocalAlloc(
  __in  UINT uFlags,
  __in  SIZE_T uBytes
);
=end
        attach_function :LocalAlloc, [ :UINT, :SIZE_T ], :pointer

=begin
UINT WINAPI LocalFlags(
  __in  HLOCAL hMem
);
=end
        attach_function :LocalFlags, [ :pointer ], :UINT

=begin
HLOCAL WINAPI LocalFree(
  __in  HLOCAL hMem
);
=end
        attach_function :LocalFree, [ :pointer ], :pointer

=begin
HLOCAL WINAPI LocalReAlloc(
  __in  HLOCAL hMem,
  __in  SIZE_T uBytes,
  __in  UINT uFlags
);
=end
        attach_function :LocalReAlloc, [ :pointer, :SIZE_T, :UINT ], :pointer

=begin
UINT WINAPI LocalSize(
  __in  HLOCAL hMem
);
=end
        attach_function :LocalSize, [ :pointer ], :SIZE_T

        ###############################################
        # FFI API Bindings
        ###############################################

        ffi_lib FFI::Library::LIBC
        attach_function :malloc, [:size_t], :pointer
        attach_function :calloc, [:size_t], :pointer
        attach_function :realloc, [:pointer, :size_t], :pointer
        attach_function :free, [:pointer], :void
        attach_function :memcpy, [:pointer, :pointer, :size_t], :pointer

      end
    end
  end
end
