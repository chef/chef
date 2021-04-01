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

module Matchers
  module LeakBase
    include RSpec::Matchers

    def initialize(opts = {})
      @warmup = opts[:warmup] || 5
      @iterations = opts[:iterations] || 100
      @variance = opts[:variance] || 5000
    end

    def failure_message
      "expected final measure [#{@final_measure}] to be greater than or within +/- #{@variance} delta of initial measure [#{@initial_measure}]"
    end

    def failure_message_when_negated
      "expected final measure [#{@final_measure}] to be less than or within +/- #{@variance} delta of initial measure [#{@initial_measure}]"
    end

    private

    def match(measure, given_proc)
      profiler.start

      @initial_measure = 0
      @final_measure = 0

      @warmup.times do
        given_proc.call
      end

      @initial_measure = profiler.send(measure)

      @iterations.times do
        given_proc.call
      end

      profiler.stop

      @final_measure = profiler.send(measure)
      @final_measure > (@initial_measure + @variance)
    end

    def profiler
      @profiler ||= if ChefUtils.windows?
                      require File.join(__dir__, "..", "platforms", "prof", "win32")
                      RSpec::Prof::Win32::Profiler.new
                    else
                      require File.join(__dir__, "..", "prof", "gc")
                      RSpec::Prof::GC::Profiler.new
                    end
    end

  end

  class LeakMemory
    include LeakBase

    def matches?(given_proc)
      match(:working_set_size, given_proc)
    end
  end

  class LeakHandles
    include LeakBase

    def matches?(given_proc)
      match(:handle_count, given_proc)
    end
  end

  def leak_memory(opts, &block)
    Matchers::LeakMemory.new(opts, &block)
  end

  def leak_handles(opts, &block)
    Matchers::LeakHandles.new(opts, &block)
  end
end
