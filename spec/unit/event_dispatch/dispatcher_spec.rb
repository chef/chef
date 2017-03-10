#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

      expect(event_sink).to receive(:run_start).with("12.4.0")
      dispatcher.run_start("12.4.0")

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
end
