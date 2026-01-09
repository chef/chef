#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Resource::ChocolateyPackage do

  let(:resource) { Chef::Resource::ChocolateyPackage.new("fakey_fakerton") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
  end

  it "has a resource name of :chocolatey_package" do
    expect(resource.resource_name).to eql(:chocolatey_package)
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

  it "coerces its name to a package_name array" do
    expect(resource.package_name).to eql(["fakey_fakerton"])
  end

  it "the package_name setter coerces to arrays" do
    resource.package_name("git")
    expect(resource.package_name).to eql(["git"])
  end

  it "the package_name setter accepts arrays" do
    resource.package_name(%w{git unzip})
    expect(resource.package_name).to eql(%w{git unzip})
  end

  it "the name accepts arrays" do
    resource = Chef::Resource::ChocolateyPackage.new(%w{git unzip})
    expect(resource.package_name).to eql(%w{git unzip})
  end

  it "the default version is nil" do
    expect(resource.version).to eql(nil)
  end

  it "the version setter coerces to arrays" do
    resource.version("1.2.3")
    expect(resource.version).to eql(["1.2.3"])
  end

  it "the version setter accepts arrays" do
    resource.version(["1.2.3", "4.5.6"])
    expect(resource.version).to eql(["1.2.3", "4.5.6"])
  end

  it "sets the list_options" do
    resource.list_options("--local-only")
    expect(resource.list_options).to eql("--local-only")
  end

  it "sets the user" do
    resource.user("ubuntu")
    expect(resource.user).to eql("ubuntu")
  end

  it "sets the password" do
    resource.password("ubuntu@123")
    expect(resource.password).to eql("ubuntu@123")
  end

  it "the default returns are 0 and 2" do
    expect(resource.returns).to eql([0, 2])
  end

  # Integer, Array
  [ 0, [0, 48, 49] ].each do |val|
    it "supports setting an alternate return value as a #{val.class}" do
      resource.returns(val)
      expect(resource.returns).to eql(val)
    end
  end
end
