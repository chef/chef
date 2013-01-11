#--
# Author:: Kevin Moser (<kevin.moser@nordstrom.com>)
# Copyright:: Copyright (c) 2012, 2013 Nordstrom, Inc.
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

require 'win32/process'
require 'windows/handle'
require 'windows/process'
require 'windows/synchronize'

# Add new constants for Logon
module Process::Constants
  LOGON32_LOGON_INTERACTIVE = 0x00000002
  LOGON32_PROVIDER_DEFAULT  = 0x00000000

  SID_MAX_SUB_AUTHORITIES   = 0x00000015
  SECURITY_NT_AUTHORITY     = 0x00000005
  SECURITY_LOCAL_SYSTEM_RID = 0x00000012
end  

# Define the LogonUser function
module Process::Functions
  module FFI::Library
    # Wrapper method for attach_function + private
    def attach_pfunc(*args)
      attach_function(*args)
      private args[0]
    end
  end

  extend FFI::Library

  ffi_lib :advapi32

  attach_pfunc :LogonUser, :LogonUserA,
    [:buffer_in, :buffer_in, :buffer_in, :ulong, :ulong, :pointer], :bool

  attach_pfunc :AllocateAndInitializeSid, 
    [:pointer, :uint, :ulong, :ulong, :ulong, :ulong, :ulong, :ulong, :ulong, :ulong, :pointer], :bool
  attach_pfunc :EqualSid, [:pointer, :pointer], :bool
  attach_pfunc :FreeSid, [:pointer], :pointer
end

module Process
  def is_local_system?
    token = FFI::MemoryPointer.new(:ulong)

    unless OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, token)
      raise SystemCallError, FFI.errno, "OpenProcessToken"
    end

    puts("-------------------token pointer: #{token.read_ulong}")

    CloseHandle(token)

  end

  module_function :is_local_system?
end
