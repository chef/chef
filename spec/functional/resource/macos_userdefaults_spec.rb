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

describe Chef::Resource::MacosUserDefaults, :macos_only do
  before(:all) do
    @test_temp_dir = Dir.mktmpdir("chef_macos_test")
  end

  after(:all) do
    FileUtils.rm_rf(@test_temp_dir)
  end

  let(:temp_pref_path) { File.join(@test_temp_dir, "test_preferences.plist") }

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

    it ":all for the host property" do
      expect(resource.host).to eq(:all)
    end

    it ":current for the user property" do
      expect(resource.user).to eq(:current)
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
      resource.domain temp_pref_path
      resource.key "TestArrayValues"
      resource.value [ "/Library/Managed Installs/fake.log", "/Library/Managed Installs/also_fake.log"]
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq([ "/Library/Managed Installs/fake.log", "/Library/Managed Installs/also_fake.log"])
    end

    it "set dictionary value" do
      resource.domain temp_pref_path
      resource.key "TestDictionaryValues"
      resource.value "User": "/Library/Managed Installs/way_fake.log"
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq("User" => "/Library/Managed Installs/way_fake.log")
    end

    it "set array of dictionaries" do
      resource.domain temp_pref_path
      resource.key "TestArrayWithDictionary"
      resource.value [ { "User": "/Library/Managed Installs/way_fake.log" } ]
      resource.run_action(:write)
      expect(resource.get_preference resource).to eq([ { "User" => "/Library/Managed Installs/way_fake.log" } ])
    end

    it "set boolean for preference value" do
      resource.domain temp_pref_path
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
    resource.domain temp_pref_path
    resource.key "TestKey"
    expect { resource.run_action(:delete) }. to_not raise_error
  end

  it "we can delete a preference with short name" do
    resource.domain "com.apple.dock"
    resource.key "titlesize"
    expect { resource.run_action(:delete) }. to_not raise_error
  end

  context "resource can process FFI::Pointer type" do
    it "for host property" do
      resource.domain temp_pref_path
      resource.key "TestDictionaryValues"
      resource.value "User": "/Library/Managed Installs/way_fake.log"
      resource.host :current
      resource.run_action(:write)
      expect { resource.run_action(:write) }. to_not raise_error
    end

    it "for user property" do
      resource.domain temp_pref_path
      resource.key "TestDictionaryValues"
      resource.value "User": "/Library/Managed Installs/way_fake.log"
      resource.user :current
      resource.run_action(:write)
      expect { resource.run_action(:write) }. to_not raise_error
    end
  end
end
