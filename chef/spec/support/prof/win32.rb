#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

module RSpec
  module Prof
    module Win32
      class Profiler
        def start
          #raise 'Not Implemented'
        end

        def stop
          #raise 'Not Implemented'
        end

        def sample
          Sample.new(Chef::Win32::Process.get_current_process.handle_count, Chef::Win32::Process.get_current_process.memory_info[:WorkingSetSize])
        end
      end

      class Sample
        include Comparable

        attr_reader :handle_count
        attr_reader :working_set_size

        def initialize(handle_count, working_set_size)
          @handle_count = handle_count
          @working_set_size = working_set_size
        end

        def <=>(other)
          if (self.handle_count < other.handle_count) || (self.working_set_size < other.working_set_size)
            -1
          elsif (self.handle_count > other.handle_count) || (self.working_set_size > other.working_set_size)
            1
          else
            0
          end
        end

        def to_s
          ":handle_count => #{handle_count}, :working_set_size => #{working_set_size}"
        end
      end
    end
  end
end

