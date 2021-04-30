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

module RSpec
  module Prof
    module GC
      class Profiler

        # GC 1 invokes.
        # Index    Invoke Time(sec)       Use Size(byte)     Total Size(byte)         Total Object                    GC time(ms)
        #     1               0.012               159240               212940                10647         0.00000000000001530000
        LINE_PATTERN = /^\s+([\d\.]*)\s+([\d\.]*)\s+([\d\.]*)\s+([\d\.]*)\s+([\d\.]*)\s+([\d\.]*)$/.freeze

        def start
          ::GC::Profiler.enable unless ::GC::Profiler.enabled?
        end

        def stop
          ::GC::Profiler.disable
        end

        def working_set_size
          ::GC.start
          ::GC::Profiler.result.scan(LINE_PATTERN)[-1][2].to_i if ::GC::Profiler.enabled?
        ensure
          ::GC::Profiler.clear
        end

        def handle_count
          0
        end

      end
    end
  end
end
