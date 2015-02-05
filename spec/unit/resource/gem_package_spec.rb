#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
require 'support/shared/unit/resource/static_provider_resolution'

describe Chef::Resource::GemPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::GemPackage,
    provider: Chef::Provider::Package::Rubygems,
    name: :gem_package,
    action: :install,
  )

end

describe Chef::Resource::GemPackage, "gem_binary" do
  before(:each) do
    @resource = Chef::Resource::GemPackage.new("foo")
  end

  it "should set the gem_binary variable to whatever is passed in" do
    @resource.gem_binary("/opt/local/bin/gem")
    expect(@resource.gem_binary).to eql("/opt/local/bin/gem")
  end
end
