#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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

require 'spec_helper'
require 'chef/event_dispatch/dispatcher'

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

      expect(event_sink).to receive(:synchronized_cookbook).with("apache2")
      dispatcher.synchronized_cookbook("apache2")

      exception = StandardError.new("foo")
      expect(event_sink).to receive(:recipe_file_load_failed).with("/path/to/file.rb", exception)
      dispatcher.recipe_file_load_failed("/path/to/file.rb", exception)
    end

  end

end

