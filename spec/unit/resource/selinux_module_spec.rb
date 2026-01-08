#
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

describe Chef::Resource::SelinuxModule do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxModule.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:create) }

  it "sets module_name property as name_property" do
    expect(resource.module_name).to eql("fakey_fakerton")
  end

  it "sets default value for base_dir property" do
    expect(resource.base_dir).to eql("/etc/selinux/local")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :delete, :install, :remove actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#selinux_module_filepath" do
    it "returns selinux module file path based upon base_dir property and module_name property" do
      resource.base_dir = "/opt/selinux"
      resource.module_name = "my_module"
      file_type = "te"
      expect(provider.selinux_module_filepath(file_type)).to eql("/opt/selinux/my_module.te")
    end
  end
end
