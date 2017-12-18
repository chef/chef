#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@msystechnologies.com>)
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

describe Chef::Resource::CabPackage do

  let(:resource) { Chef::Resource::CabPackage.new("test_pkg") }

  it "creates a new Chef::Resource::CabPackage" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
    expect(resource).to be_a_instance_of(Chef::Resource::CabPackage)
  end

  it "sets resource name as :cab_package" do
    expect(resource.resource_name).to eql(:cab_package)
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "coerces name property to package_name property" do
    expect(resource.package_name).to eql("test_pkg")
  end

  it "coerces name property to a source property if source not provided" do
    expect(resource.source).to end_with("test_pkg")
  end

  it "coerces name property to a source property if source not provided and package_name is" do
    resource.package_name("package.cab")
    expect(resource.source).to end_with("package.cab")
  end

  it "coerces source property if it does not looks like a path" do
    resource.source("package.cab")
    expect(resource.source).not_to eq("package.cab")
  end
end
