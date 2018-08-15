#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

  let(:resource) { Chef::Resource::ChocolateySource.new("fakey_fakerton") }
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
    @original_env = ENV.to_hash
    ENV["ALLUSERSPROFILE"] = 'C:\ProgramData'
  end

  after(:each) do
    ENV.clear
    ENV.update(@original_env)
  end

  it "has a resource name of :chocolatey_source" do
    expect(resource.resource_name).to eql(:chocolatey_source)
  end

  it "is not a preview resource in Chef 15" do
    pending("Chef 15") unless Chef::VERSION.start_with?("15")
    expect(resource.class.preview_resource).to be_falsey
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
  end

  it "bypass_proxy property defaults to false" do
    expect { resource.bypass_proxy.to be_false }
  end

  it "priority property defaults to 0" do
    expect { resource.priority.to eq(0) }
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
