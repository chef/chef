#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

  it "returns a Chef::Resource::WindowsPackage" do
    expect(resource).to be_a_kind_of(Chef::Resource::WindowsPackage)
  end

  it "sets the resource_name to :windows_package" do
    expect(resource.resource_name).to eql(:windows_package)
  end

  it "supports setting installer_type as a symbol" do
    resource.installer_type(:msi)
    expect(resource.installer_type).to eql(:msi)
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

  it "coverts a source to an absolute path" do
    allow(::File).to receive(:absolute_path).and_return("c:\\Files\\frost.msi")
    resource.source("frost.msi")
    expect(resource.source).to eql "c:\\Files\\frost.msi"
  end

  it "converts slashes to backslashes in the source path" do
    allow(::File).to receive(:absolute_path).and_return("c:\\frost.msi")
    resource.source("c:/frost.msi")
    expect(resource.source).to eql "c:\\frost.msi"
  end

  it "defaults source to the resource name" do
    # it's a little late to stub out File.absolute_path
    expect(resource.source).to include("solitaire.msi")
  end

  context 'when a URL is used' do
    let(:resource_source) { 'https://foo.bar/solitare.msi' }
    let(:resource) { Chef::Resource::WindowsPackage.new(resource_source) }

    it "should return the source unmodified" do
      expect(resource.source).to eq(resource_source)
    end
  end
end
