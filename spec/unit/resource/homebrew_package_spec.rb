#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::HomebrewPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::HomebrewPackage,
    provider: Chef::Provider::Package::Homebrew,
    name: :homebrew_package,
    action: :install,
    os: "mac_os_x"
  )

  let(:resource) { Chef::Resource::HomebrewPackage.new("emacs") }

  it "is a subclass of Chef::Resource::Package" do
    expect(resource).to be_a_kind_of(Chef::Resource::Package)
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

  shared_examples "home_brew user set and returned" do
    it "returns the configured homebrew_user" do
      resource.homebrew_user user
      expect(resource.homebrew_user).to eql(user)
    end
  end

  context "homebrew_user is set" do
    let(:user) { "Captain Picard" }
    include_examples "home_brew user set and returned"

    context "as an integer" do
      let(:user) { 1001 }
      include_examples "home_brew user set and returned"
    end
  end

end
