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

describe Chef::Resource::ChocolateySource do

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChocolateySource.new("fakey_fakerton", run_context) }
  let(:disable_provider) { resource.provider_for_action(:disable) }
  let(:enable_provider) { resource.provider_for_action(:enable) }
  let(:current_resource) { Chef::Resource::ChocolateySource.new("fakey_fakerton") }
  let(:config) do
    <<-CONFIG
  <?xml version="1.0" encoding="utf-8"?>
  <chocolatey xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <config>
      <add key="containsLegacyPackageInstalls" value="true" description="Install has packages installed prior to 0.9.9 series." />
    </config>
    <sources>
      <source id="chocolatey" value="https://chocolatey.org/api/v2/" disabled="false" bypassProxy="false" selfService="false" adminOnly="false" priority="0" />
    </sources>
    <features>
      <feature name="checksumFiles" enabled="true" setExplicitly="false" description="Checksum files when pulled in from internet (based on package)." />
    </features>
    <apiKeys />
  </chocolatey>
    CONFIG
  end

  # we save off the ENV and set ALLUSERSPROFILE so these specs will work on *nix and non-C drive Windows installs
  before(:each) do
    disable_provider # vivify before mocking
    enable_provider
    current_resource
    allow(resource).to receive(:provider_for_action).and_return(disable_provider)
    allow(resource).to receive(:provider_for_action).and_return(enable_provider)
    allow(resource.class).to receive(:new).and_return(current_resource)
    @original_env = ENV.to_hash
    ENV["ALLUSERSPROFILE"] = "C:\\ProgramData"
  end

  after(:each) do
    ENV.clear
    ENV.update(@original_env)
  end

  it "has a resource name of :chocolatey_source" do
    expect(resource.resource_name).to eql(:chocolatey_source)
  end

  it "has a name property of source_name" do
    expect(resource.source_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add and :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :disable }.not_to raise_error
    expect { resource.action :enable }.not_to raise_error
  end

  it "bypass_proxy property defaults to false" do
    expect { resource.bypass_proxy.to be_false }
  end

  it "priority property defaults to 0" do
    expect { resource.priority.to eq(0) }
  end

  it "admin_only property defaults to false" do
    expect { resource.admin_only.to be_false }
  end

  it "allow_self_service property defaults to false" do
    expect { resource.allow_self_service.to be_false }
  end

  describe "#load_current_resource" do
    it "sets disabled to true when the XML disabled property is true" do
      allow(current_resource).to receive(:fetch_source_element).with("fakey_fakerton").and_return(OpenStruct.new(disabled: "true"))
      disable_provider.load_current_resource
      expect(current_resource.disabled).to be true
    end

    it "sets disabled to false when the XML disabled property is false" do
      allow(current_resource).to receive(:fetch_source_element).with("fakey_fakerton").and_return(OpenStruct.new(disabled: "false"))
      enable_provider.load_current_resource
      expect(current_resource.disabled).to be false
    end
  end

  describe "run_action(:enable)" do
    it "when source is disabled, it enables it correctly" do
      resource.disabled true
      allow(current_resource).to receive(:fetch_source_element).with("fakey_fakerton").and_return(OpenStruct.new(disabled: "true"))
      expect(enable_provider).to receive(:shell_out!).with("C:\\ProgramData\\chocolatey\\bin\\choco source enable -n \"fakey_fakerton\"")
      resource.run_action(:enable)
      expect(resource.updated_by_last_action?).to be true
    end

    it "when source is enabled, it is idempotent when trying to enable" do
      resource.disabled false
      allow(current_resource).to receive(:fetch_source_element).with("fakey_fakerton").and_return(OpenStruct.new(disabled: "false"))
      resource.run_action(:enable)
      expect(resource.updated_by_last_action?).to be false
    end
  end

  describe "#fetch_source_element" do
    it "raises and error if the config file cannot be found" do
      allow(::File).to receive(:exist?).with('C:\ProgramData\chocolatey\config\chocolatey.config').and_return(false)
      expect { resource.fetch_source_element("foo") }.to raise_error(RuntimeError)
    end

    it "returns the value if present in the config file" do
      allow(::File).to receive(:exist?).with('C:\ProgramData\chocolatey\config\chocolatey.config').and_return(true)
      allow(::File).to receive(:read).with('C:\ProgramData\chocolatey\config\chocolatey.config').and_return(config)
      expect(resource.fetch_source_element("chocolatey")["value"]).to eq("https://chocolatey.org/api/v2/")
      expect { resource.fetch_source_element("foo") }.not_to raise_error
    end

    it "returns nil if the element is not present in the config file" do
      allow(::File).to receive(:exist?).with('C:\ProgramData\chocolatey\config\chocolatey.config').and_return(true)
      allow(::File).to receive(:read).with('C:\ProgramData\chocolatey\config\chocolatey.config').and_return(config)
      expect(resource.fetch_source_element("foo")).to be_nil
      expect { resource.fetch_source_element("foo") }.not_to raise_error
    end
  end
end
