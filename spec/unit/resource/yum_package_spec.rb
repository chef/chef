#
# Author:: AJ Christensen (<aj@opscode.com>)
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

describe Chef::Resource::YumPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::YumPackage,
    provider: Chef::Provider::Package::Yum,
    name: :yum_package,
    action: :install,
    os: 'linux',
    platform_family: 'rhel',
  )

end

describe Chef::Resource::YumPackage, "arch" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "should set the arch variable to whatever is passed in" do
    @resource.arch("i386")
    expect(@resource.arch).to eql("i386")
  end
end

describe Chef::Resource::YumPackage, "flush_cache" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "should default the flush timing to false" do
    flush_hash = { :before => false, :after => false }
    expect(@resource.flush_cache).to eq(flush_hash)
  end

  it "should allow you to set the flush timing with an array" do
    flush_array = [ :before, :after ]
    flush_hash = { :before => true, :after => true }
    @resource.flush_cache(flush_array)
    expect(@resource.flush_cache).to eq(flush_hash)
  end

  it "should allow you to set the flush timing with a hash" do
    flush_hash = { :before => true, :after => true }
    @resource.flush_cache(flush_hash)
    expect(@resource.flush_cache).to eq(flush_hash)
  end
end

describe Chef::Resource::YumPackage, "allow_downgrade" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "should allow you to specify whether allow_downgrade is true or false" do
    expect { @resource.allow_downgrade true }.not_to raise_error
    expect { @resource.allow_downgrade false }.not_to raise_error
    expect { @resource.allow_downgrade "monkey" }.to raise_error(ArgumentError)
  end
end
