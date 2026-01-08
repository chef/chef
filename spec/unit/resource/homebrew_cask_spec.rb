#
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

describe Chef::Resource::HomebrewCask do

  context "name with under bar" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey_fakerton") }

    it "has a resource name of :homebrew_cask" do
      expect(resource.resource_name).to eql(:homebrew_cask)
    end

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey_fakerton")
    end

    it "sets the default action as :install" do
      expect(resource.action).to eql([:install])
    end

    it "supports :install, :remove actions" do
      expect { resource.action :install }.not_to raise_error
      expect { resource.action :remove }.not_to raise_error
    end
  end

  context "name with high fun" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey-fakerton") }

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey-fakerton")
    end
  end

  context "name with at mark" do
    let(:resource) { Chef::Resource::HomebrewCask.new("fakey-fakerton@10") }

    it "the cask_name property is the name_property" do
      expect(resource.cask_name).to eql("fakey-fakerton@10")
    end
  end
end
