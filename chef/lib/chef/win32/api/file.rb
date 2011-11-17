#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@ospcode.com>)
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
  module Win32
    module API
      module File

        extend Chef::Win32::API

        FILE_ATTRIBUTE_REPARSE_POINT = 0x400
        IO_REPARSE_TAG_SYMLINK = 0xA000000C
        INVALID_FILE_ATTRIBUTES = 0xFFFFFFFF
        INVALID_HANDLE_VALUE = 0xFFFFFFFF
        MAX_PATH = 260

        class FILETIME < FFI::Struct
          layout :dw_low_date_time, :DWORD,
          :dw_high_date_time, :DWORD,
        end

        class WIN32_FIND_DATA < FFI::Struct
          layout :dw_file_attributes, :DWORD,
          :ft_creation_time, FILETIME,
          :ft_last_access_time, FILETIME,
          :ft_last_write_time, FILETIME,
          :n_file_size_high, :DWORD,
          :n_file_size_low, :DWORD,
          :dw_reserved_0, :DWORD,
          :dw_reserved_1, :DWORD,
          :c_file_name, [:BYTE, MAX_PATH*2],
          :c_alternate_file_name, [:BYTE, 14],
        end

=begin
DWORD WINAPI GetFileAttributes(
  __in  LPCTSTR lpFileName
);
=end
        attach_function :GetFileAttributesA, [:pointer], :DWORD
        attach_function :GetFileAttributesW, [:pointer], :DWORD
=begin
HANDLE WINAPI FindFirstFile(
  __in   LPCTSTR lpFileName,
  __out  LPWIN32_FIND_DATA lpFindFileData
);
=end
        attach_function :FindFirstFileA, [:pointer, :pointer], :ulong
        attach_function :FindFirstFileW, [:pointer, :pointer], :ulong

      end
    end
  end
end
