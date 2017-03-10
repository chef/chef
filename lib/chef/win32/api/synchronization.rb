#
# Author:: Serdar Sutay (<serdar@chef.io>)
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

require "chef/win32/api"

class Chef
  module ReservedNames::Win32
    module API
      module Synchronization
        extend Chef::ReservedNames::Win32::API

        ffi_lib "kernel32"

        # Constant synchronization functions use to indicate wait
        # forever.
        INFINITE = 0xFFFFFFFF

        # Return codes
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms687032(v=vs.85).aspx
        WAIT_FAILED = 0xFFFFFFFF
        WAIT_TIMEOUT = 0x00000102
        WAIT_OBJECT_0 = 0x00000000
        WAIT_ABANDONED = 0x00000080

        # Security and access rights for synchronization objects
        # http://msdn.microsoft.com/en-us/library/windows/desktop/ms686670(v=vs.85).aspx
        DELETE = 0x00010000
        READ_CONTROL = 0x00020000
        SYNCHRONIZE = 0x00100000
        WRITE_DAC = 0x00040000
        WRITE_OWNER = 0x00080000

        # Mutex specific rights
        MUTEX_ALL_ACCESS = 0x001F0001
        MUTEX_MODIFY_STATE = 0x00000001

=begin
HANDLE WINAPI CreateMutex(
  _In_opt_  LPSECURITY_ATTRIBUTES lpMutexAttributes,
  _In_      BOOL bInitialOwner,
  _In_opt_  LPCTSTR lpName
);
=end
        safe_attach_function :CreateMutexW, [ :LPSECURITY_ATTRIBUTES, :BOOL, :LPCTSTR ], :HANDLE
        safe_attach_function :CreateMutexA, [ :LPSECURITY_ATTRIBUTES, :BOOL, :LPCTSTR ], :HANDLE

=begin
DWORD WINAPI WaitForSingleObject(
  _In_  HANDLE hHandle,
  _In_  DWORD dwMilliseconds
);
=end
        safe_attach_function :WaitForSingleObject, [ :HANDLE, :DWORD ], :DWORD

=begin
BOOL WINAPI ReleaseMutex(
  _In_  HANDLE hMutex
);
=end
        safe_attach_function :ReleaseMutex, [ :HANDLE ], :BOOL

=begin
HANDLE WINAPI OpenMutex(
  _In_  DWORD dwDesiredAccess,
  _In_  BOOL bInheritHandle,
  _In_  LPCTSTR lpName
);
=end
        safe_attach_function :OpenMutexW, [ :DWORD, :BOOL, :LPCTSTR ], :HANDLE
        safe_attach_function :OpenMutexA, [ :DWORD, :BOOL, :LPCTSTR ], :HANDLE
      end
    end
  end
end
