#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

describe Chef::Resource::WindowsPackage, "initialize" do
  before(:each) do
    stub_const("File::ALT_SEPARATOR", "\\")
  end

  static_provider_resolution(
    resource: Chef::Resource::WindowsPackage,
    provider: Chef::Provider::Package::Windows,
    os: "windows",
    name: :windows_package,
    action: :start
  )

  let(:resource) { Chef::Resource::WindowsPackage.new("solitaire.msi") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install, :lock, :purge, :reconfig, :remove, :unlock, :upgrade actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :lock }.not_to raise_error
    expect { resource.action :purge }.not_to raise_error
    expect { resource.action :reconfig }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
    expect { resource.action :unlock }.not_to raise_error
    expect { resource.action :upgrade }.not_to raise_error
  end

  it "supports setting installer_type to :custom :inno :installshield :msi :nsis or :wise only" do
    expect { resource.installer_type :custom }.not_to raise_error
    expect { resource.installer_type :inno }.not_to raise_error
    expect { resource.installer_type :installshield }.not_to raise_error
    expect { resource.installer_type :msi }.not_to raise_error
    expect { resource.installer_type :nsis }.not_to raise_error
    expect { resource.installer_type :wise }.not_to raise_error
    expect { resource.installer_type :something_else_entirely }.to raise_error(Chef::Exceptions::ValidationFailed)
    expect { resource.installer_type "msi" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  # String, Integer
  [ "600", 600 ].each do |val|
    it "supports setting a timeout as a #{val.class}" do
      resource.timeout(val)
      expect(resource.timeout).to eql(val)
    end
  end

  # String, Integer, Array
  [ "42", 42, [47, 48, 49] ].each do |val|
    it "supports setting an alternate return value as a #{val.class}" do
      resource.returns(val)
      expect(resource.returns).to eql(val)
    end
  end

  it "converts a source to an absolute path" do
    allow(::File).to receive(:absolute_path).and_return("c:\\files\\frost.msi")
    resource.source("frost.msi")
    expect(resource.source).to eql "c:\\files\\frost.msi"
  end

  it "converts slashes to backslashes in the source path" do
    allow(::File).to receive(:absolute_path).and_return("c:\\frost.msi")
    resource.source("c:/frost.msi")
    expect(resource.source).to eql "c:\\frost.msi"
  end

  it "defaults returns to [0, 3010]" do
    expect(resource.returns).to eq([0, 3010])
  end

  it "does not accept a string for the package_name property" do
    expect { resource.package_name(%w{this should break}) }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  # even though we don't do anything with arrays of versions we need them for current_value
  it "accepts both Strings and Arrays for the version property" do
    expect { resource.version "1.2.3" }.not_to raise_error
    expect { resource.version ["1.2.3", "1.2.3.4"] }.not_to raise_error
  end

  it "defaults source to the resource name" do
    # it's a little late to stub out File.absolute_path
    expect(resource.source).to include("solitaire.msi")
  end

  it "lowercases values provided in the checksum property" do
    resource.checksum("SOMECHECKSUM")
    expect(resource.checksum).to eq("somechecksum")
  end

  context "when a URL is used" do
    let(:resource_source) { "https://foo.bar/solitare.msi" }
    let(:resource) { Chef::Resource::WindowsPackage.new(resource_source) }

    it "returns the source unmodified" do
      expect(resource.source).to eq(resource_source)
    end
  end
end
