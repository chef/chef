#
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
require "spec_helper"

describe Chef::Resource::MacosUserDefaults, :macos_only, requires_root: true do
  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::MacosUserDefaults.new("test", run_context)
    resource
  end

  let(:resource) do
    create_resource
  end

  context "has a default value" do
    it ":macos_userdefaults for resource name" do
      expect(resource.name).to eq("test")
    end

    it "NSGlobalDomain for the domain property" do
      expect(resource.domain).to eq("NSGlobalDomain")
    end

    it "nil for the host property" do
      expect(resource.host).to be_nil
    end

    it "nil for the user property" do
      expect(resource.user).to be_nil
    end

    it ":write for resource action" do
      expect(resource.action).to eq([:write])
    end
  end

  it "supports :write, :delete actions" do
    expect { resource.action :write }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  context "can process expected data" do
    it "set array values" do
      resource.domain "/Library/Preferences/ManagedInstalls"
      resource.key "TestArrayValues"
      resource.value [ "/Library/Managed Installs/fake.log", "/Library/Managed Installs/also_fake.log"]
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq([ "/Library/Managed Installs/fake.log", "/Library/Managed Installs/also_fake.log"])
    end

    it "set dictionary value" do
      resource.domain "/Library/Preferences/ManagedInstalls"
      resource.key "TestDictionaryValues"
      resource.value "User": "/Library/Managed Installs/way_fake.log"
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq("User" => "/Library/Managed Installs/way_fake.log")
    end

    it "set array of dictionaries" do
      resource.domain "/Library/Preferences/ManagedInstalls"
      resource.key "TestArrayWithDictionary"
      resource.value [ { "User": "/Library/Managed Installs/way_fake.log" } ]
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq([ { "User" => "/Library/Managed Installs/way_fake.log" } ])
    end

    it "set boolean for preference value" do
      resource.domain "/Library/Preferences/ManagedInstalls"
      resource.key "TestBooleanValue"
      resource.value true
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq(true)
    end

    it "sets value to global domain when domain is not passed" do
      resource.key "TestKey"
      resource.value 1
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq(1)
    end

    it "short domain names" do
      resource.domain "com.apple.dock"
      resource.key "titlesize"
      resource.value "20"
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq("20")
    end
  end

  it "we can delete a preference with full path" do
    resource.domain "/Library/Preferences/ManagedInstalls"
    resource.key "TestKey"
    expect { resource.run_action(:delete) }. to_not raise_error
  end

  it "we can delete a preference with short name" do
    resource.domain "com.apple.dock"
    resource.key "titlesize"
    expect { resource.run_action(:delete) }. to_not raise_error
  end
end
