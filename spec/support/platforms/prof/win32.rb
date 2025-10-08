#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/win32/process"

module RSpec
  module Prof
    module Win32
      class Profiler

        def start
          GC.start
        end

        def stop
          GC.start
        end

        def working_set_size
          Chef::ReservedNames::Win32::Process.get_current_process.memory_info[:WorkingSetSize]
        end

        def handle_count
          Chef::ReservedNames::Win32::Process.get_current_process.handle_count
        end
      end

    end
  end
end
