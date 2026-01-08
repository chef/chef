#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

describe "Chef class" do
  let(:platform) { "debian" }

  let(:node) do
    node = Chef::Node.new
    node.automatic["platform"] = platform
    node
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
        expect(provider_priority_map).to receive(:set_priority_array).with(:http_request, %w{a b}, platform: "debian").and_return("stuff")
        expect(Chef.set_provider_priority_array(:http_request, %w{a b}, platform: "debian")).to eql("stuff")
      end
    end
    context "#set_priority_map_for_resource" do
      it "should delegate to the resource_priority_map" do
        expect(resource_priority_map).to receive(:set_priority_array).with(:http_request, %w{a b}, platform: "debian").and_return("stuff")
        expect(Chef.set_resource_priority_array(:http_request, %w{a b}, platform: "debian")).to eql("stuff")
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

  context "#event_handler" do
    it "adds a new handler" do
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

    it "raise error if unknown event type is passed" do
      expect do
        Chef.event_handler do
          on :yolo do
          end
        end
      end.to raise_error(Chef::Exceptions::InvalidEventType)
    end
  end

  describe "Deprecation system" do
    context "with treat_deprecation_warnings_as_errors false" do
      before { Chef::Config[:treat_deprecation_warnings_as_errors] = false }

      it "displays a simple deprecation warning" do
        expect(Chef::Log).to receive(:warn).with(%r{spec/unit/chef_class_spec\.rb.*?I'm a little teapot.*?Please see}m)
        Chef.deprecated(:generic, "I'm a little teapot.")
      end

      it "allows silencing all warnings" do
        Chef::Config[:silence_deprecation_warnings] = true
        expect(Chef::Log).to_not receive(:warn)
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific types" do
        Chef::Config[:silence_deprecation_warnings] = [:internal_api]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific IDs" do
        Chef::Config[:silence_deprecation_warnings] = [0]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific IDs without matching the line number" do
        Chef::Config[:silence_deprecation_warnings] = [__LINE__ + 4]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/Short and stout/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific IDs using the CHEF- syntax" do
        Chef::Config[:silence_deprecation_warnings] = ["CHEF-0"]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific IDs using the chef- syntax" do
        Chef::Config[:silence_deprecation_warnings] = ["chef-0"]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.")
        Chef.deprecated(:generic, "This is my handle.")
      end

      it "allows silencing specific lines" do
        Chef::Config[:silence_deprecation_warnings] = ["chef_class_spec.rb:#{__LINE__ + 4}"]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:generic, "Short and stout.")
        Chef.deprecated(:internal_api, "This is my handle.")
      end

      it "allows silencing all via inline comments" do
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:generic, "Short and stout.") # chef:silence_deprecation
        Chef.deprecated(:internal_api, "This is my handle.")
      end

      it "allows silencing specific types via inline comments" do
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:generic, "Short and stout.") # chef:silence_deprecation:generic
        Chef.deprecated(:internal_api, "This is my handle.")
      end

      it "does not silence via inline comments when the types don't match" do
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/Short and stout/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:internal_api, "Short and stout.") # chef:silence_deprecation:generic
        Chef.deprecated(:internal_api, "This is my handle.")
      end

      it "allows silencing all via inline comments with other stuff in the comment" do
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my handle/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:generic, "Short and stout.") # rubocop:something chef:silence_deprecation other stuff
        Chef.deprecated(:internal_api, "This is my handle.")
      end

      it "handles multiple silence configurations at the same time" do
        Chef::Config[:silence_deprecation_warnings] = ["exit_code", "chef_class_spec.rb:#{__LINE__ + 6}"]
        expect(Chef::Log).to receive(:warn).with(/I'm a little teapot/).once
        expect(Chef::Log).to receive(:warn).with(/This is my spout/).once
        expect(Chef::Log).to receive(:warn).with(/Hear me shout/).once
        Chef.deprecated(:generic, "I'm a little teapot.")
        Chef.deprecated(:generic, "Short and stout.") # chef:silence_deprecation
        Chef.deprecated(:internal_api, "This is my handle.")
        Chef.deprecated(:internal_api, "This is my spout.")
        Chef.deprecated(:exit_code, "When I get all steamed up.")
        Chef.deprecated(:generic, "Hear me shout.")
      end
    end

    context "with treat_deprecation_warnings_as_errors true" do
      # This is already turned on globally for Chef's unit tests, but just for clarity do it here too.
      before { Chef::Config[:treat_deprecation_warnings_as_errors] = true }

      it "displays a simple deprecation error" do
        expect(Chef::Log).to receive(:error).with(%r{spec/unit/chef_class_spec\.rb.*?I'm a little teapot.*?Please see}m)
        expect { Chef.deprecated(:generic, "I'm a little teapot.") }.to raise_error(/I'm a little teapot./)
      end
    end
  end
end
