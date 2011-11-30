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

module Matchers
  class Leak
    def initialize(opts={}, &block)
      @warmup = opts[:warmup] || 5
      @iterations = opts[:iterations] || 100
    end

    def matches?(given_proc)

      profiler.start

      initial_measure = 0
      final_measure = 0

      @warmup.times do
        given_proc.call
      end

      initial_measure = profiler.sample

      @iterations.times do
        given_proc.call
      end

      final_measure = profiler.sample

      final_measure <= initial_measure
    end

    def failure_message_for_should
      "expected #{@target.inspect} to be in Zone #{@expected}"
    end

    def failure_message_for_should_not
      "expected #{@target.inspect} not to be in Zone #{@expected}"
    end

    private
    def profiler
      @profiler ||= begin
        case RbConfig::CONFIG['host_os']
        when /mswin|mingw|windows/
          Rspec::Prof::Win32::Profiler.new
        else
          Rspec::Prof::GC::Profiler.new
        end
      end
    end
  end

  def leak(opts, &block)
    Matchers::Leak.new(opts, &block)
  end
  alias_method :leak_memory, :leak
end
