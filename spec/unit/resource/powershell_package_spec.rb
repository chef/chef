#
# Author:: Dheeraj Dubey(<dheeraj.dubey@msystechnologies.com>)
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

describe Chef::Resource::PowershellPackage do

  let(:resource) { Chef::Resource::PowershellPackage.new("test_package") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
  end

  # to check the value of resource.resource_name
  it "has a resource name of :powershell_package" do
    expect(resource.resource_name).to eql(:powershell_package)
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
    expect(resource.package_name).to eql(["test_package"])
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
    resource = Chef::Resource::PowershellPackage.new(%w{git unzip})
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

  it "the default source is nil" do
    expect(resource.source).to eql(nil)
  end

  it "the source setter accepts strings" do
    resource.source("MyGallery")
    expect(resource.source).to eql("MyGallery")
  end

  it "the skip_publisher_check default is false" do
    expect(resource.skip_publisher_check).to eql(false)
  end

  it "the skip_publisher_check setter accepts booleans" do
    resource.skip_publisher_check(true)
    expect(resource.skip_publisher_check).to eql(true)
  end
end
