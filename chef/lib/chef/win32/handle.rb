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

require 'chef/win32/api/process'
require 'chef/win32/api/psapi'
require 'chef/win32/error'

class Chef
  module Win32
    class Handle

      def initialize(handle)
        @handle = handle
        ObjectSpace.define_finalizer(self, Handle.close_handle_finalizer(handle))
      end

      attr_reader :handle

      class << self
        include Chef::Win32::API::Process

        def close_handle_finalizer(handle)
          proc { close_handle(handle) }
        end

        def close_handle(handle)
          unless CloseHandle(handle)
            Chef::Win32::Error.raise!
          end
        end
      end
    end
  end
end
