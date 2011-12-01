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

require File.join(File.dirname(__FILE__), '..', 'prof', 'gc')
require File.join(File.dirname(__FILE__), '..', 'prof', 'win32')
require 'rspec/matchers/be_within'

module Matchers
  class Leak
    include RSpec::Matchers

    def initialize(opts={}, &block)
      @warmup = opts[:warmup] || 5
      @iterations = opts[:iterations] || 100
      @variance = opts[:variance] || 1000
    end

    def matches?(given_proc)

      profiler.start

      @initial_measure = 0
      @final_measure = 0

      @warmup.times do
        given_proc.call
      end

      @initial_measure = profiler.working_set_size

      @iterations.times do
        given_proc.call
      end

      @final_measure = profiler.working_set_size
      @final_measure > (@initial_measure + @variance)
    end

    def failure_message_for_should
      "expected #{@final_measure} to be greater than or within +/- #{@variance} delta of #{@initial_measure}"
    end

    def failure_message_for_should_not
      "expected #{@final_measure} to be less than or within +/- #{@variance} delta of #{@initial_measure}"
    end

    private
    def profiler
      @profiler ||= begin
        case RbConfig::CONFIG['host_os']
        when /mswin|mingw|windows/
          RSpec::Prof::Win32::Profiler.new
        else
          RSpec::Prof::GC::Profiler.new
        end
      end
    end
  end

  def leak(opts, &block)
    Matchers::Leak.new(opts, &block)
  end
  alias_method :leak_memory, :leak
end
