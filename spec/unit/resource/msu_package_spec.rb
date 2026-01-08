#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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

describe Chef::Resource::MsuPackage do
  let(:resource) { Chef::Resource::MsuPackage.new("test_pkg") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
  end

  it "sets resource name as :msu_package" do
    expect(resource.resource_name).to eql(:msu_package)
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

  it "coerces name property to package_name property" do
    expect(resource.package_name).to eql("test_pkg")
  end

  it "coerces name property to a source property if source not provided" do
    expect(resource.source).to end_with("test_pkg")
  end

  it "coerces name property to a source property if source not provided and package_name is" do
    resource.package_name("package.msu")
    expect(resource.source).to end_with("package.msu")
  end

  it "coerces source property if it does not looks like a path" do
    resource.source("package.msu")
    expect(resource.source).not_to eq("package.msu")
  end

  it "sets timeout property to 3600 by default" do
    expect(resource.timeout).to eql(3600)
  end
end
