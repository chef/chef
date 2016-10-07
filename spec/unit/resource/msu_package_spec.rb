#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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

describe Chef::Resource::MsuPackage do
  let(:resource) { Chef::Resource::MsuPackage.new("test_pkg") }

  it "creates a new Chef::Resource::MsuPackage" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
    expect(resource).to be_a_instance_of(Chef::Resource::MsuPackage)
  end

  it "sets resource name as :msu_package" do
    expect(resource.resource_name).to eql(:msu_package)
  end

  it "sets the source as it's name" do
    expect(resource.source).to eql("test_pkg")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql(:install)
  end

  it "raises error if invalid action is given" do
    expect { resource.action "abc" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "coerce its name to a package_name" do
    expect(resource.package_name).to eql("test_pkg")
  end
end
