#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "api/process"
require_relative "api/psapi"
require_relative "api/system"
require_relative "error"

class Chef
  module ReservedNames::Win32
    class Handle
      extend Chef::ReservedNames::Win32::API::Process

      def initialize(handle)
        @handle = handle
        ObjectSpace.define_finalizer(self, Handle.close_handle_finalizer(handle))
      end

      attr_reader :handle

      def self.close_handle_finalizer(handle)
        proc { close_handle(handle) }
      end

      def self.close_handle(handle)
        # According to http://msdn.microsoft.com/en-us/library/windows/desktop/ms683179(v=vs.85).aspx, it is not necessary
        # to close the pseudo handle returned by the GetCurrentProcess function.  The docs also say that it doesn't hurt to call
        # CloseHandle on it. However, doing so from inside of Ruby always seems to produce an invalid handle error.
        # The recommendation is to use GetCurrentProcess instead of the const (HANDLE)-1, to ensure we're making the correct comparison.
        return if handle == GetCurrentProcess()

        unless CloseHandle(handle)
          Chef::ReservedNames::Win32::Error.raise!
        end
      end

    end
  end
end
