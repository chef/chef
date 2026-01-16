#
# Author:: Adam Jacob (<adam@chef.io>)
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::GemPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::GemPackage,
    provider: Chef::Provider::Package::Rubygems,
    name: :gem_package,
    action: :install
  )

end

describe Chef::Resource::GemPackage, "gem_binary" do
  let(:resource) { Chef::Resource::GemPackage.new("foo") }

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

  it "sets the gem_binary variable to whatever is passed in" do
    resource.gem_binary("/opt/local/bin/gem")
    expect(resource.gem_binary).to eql("/opt/local/bin/gem")
  end
end

describe Chef::Resource::GemPackage, "clear_sources" do
  let(:resource) { Chef::Resource::GemPackage.new("foo") }

  it "is nil by default" do
    expect(resource.clear_sources).to be_nil
  end

  it "sets the default of clear_sources to the config value" do
    Chef::Config[:clear_gem_sources] = true
    expect(resource.clear_sources).to be true
  end
end
