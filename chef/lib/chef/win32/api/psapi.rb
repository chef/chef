#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
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
      module PSAPI
        extend Chef::ReservedNames::Win32::API

        ###############################################
        # Win32 API Bindings
        ###############################################

        class PROCESS_MEMORY_COUNTERS < FFI::Struct
          layout :cb, :DWORD,
            :PageFaultCount, :DWORD,
            :PeakWorkingSetSize, :SIZE_T,
            :WorkingSetSize, :SIZE_T,
            :QuotaPeakPagedPoolUsage, :SIZE_T,
            :QuotaPagedPoolUsage, :SIZE_T,
            :QuotaPeakNonPagedPoolUsage, :SIZE_T,
            :QuotaNonPagedPoolUsage, :SIZE_T,
            :PagefileUsage, :SIZE_T,
            :PeakPagefileUsage, :SIZE_T
        end

        ffi_lib 'psapi'

        attach_function :GetProcessMemoryInfo, [ :HANDLE, :pointer, :DWORD ], :BOOL

      end
    end
  end
end
