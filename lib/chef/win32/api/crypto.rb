#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/win32/api"

class Chef
  module ReservedNames::Win32
    module API
      module Crypto
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib "Crypt32"

        CRYPTPROTECT_UI_FORBIDDEN  = 0x1
        CRYPTPROTECT_LOCAL_MACHINE = 0x4
        CRYPTPROTECT_AUDIT         = 0x10

        class CRYPT_INTEGER_BLOB < FFI::Struct
          layout :cbData, :DWORD,   # Count, in bytes, of data
                 :pbData, :pointer  # Pointer to data buffer
          def initialize(str = nil)
            super(nil)
            if str
              self[:pbData] = FFI::MemoryPointer.from_string(str)
              self[:cbData] = str.bytesize
            end
          end

        end

        safe_attach_function :CryptProtectData, [
          :PDATA_BLOB,
          :LPCWSTR,
          :PDATA_BLOB,
          :pointer,
          :PCRYPTPROTECT_PROMPTSTRUCT,
          :DWORD,
          :PDATA_BLOB,
        ], :BOOL

      end
    end
  end
end
