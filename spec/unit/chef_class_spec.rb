#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright (c) 2015 Opscode, Inc.
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

describe "Chef class" do
  let(:platform) { "debian" }

  let(:node) do
    node = Chef::Node.new
    node.automatic['platform'] = platform
    node
  end

  let(:processor) do
    Chef::Telemetry::Processor.new
  end

  let(:run_context) do
    Chef::RunContext.new(node, nil, nil)
  end

  let(:resource_priority_map) do
    double("Chef::Platform::ResourcePriorityMap")
  end

  let(:provider_priority_map) do
    double("Chef::Platform::ProviderPriorityMap")
  end

  before do
    Chef.set_run_context(run_context)
    Chef.set_node(node)
    Chef.set_resource_priority_map(resource_priority_map)
    Chef.set_provider_priority_map(provider_priority_map)
    Chef.set_telemetry_processor(processor)
  end

  context "priority maps" do
    context "#get_provider_priority_array" do
      it "should use the current node to get the right priority_map" do
        expect(provider_priority_map).to receive(:get_priority_array).with(node, :http_request).and_return("stuff")
        expect(Chef.get_provider_priority_array(:http_request)).to eql("stuff")
      end
    end
    context "#get_resource_priority_array" do
      it "should use the current node to get the right priority_map" do
        expect(resource_priority_map).to receive(:get_priority_array).with(node, :http_request).and_return("stuff")
        expect(Chef.get_resource_priority_array(:http_request)).to eql("stuff")
      end
    end
    context "#set_provider_priority_array" do
      it "should delegate to the provider_priority_map" do
        expect(provider_priority_map).to receive(:set_priority_array).with(:http_request, ["a", "b"], platform: "debian").and_return("stuff")
        expect(Chef.set_provider_priority_array(:http_request, ["a", "b"], platform: "debian")).to eql("stuff")
      end
    end
    context "#set_priority_map_for_resource" do
      it "should delegate to the resource_priority_map" do
        expect(resource_priority_map).to receive(:set_priority_array).with(:http_request, ["a", "b"], platform: "debian").and_return("stuff")
        expect(Chef.set_resource_priority_array(:http_request, ["a", "b"], platform: "debian")).to eql("stuff")
      end
    end
  end

  context "#run_context" do
    it "should return the injected RunContext" do
      expect(Chef.run_context).to eql(run_context)
    end
  end

  context "#node" do
    it "should return the injected Node" do
      expect(Chef.node).to eql(node)
    end
  end

  context '#event_handler' do
    it 'adds a new handler' do
      x = 1
      Chef.event_handler do
        on :converge_start do
          x = 2
        end
      end
      expect(Chef::Config[:event_handlers]).to_not be_empty
      Chef::Config[:event_handlers].first.send(:converge_start)
      expect(x).to eq(2)
    end

    it 'raise error if unknown event type is passed' do
      expect do
        Chef.event_handler do
          on :yolo do
          end
        end
      end.to raise_error(Chef::Exceptions::InvalidEventType)
    end
  end

  context '#telemetry' do
    it 'returns the injected telemetry processor object' do
      Chef.telemetry do |meter|
        expect(meter).to eq(processor)
      end
    end
  end
end
