#
# Author:: Prabhu Das (<prabhu.das@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::SolarisPackage, "initialize" do

  %w{solaris2 nexentacore}.each do |platform_family|
    static_provider_resolution(
      resource: Chef::Resource::SolarisPackage,
      provider: Chef::Provider::Package::Solaris,
      name: :solaris_package,
      action: :install,
      os: "solaris2",
      platform_family: platform_family
    )
  end

  before(:each) do
    @resource = Chef::Resource::SolarisPackage.new("foo")
  end

  it "should set the package_name to the name provided" do
    expect(@resource.package_name).to eql("foo")
  end
end
