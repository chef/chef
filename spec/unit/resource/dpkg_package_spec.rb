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

describe Chef::Resource::DpkgPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::DpkgPackage,
    provider: Chef::Provider::Package::Dpkg,
    name: :dpkg_package,
    action: :install,
    os: "linux"
  )

  describe Chef::Resource::DpkgPackage, "defaults" do
    let(:resource) { Chef::Resource::DpkgPackage.new("fakey_fakerton") }

    it "sets the default action as :install" do
      expect(resource.action).to eql([:install])
    end

    it "accepts a string for the response file" do
      resource.response_file "something"
      expect(resource.response_file).to eql("something")
    end

    it "accepts a hash for response file template variables" do
      resource.response_file_variables({ variables: true })
      expect(resource.response_file_variables).to eql({ variables: true })
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
  end

  describe Chef::Resource::DpkgPackage, "allow_downgrade" do
    before(:each) do
      @resource = Chef::Resource::DpkgPackage.new("fakey_fakerton")
    end

    it "should allow you to specify whether allow_downgrade is true or false" do
      expect { @resource.allow_downgrade true }.not_to raise_error
      expect { @resource.allow_downgrade false }.not_to raise_error
      expect { @resource.allow_downgrade "something" }.to raise_error(ArgumentError)
    end
  end

end
