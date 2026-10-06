#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
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

require "spec_helper"
require "chef/event_dispatch/dispatcher"
require "timeout"

describe Chef::EventDispatch::Dispatcher do

  subject(:dispatcher) { Chef::EventDispatch::Dispatcher.new }

  let(:event_sink) { instance_double("Chef::EventDispatch::Base") }

  it "has no subscribers by default" do
    expect(dispatcher.subscribers).to be_empty
  end

  context "when an event sink is registered" do

    before do
      dispatcher.register(event_sink)
    end

    it "it has the event sink as a subscriber" do
      expect(dispatcher.subscribers.size).to eq(1)
      expect(dispatcher.subscribers.first).to eq(event_sink)
    end

    it "forwards events to the subscribed event sink" do
      # the events all have different arity and such so we just hit a few different events:
      run_status = Chef::RunStatus.new({}, {})
      expect(event_sink).to receive(:run_start).with("12.4.0", run_status)
      dispatcher.run_start("12.4.0", run_status)

      cookbook_version = double("cookbook_version")
      expect(event_sink).to receive(:synchronized_cookbook).with("apache2", cookbook_version)
      dispatcher.synchronized_cookbook("apache2", cookbook_version)

      exception = StandardError.new("foo")
      expect(event_sink).to receive(:recipe_file_load_failed).with("/path/to/file.rb", exception, "myrecipe")
      dispatcher.recipe_file_load_failed("/path/to/file.rb", exception, "myrecipe")
    end

    context "when an event sink has fewer arguments for an event" do
      # Can't use a double because they don't report arity correctly.
      let(:event_sink) do
        Class.new(Chef::EventDispatch::Base) do
          attr_reader :synchronized_cookbook_args

          def synchronized_cookbook(cookbook_name)
            @synchronized_cookbook_args = [cookbook_name]
          end
        end.new
      end

      it "trims the arugment list" do
        cookbook_version = double("cookbook_version")
        dispatcher.synchronized_cookbook("apache2", cookbook_version)
        expect(event_sink.synchronized_cookbook_args).to eq ["apache2"]
      end
    end
  end

  context "when two event sinks have different arguments for an event" do
    let(:event_sink_1) do
      Class.new(Chef::EventDispatch::Base) do
        attr_reader :synchronized_cookbook_args

        def synchronized_cookbook(cookbook_name)
          @synchronized_cookbook_args = [cookbook_name]
        end
      end.new
    end
    let(:event_sink_2) do
      Class.new(Chef::EventDispatch::Base) do
        attr_reader :synchronized_cookbook_args

        def synchronized_cookbook(cookbook_name, cookbook)
          @synchronized_cookbook_args = [cookbook_name, cookbook]
        end
      end.new
    end

    context "and the one with fewer arguments comes first" do
      before do
        dispatcher.register(event_sink_1)
        dispatcher.register(event_sink_2)
      end
      it "trims the arugment list" do
        cookbook_version = double("cookbook_version")
        dispatcher.synchronized_cookbook("apache2", cookbook_version)
        expect(event_sink_1.synchronized_cookbook_args).to eq ["apache2"]
        expect(event_sink_2.synchronized_cookbook_args).to eq ["apache2", cookbook_version]
      end
    end

    context "and the one with fewer arguments comes last" do
      before do
        dispatcher.register(event_sink_2)
        dispatcher.register(event_sink_1)
      end
      it "trims the arugment list" do
        cookbook_version = double("cookbook_version")
        dispatcher.synchronized_cookbook("apache2", cookbook_version)
        expect(event_sink_1.synchronized_cookbook_args).to eq ["apache2"]
        expect(event_sink_2.synchronized_cookbook_args).to eq ["apache2", cookbook_version]
      end
    end
  end

  context "events that queue events" do
    class Accumulator
      def self.sequence
        @sequence ||= []
      end
    end

    let(:event_sink_1) do
      Class.new(Chef::EventDispatch::Base) do
        def synchronized_cookbook(dispatcher, arg)
          dispatcher.enqueue(:event_two, arg)
          Accumulator.sequence << [ :sink_1_event_1, arg ]
        end

        def event_two(arg)
          Accumulator.sequence << [ :sink_1_event_2, arg ]
        end
      end.new
    end
    let(:event_sink_2) do
      Class.new(Chef::EventDispatch::Base) do
        def synchronized_cookbook(dispatcher, arg)
          Accumulator.sequence << [ :sink_2_event_1, arg ]
        end

        def event_two(arg)
          Accumulator.sequence << [ :sink_2_event_2, arg ]
        end
      end.new
    end

    before do
      dispatcher.register(event_sink_1)
      dispatcher.register(event_sink_2)
    end

    it "runs the events in the correct order without interleaving the enqueued event" do
      dispatcher.synchronized_cookbook(dispatcher, "two")
      expect(Accumulator.sequence).to eql([
        [:sink_1_event_1, "two"], # the call to enqueue the event happens here
        [:sink_2_event_1, "two"], # event 1 fully finishes
        [:sink_1_event_2, "two"],
        [:sink_2_event_2, "two"], # then event 2 runs and finishes
      ])
    end
  end

  context "when multiple threads dispatch events concurrently" do
    # the cookbook synchronizer dispatches events from worker threads, so
    # "in_call" state used to gate re-entrant processing must not leak
    # between threads the way the thread-local event_list already doesn't.
    let(:event_sink) do
      Class.new(Chef::EventDispatch::Base) do
        def initialize(gate, processed)
          @gate = gate
          @processed = processed
        end

        # blocks the calling thread inside call_subscribers until released,
        # simulating a slow subscriber
        def run_start(*)
          @gate.pop
        end

        def synchronized_cookbook(*)
          @processed << :from_other_thread
        end
      end
    end

    it "still processes a second thread's enqueued event instead of stranding it" do
      gate = Queue.new
      processed = Queue.new
      dispatcher.register(event_sink.new(gate, processed))

      thread_a = Thread.new { dispatcher.run_start("1.0.0", nil) }
      Timeout.timeout(2) { sleep 0.01 until thread_a.status == "sleep" }

      thread_b = Thread.new { dispatcher.synchronized_cookbook("apache2", nil) }
      thread_b.join(2)

      gate << :release
      thread_a.join(2)

      expect(processed.pop(true)).to eq(:from_other_thread)
    end
  end
end
