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
require "chef/resource_inspector"

COMBINED_RESOURCE_TEXT = <<-EOF.freeze
class Dummy1 < Chef::Resource::LWRPBase
  resource_name :dummy1
  description "A dummy resource"
  property :first, String, description: "My First Property", introduced: "14.0"
end

class Dummy2 < Chef::Resource::LWRPBase
  resource_name :dummy2
  description "Another dummy resource"
  property :second, String, description: "My Second Property", introduced: "14.0"
end
EOF

class DummyResource < Chef::Resource
  resource_name :dummy
  description "A dummy resource"
  examples <<~EOH
    dummy "foo" do
      first "yes"
    end
  EOH
  introduced "14.0"
  property :first, String, description: "My First Property", introduced: "14.0"

  action :dummy, description: "Dummy action" do
    return true
  end

  action :dummy_no_desc do
    return true
  end
end

describe Chef::ResourceInspector do
  describe "inspecting a resource" do
    subject { Chef::ResourceInspector.extract_resource(DummyResource, false) }

    it "returns a hash with required data" do
      expect(subject[:description]).to eq "A dummy resource"
      expect(subject[:actions]).to eq({ nothing: nil, dummy: "Dummy action",
                                        dummy_no_desc: nil })
    end

    context "excluding built in properties" do
      it "returns a single property" do
        expect(subject[:properties].count).to eq 1
        expect(subject[:properties].first[:name]).to eq :first
      end
    end

    context "including built in properties" do
      subject { Chef::ResourceInspector.extract_resource(DummyResource, true) }
      it "returns many properties" do
        expect(subject[:properties].count).to be > 1
        expect(subject[:properties].map { |n| n[:name] }).to include(:name, :first, :sensitive)
      end
    end
  end

  describe "inspecting a multi-resource file" do
    # Call the inspector with a fake file containing two resources, and ensure that we get
    # both of them back!
    subject {
      Chef::ResourceInspector.load_from_resources([
        { "full_path" => "/cookbooks/fake_cookbook/resources/big_resource.rb" },
      ], false)
    }
    it "has elephants" do
      allow(File).to receive(:file?).with("/cookbooks/fake_cookbook/resources/big_resource.rb").and_return(true)
      allow(File).to receive(:readable?).with("/cookbooks/fake_cookbook/resources/big_resource.rb").and_return(true)
      allow(IO).to receive(:read).with("/cookbooks/fake_cookbook/resources/big_resource.rb").and_return(COMBINED_RESOURCE_TEXT)
      expect(subject.keys.count).to be 2
      expect(subject.keys.sort).to eq(%i{dummy1 dummy2})
      # This is correct - because they're not fully realised resources at this point, sensitive and friends are not added yet.
      expect(subject[:dummy1][:properties].count).to be 1
      expect(subject[:dummy2][:properties].count).to be 1
      expect(subject[:dummy1][:properties][0][:description]).to eq "My First Property"
      expect(subject[:dummy2][:properties][0][:description]).to eq "My Second Property"
    end
  end
end
