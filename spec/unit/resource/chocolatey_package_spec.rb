#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

describe Chef::Resource::ChocolateyPackage do

  let(:resource) { Chef::Resource::ChocolateyPackage.new("fakey_fakerton") }

  it "should create a new Chef::Resource::ChocolateyPackage" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
    expect(resource).to be_a_instance_of(Chef::Resource::ChocolateyPackage)
  end

  it "should have a resource name of :python" do
    expect(resource.resource_name).to eql(:chocolatey_package)
  end

  it "should coerce its name to a package_name array" do
    expect(resource.package_name).to eql(["fakey_fakerton"])
  end

  it "the package_name setter should coerce to arrays" do
    resource.package_name("git")
    expect(resource.package_name).to eql(["git"])
  end

  it "the package_name setter should accept arrays" do
    resource.package_name(%w{git unzip})
    expect(resource.package_name).to eql(%w{git unzip})
  end

  it "the name should accept arrays" do
    resource = Chef::Resource::ChocolateyPackage.new(%w{git unzip})
    expect(resource.package_name).to eql(%w{git unzip})
  end

  it "the default version should be nil" do
    expect(resource.version).to eql(nil)
  end

  it "the version setter should coerce to arrays" do
    resource.version("1.2.3")
    expect(resource.version).to eql(["1.2.3"])
  end

  it "the version setter should accept arrays" do
    resource.version(["1.2.3", "4.5.6"])
    expect(resource.version).to eql(["1.2.3", "4.5.6"])
  end

  it "the default returns should be 0" do
    expect(resource.returns).to eql([0])
  end

  # Integer, Array
  [ 0, [0, 48, 49] ].each do |val|
    it "supports setting an alternate return value as a #{val.class}" do
      resource.returns(val)
      expect(resource.returns).to eql(val)
    end
  end
end
