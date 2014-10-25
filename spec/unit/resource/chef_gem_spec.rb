#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2008, 2012 Opscode, Inc.
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

describe Chef::Resource::ChefGem, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::ChefGem,
    provider: Chef::Provider::Package::Rubygems,
    name: :chef_gem,
    action: :install,
  )

end

describe Chef::Resource::ChefGem, "gem_binary" do
  before(:each) do
    expect(RbConfig::CONFIG).to receive(:[]).with('bindir').and_return("/opt/chef/embedded/bin")
    @resource = Chef::Resource::ChefGem.new("foo")
  end

  it "should raise an exception when gem_binary is set" do
    expect { @resource.gem_binary("/lol/cats/gem") }.to raise_error(ArgumentError)
  end

  it "should set the gem_binary based on computing it from RbConfig" do
    expect(@resource.gem_binary).to eql("/opt/chef/embedded/bin/gem")
  end
end
