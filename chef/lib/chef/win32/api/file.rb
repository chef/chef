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
require 'chef/win32/api/security'
require 'chef/win32/api/system'

class Chef
  module Win32
    module API
      module File
        extend Chef::Win32::API
        include Chef::Win32::API::Security
        include Chef::Win32::API::System

        ###############################################
        # Win32 API Constants
        ###############################################

        FILE_ATTRIBUTE_READONLY            = 0x00000001
        FILE_ATTRIBUTE_HIDDEN              = 0x00000002
        FILE_ATTRIBUTE_SYSTEM              = 0x00000004
        FILE_ATTRIBUTE_DIRECTORY           = 0x00000010
        FILE_ATTRIBUTE_ARCHIVE             = 0x00000020
        FILE_ATTRIBUTE_DEVICE              = 0x00000040
        FILE_ATTRIBUTE_NORMAL              = 0x00000080
        FILE_ATTRIBUTE_TEMPORARY           = 0x00000100
        FILE_ATTRIBUTE_SPARSE_FILE         = 0x00000200
        FILE_ATTRIBUTE_REPARSE_POINT       = 0x00000400
        FILE_ATTRIBUTE_COMPRESSED          = 0x00000800
        FILE_ATTRIBUTE_OFFLINE             = 0x00001000
        FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = 0x00002000
        FILE_ATTRIBUTE_ENCRYPTED           = 0x00004000
        FILE_ATTRIBUTE_VIRTUAL             = 0x00010000
        INVALID_FILE_ATTRIBUTES            = 0xFFFFFFFF

        IO_REPARSE_TAG_SYMLINK = 0xA000000C
        INVALID_HANDLE_VALUE = 0xFFFFFFFF
        MAX_PATH = 260

        SYMBOLIC_LINK_FLAG_DIRECTORY = 0x1

        FILE_NAME_NORMALIZED = 0x0
        FILE_NAME_OPENED = 0x8

        # TODO add the rest of these CONSTS
        FILE_SHARE_READ = 0x00000001
        OPEN_EXISTING = 3

        ###############################################
        # Win32 API Bindings
        ###############################################

        ffi_lib 'kernel32'

=begin
typedef struct _FILETIME {
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} FILETIME, *PFILETIME;
=end
        class FILETIME < FFI::Struct
          layout :dw_low_date_time, :DWORD,
          :dw_high_date_time, :DWORD
        end

=begin
typedef struct _SECURITY_ATTRIBUTES {
  DWORD  nLength;
  LPVOID lpSecurityDescriptor;
  BOOL   bInheritHandle;
} SECURITY_ATTRIBUTES, *PSECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;
=end
        class SECURITY_ATTRIBUTES < FFI::Struct
          layout :n_length, :DWORD,
          :lp_security_descriptor, :LPVOID,
          :b_inherit_handle, :DWORD
        end

=begin
typedef struct _WIN32_FIND_DATA {
  DWORD    dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  DWORD    nFileSizeHigh;
  DWORD    nFileSizeLow;
  DWORD    dwReserved0;
  DWORD    dwReserved1;
  TCHAR    cFileName[MAX_PATH];
  TCHAR    cAlternateFileName[14];
} WIN32_FIND_DATA, *PWIN32_FIND_DATA, *LPWIN32_FIND_DATA;
=end
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
          :c_alternate_file_name, [:BYTE, 14]
        end

=begin
typedef struct _BY_HANDLE_FILE_INFORMATION {
  DWORD    dwFileAttributes;
  FILETIME ftCreationTime;
  FILETIME ftLastAccessTime;
  FILETIME ftLastWriteTime;
  DWORD    dwVolumeSerialNumber;
  DWORD    nFileSizeHigh;
  DWORD    nFileSizeLow;
  DWORD    nNumberOfLinks;
  DWORD    nFileIndexHigh;
  DWORD    nFileIndexLow;
} BY_HANDLE_FILE_INFORMATION, *PBY_HANDLE_FILE_INFORMATION;
=end
        class BY_HANDLE_FILE_INFORMATION < FFI::Struct
          layout :dw_file_attributes, :DWORD,
          :ft_creation_time, FILETIME,
          :ft_last_access_time, FILETIME,
          :ft_last_write_time, FILETIME,
          :dw_volume_serial_number, :DWORD,
          :n_file_size_high, :DWORD,
          :n_file_size_low, :DWORD,
          :n_number_of_links, :DWORD,
          :n_file_index_high, :DWORD,
          :n_file_index_low, :DWORD
        end

=begin
HANDLE WINAPI CreateFile(
  __in      LPCTSTR lpFileName,
  __in      DWORD dwDesiredAccess,
  __in      DWORD dwShareMode,
  __in_opt  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
  __in      DWORD dwCreationDisposition,
  __in      DWORD dwFlagsAndAttributes,
  __in_opt  HANDLE hTemplateFile
);
=end
        attach_function :CreateFileW, [:LPCTSTR, :DWORD, :DWORD, :LPSECURITY_ATTRIBUTES, :DWORD, :DWORD, :pointer], :HANDLE

=begin
BOOL WINAPI FindClose(
  __inout  HANDLE hFindFile
);
=end
        attach_function :FindClose, [:HANDLE], :BOOL

=begin
DWORD WINAPI GetFileAttributes(
  __in  LPCTSTR lpFileName
);
=end
        attach_function :GetFileAttributesW, [:LPCWSTR], :DWORD

=begin
DWORD WINAPI GetFinalPathNameByHandle(
  __in   HANDLE hFile,
  __out  LPTSTR lpszFilePath,
  __in   DWORD cchFilePath,
  __in   DWORD dwFlags
);
=end
        attach_function :GetFinalPathNameByHandleW, [:HANDLE, :LPTSTR, :DWORD, :DWORD], :DWORD

=begin
BOOL WINAPI GetFileInformationByHandle(
  __in   HANDLE hFile,
  __out  LPBY_HANDLE_FILE_INFORMATION lpFileInformation
);
=end
        attach_function :GetFileInformationByHandle, [:HANDLE, :LPBY_HANDLE_FILE_INFORMATION], :BOOL

=begin
HANDLE WINAPI FindFirstFile(
  __in   LPCTSTR lpFileName,
  __out  LPWIN32_FIND_DATA lpFindFileData
);
=end
        attach_function :FindFirstFileW, [:LPCTSTR, :LPWIN32_FIND_DATA], :HANDLE

=begin
BOOL WINAPI CreateHardLink(
  __in        LPCTSTR lpFileName,
  __in        LPCTSTR lpExistingFileName,
  __reserved  LPSECURITY_ATTRIBUTES lpSecurityAttributes
);
=end
        attach_function :CreateHardLinkW, [:LPCTSTR, :LPCTSTR, :LPSECURITY_ATTRIBUTES], :BOOLEAN

=begin
BOOLEAN WINAPI CreateSymbolicLink(
  __in  LPTSTR lpSymlinkFileName,
  __in  LPTSTR lpTargetFileName,
  __in  DWORD dwFlags
);
=end
        attach_function :CreateSymbolicLinkW, [:LPTSTR, :LPTSTR, :DWORD], :BOOLEAN

=begin
DWORD WINAPI GetLongPathName(
  __in   LPCTSTR lpszShortPath,
  __out  LPTSTR lpszLongPath,
  __in   DWORD cchBuffer
);
=end
        attach_function :GetLongPathNameW, [:LPCTSTR, :LPTSTR, :DWORD], :DWORD

=begin
DWORD WINAPI GetShortPathName(
  __in   LPCTSTR lpszLongPath,
  __out  LPTSTR lpszShortPath,
  __in   DWORD cchBuffer
);
=end
        attach_function :GetShortPathNameW, [:LPCTSTR, :LPTSTR, :DWORD], :DWORD

        ###############################################
        # Helpers
        ###############################################

        # takes the given path pre-pends "\\?\" and
        # UTF-16LE encodes it.  Used to prepare paths
        # to be passed to the *W vesion of WinAPI File
        # functions
        def encode_path(path)
          path.gsub!(::File::SEPARATOR, ::File::ALT_SEPARATOR)
          (path_prepender << path).to_wstring
        end

        def path_prepender
          "\\\\?\\"
        end

        # retrieves a file search handle and passes it
        # to +&block+ along with the find_data.  also
        # ensures the handle is closed on exit of the block
        def file_search_handle(path, &block)
          begin
            path = encode_path(path)
            find_data = WIN32_FIND_DATA.new
            handle = FindFirstFileW(path, find_data)
            if handle == INVALID_HANDLE_VALUE
              Chef::Win32::Error.raise!
            end
            block.call(handle, find_data)
          ensure
            FindClose(handle) if handle && handle != INVALID_HANDLE_VALUE
          end
        end

        # retrieves a file handle and passes it
        # to +&block+ along with the find_data.  also
        # ensures the handle is closed on exit of the block
        def file_handle(path, &block)
          begin
            path = encode_path(path)
            handle = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ,
                                  nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nil)

            if handle == INVALID_HANDLE_VALUE
              Chef::Win32::Error.raise!
            end
            block.call(handle)
          ensure
            CloseHandle(handle) if handle && handle != INVALID_HANDLE_VALUE
          end
        end

        def retrieve_file_info(file_name)
          file_information = nil
          file_handle(file_name) do |handle|
            file_information = BY_HANDLE_FILE_INFORMATION.new
            success = GetFileInformationByHandle(handle, file_information)
            if success == 0
              Chef::Win32::Error.raise!
            end
          end
          file_information
        end

      end
    end
  end
end
