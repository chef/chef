#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

describe Chef::Resource::EasyInstallPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::EasyInstallPackage,
    provider: Chef::Provider::Package::EasyInstall,
    name: :easy_install_package,
    action: :install
  )

  before(:each) do
    @resource = Chef::Resource::EasyInstallPackage.new("foo")
  end

  it "should allow you to set the easy_install_binary attribute" do
    @resource.easy_install_binary "/opt/local/bin/easy_install"
    expect(@resource.easy_install_binary).to eql("/opt/local/bin/easy_install")
  end
end
