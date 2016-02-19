#
# Author:: Bryan McLellan <btm@chef.io>
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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

describe Chef::Resource::IpsPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::IpsPackage,
    provider: Chef::Provider::Package::Ips,
    name: :ips_package,
    action: :install,
    os: "solaris2"
  )

  before(:each) do
    @resource = Chef::Resource::IpsPackage.new("crypto/gnupg")
  end

  it "should support accept_license" do
    @resource.accept_license(true)
    expect(@resource.accept_license).to eql(true)
  end
end
