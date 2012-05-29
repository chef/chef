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
  module ReservedNames::Win32
    module API
      module File
        extend Chef::ReservedNames::Win32::API
        include Chef::ReservedNames::Win32::API::Security
        include Chef::ReservedNames::Win32::API::System

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

        FILE_FLAG_WRITE_THROUGH            = 0x80000000
        FILE_FLAG_OVERLAPPED               = 0x40000000
        FILE_FLAG_NO_BUFFERING             = 0x20000000
        FILE_FLAG_RANDOM_ACCESS            = 0x10000000
        FILE_FLAG_SEQUENTIAL_SCAN          = 0x08000000
        FILE_FLAG_DELETE_ON_CLOSE          = 0x04000000
        FILE_FLAG_BACKUP_SEMANTICS         = 0x02000000
        FILE_FLAG_POSIX_SEMANTICS          = 0x01000000
        FILE_FLAG_OPEN_REPARSE_POINT       = 0x00200000
        FILE_FLAG_OPEN_NO_RECALL           = 0x00100000
        FILE_FLAG_FIRST_PIPE_INSTANCE      = 0x00080000

        INVALID_HANDLE_VALUE = 0xFFFFFFFF
        MAX_PATH = 260

        SYMBOLIC_LINK_FLAG_DIRECTORY = 0x1

        FILE_NAME_NORMALIZED = 0x0
        FILE_NAME_OPENED = 0x8

        # TODO add the rest of these CONSTS
        FILE_SHARE_READ = 0x00000001
        OPEN_EXISTING = 3

        # DeviceIoControl control codes
        # -----------------------------
        FILE_DEVICE_BEEP                = 0x00000001
        FILE_DEVICE_CD_ROM              = 0x00000002
        FILE_DEVICE_CD_ROM_FILE_SYSTEM  = 0x00000003
        FILE_DEVICE_CONTROLLER          = 0x00000004
        FILE_DEVICE_DATALINK            = 0x00000005
        FILE_DEVICE_DFS                 = 0x00000006
        FILE_DEVICE_DISK                = 0x00000007
        FILE_DEVICE_DISK_FILE_SYSTEM    = 0x00000008
        FILE_DEVICE_FILE_SYSTEM         = 0x00000009
        FILE_DEVICE_INPORT_PORT         = 0x0000000a
        FILE_DEVICE_KEYBOARD            = 0x0000000b
        FILE_DEVICE_MAILSLOT            = 0x0000000c
        FILE_DEVICE_MIDI_IN             = 0x0000000d
        FILE_DEVICE_MIDI_OUT            = 0x0000000e
        FILE_DEVICE_MOUSE               = 0x0000000f
        FILE_DEVICE_MULTI_UNC_PROVIDER  = 0x00000010
        FILE_DEVICE_NAMED_PIPE          = 0x00000011
        FILE_DEVICE_NETWORK             = 0x00000012
        FILE_DEVICE_NETWORK_BROWSER     = 0x00000013
        FILE_DEVICE_NETWORK_FILE_SYSTEM = 0x00000014
        FILE_DEVICE_NULL                = 0x00000015
        FILE_DEVICE_PARALLEL_PORT       = 0x00000016
        FILE_DEVICE_PHYSICAL_NETCARD    = 0x00000017
        FILE_DEVICE_PRINTER             = 0x00000018
        FILE_DEVICE_SCANNER             = 0x00000019
        FILE_DEVICE_SERIAL_MOUSE_PORT   = 0x0000001a
        FILE_DEVICE_SERIAL_PORT         = 0x0000001b
        FILE_DEVICE_SCREEN              = 0x0000001c
        FILE_DEVICE_SOUND               = 0x0000001d
        FILE_DEVICE_STREAMS             = 0x0000001e
        FILE_DEVICE_TAPE                = 0x0000001f
        FILE_DEVICE_TAPE_FILE_SYSTEM    = 0x00000020
        FILE_DEVICE_TRANSPORT           = 0x00000021
        FILE_DEVICE_UNKNOWN             = 0x00000022
        FILE_DEVICE_VIDEO               = 0x00000023
        FILE_DEVICE_VIRTUAL_DISK        = 0x00000024
        FILE_DEVICE_WAVE_IN             = 0x00000025
        FILE_DEVICE_WAVE_OUT            = 0x00000026
        FILE_DEVICE_8042_PORT           = 0x00000027
        FILE_DEVICE_NETWORK_REDIRECTOR  = 0x00000028
        FILE_DEVICE_BATTERY             = 0x00000029
        FILE_DEVICE_BUS_EXTENDER        = 0x0000002a
        FILE_DEVICE_MODEM               = 0x0000002b
        FILE_DEVICE_VDM                 = 0x0000002c
        FILE_DEVICE_MASS_STORAGE        = 0x0000002d
        FILE_DEVICE_SMB                 = 0x0000002e
        FILE_DEVICE_KS                  = 0x0000002f
        FILE_DEVICE_CHANGER             = 0x00000030
        FILE_DEVICE_SMARTCARD           = 0x00000031
        FILE_DEVICE_ACPI                = 0x00000032
        FILE_DEVICE_DVD                 = 0x00000033
        FILE_DEVICE_FULLSCREEN_VIDEO    = 0x00000034
        FILE_DEVICE_DFS_FILE_SYSTEM     = 0x00000035
        FILE_DEVICE_DFS_VOLUME          = 0x00000036
        FILE_DEVICE_SERENUM             = 0x00000037
        FILE_DEVICE_TERMSRV             = 0x00000038
        FILE_DEVICE_KSEC                = 0x00000039
        FILE_DEVICE_FIPS                = 0x0000003A
        FILE_DEVICE_INFINIBAND          = 0x0000003B
        FILE_DEVICE_VMBUS               = 0x0000003E
        FILE_DEVICE_CRYPT_PROVIDER      = 0x0000003F
        FILE_DEVICE_WPD                 = 0x00000040
        FILE_DEVICE_BLUETOOTH           = 0x00000041
        FILE_DEVICE_MT_COMPOSITE        = 0x00000042
        FILE_DEVICE_MT_TRANSPORT        = 0x00000043
        FILE_DEVICE_BIOMETRIC           = 0x00000044
        FILE_DEVICE_PMI                 = 0x00000045

        # Methods
        METHOD_BUFFERED                 = 0
        METHOD_IN_DIRECT                = 1
        METHOD_OUT_DIRECT               = 2
        METHOD_NEITHER                  = 3
        METHOD_DIRECT_TO_HARDWARE       = METHOD_IN_DIRECT
        METHOD_DIRECT_FROM_HARDWARE     = METHOD_OUT_DIRECT

        # Access
        FILE_ANY_ACCESS                 = 0
        FILE_SPECIAL_ACCESS             = FILE_ANY_ACCESS
        FILE_READ_ACCESS                = 0x0001
        FILE_WRITE_ACCESS               = 0x0002

        def self.CTL_CODE( device_type, function, method, access )
          (device_type << 16) | (access << 14) | (function << 2) | method
        end

        FSCTL_GET_REPARSE_POINT         = CTL_CODE(FILE_DEVICE_FILE_SYSTEM, 42, METHOD_BUFFERED, FILE_ANY_ACCESS)

        # Reparse point tags
        IO_REPARSE_TAG_MOUNT_POINT              = 0xA0000003
        IO_REPARSE_TAG_HSM                      = 0xC0000004
        IO_REPARSE_TAG_HSM2                     = 0x80000006
        IO_REPARSE_TAG_SIS                      = 0x80000007
        IO_REPARSE_TAG_WIM                      = 0x80000008
        IO_REPARSE_TAG_CSV                      = 0x80000009
        IO_REPARSE_TAG_DFS                      = 0x8000000A
        IO_REPARSE_TAG_SYMLINK                  = 0xA000000C
        IO_REPARSE_TAG_DFSR                     = 0x80000012

        MAXIMUM_REPARSE_DATA_BUFFER_SIZE        = 16*1024

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
typedef struct _REPARSE_DATA_BUFFER {
  ULONG  ReparseTag;
  USHORT ReparseDataLength;
  USHORT Reserved;
  union {
    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      ULONG  Flags;
      WCHAR  PathBuffer[1];
    } SymbolicLinkReparseBuffer;
    struct {
      USHORT SubstituteNameOffset;
      USHORT SubstituteNameLength;
      USHORT PrintNameOffset;
      USHORT PrintNameLength;
      WCHAR  PathBuffer[1];
    } MountPointReparseBuffer;
    struct {
      UCHAR DataBuffer[1];
    } GenericReparseBuffer;
  };
} REPARSE_DATA_BUFFER, *PREPARSE_DATA_BUFFER;
=end

        class REPARSE_DATA_BUFFER_SYMBOLIC_LINK < FFI::Struct
          layout :SubstituteNameOffset, :ushort,
            :SubstituteNameLength, :ushort,
            :PrintNameOffset, :ushort,
            :PrintNameLength, :ushort,
            :Flags, :uint32,
            :PathBuffer, :ushort

          def substitute_name
            string_pointer = FFI::Pointer.new(pointer.address) + offset_of(:PathBuffer) + self[:SubstituteNameOffset]
            string_pointer.read_wstring(self[:SubstituteNameLength]/2)
          end
          def print_name
            string_pointer = FFI::Pointer.new(pointer.address) + offset_of(:PathBuffer) + self[:PrintNameOffset]
            string_pointer.read_wstring(self[:PrintNameLength]/2)
          end
        end
        class REPARSE_DATA_BUFFER_MOUNT_POINT < FFI::Struct
          layout :SubstituteNameOffset, :ushort,
            :SubstituteNameLength, :ushort,
            :PrintNameOffset, :ushort,
            :PrintNameLength, :ushort,
            :PathBuffer, :ushort

          def substitute_name
            string_pointer = FFI::Pointer.new(pointer.address) + offset_of(:PathBuffer) + self[:SubstituteNameOffset]
            string_pointer.read_wstring(self[:SubstituteNameLength]/2)
          end
          def print_name
            string_pointer = FFI::Pointer.new(pointer.address) + offset_of(:PathBuffer) + self[:PrintNameOffset]
            string_pointer.read_wstring(self[:PrintNameLength]/2)
          end
        end
        class REPARSE_DATA_BUFFER_GENERIC < FFI::Struct
          layout :DataBuffer, :uchar
        end
        class REPARSE_DATA_BUFFER_UNION < FFI::Union
          layout :SymbolicLinkReparseBuffer, REPARSE_DATA_BUFFER_SYMBOLIC_LINK,
            :MountPointReparseBuffer, REPARSE_DATA_BUFFER_MOUNT_POINT,
            :GenericReparseBuffer, REPARSE_DATA_BUFFER_GENERIC
        end
        class REPARSE_DATA_BUFFER < FFI::Struct
          layout :ReparseTag, :uint32,
            :ReparseDataLength, :ushort,
            :Reserved, :ushort,
            :ReparseBuffer, REPARSE_DATA_BUFFER_UNION

          def reparse_buffer
            if self[:ReparseTag] == IO_REPARSE_TAG_SYMLINK
              self[:ReparseBuffer][:SymbolicLinkReparseBuffer]
            elsif self[:ReparseTag] == IO_REPARSE_TAG_MOUNT_POINT
              self[:ReparseBuffer][:MountPointReparseBuffer]
            else
              self[:ReparseBuffer][:GenericReparseBuffer]
            end
          end
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

=begin
BOOL WINAPI DeviceIoControl(
  __in         HANDLE hDevice,
  __in         DWORD dwIoControlCode,
  __in_opt     LPVOID lpInBuffer,
  __in         DWORD nInBufferSize,
  __out_opt    LPVOID lpOutBuffer,
  __in         DWORD nOutBufferSize,
  __out_opt    LPDWORD lpBytesReturned,
  __inout_opt  LPOVERLAPPED lpOverlapped
);
=end
        attach_function :DeviceIoControl, [:HANDLE, :DWORD, :LPVOID, :DWORD, :LPVOID, :DWORD, :LPDWORD, :pointer], :BOOL

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
              Chef::ReservedNames::Win32::Error.raise!
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
                                  nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_BACKUP_SEMANTICS, nil)

            if handle == INVALID_HANDLE_VALUE
              Chef::ReservedNames::Win32::Error.raise!
            end
            block.call(handle)
          ensure
            CloseHandle(handle) if handle && handle != INVALID_HANDLE_VALUE
          end
        end

        def symlink_file_handle(path, &block)
          begin
            path = encode_path(path)
            handle = CreateFileW(path, FILE_READ_EA, FILE_SHARE_READ,
                                  nil, OPEN_EXISTING, FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS, nil)

            if handle == INVALID_HANDLE_VALUE
              Chef::ReservedNames::Win32::Error.raise!
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
              Chef::ReservedNames::Win32::Error.raise!
            end
          end
          file_information
        end

      end
    end
  end
end
