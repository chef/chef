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

describe Chef::Resource::SelinuxUser do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxUser.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:manage) }
  let(:semanage_list) { double("shellout", stdout: "") }

  it "sets user property as name_property" do
    expect(resource.user).to eql("fakey_fakerton")
  end

  it "sets the default action as :manage" do
    expect(resource.action).to eql([:manage])
  end

  it "supports :manage, :add, :modify, :delete actions" do
    expect { resource.action :manage }.not_to raise_error
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :modify }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end

  it "sorts roles property values" do
    expect { resource.roles %w{c a b} }.not_to raise_error
    expect(resource.roles).to eq(%w{a b c})
  end

  describe "#semanage_user_args" do
    let(:provider) { resource.provider_for_action(:modify) }

    context "when no parameters are provided" do
      it "returns an empty string" do
        expect(provider.semanage_user_args).to eq("")
      end
    end

    context "when all parameters are provided" do
      it "returns all params" do
        resource.level "s0"
        resource.range "s0"
        resource.roles %w{sysadm_r staff_r}
        expect(provider.semanage_user_args).to eq(" -L s0 -r s0 -R 'staff_r sysadm_r'")
      end
    end

    context "when no roles are provided" do
      it "returns level and range params" do
        resource.level "s0"
        resource.range "s0"
        resource.roles []

        expect(provider.semanage_user_args).to eq(" -L s0 -r s0")
      end
    end

    context "when no range is provided" do
      it "returns level and roles params" do
        resource.level "s0"
        resource.roles %w{sysadm_r staff_r}
        expect(provider.semanage_user_args).to eq(" -L s0 -R 'staff_r sysadm_r'")
      end
    end

    context "when no level is provided" do
      it "returns range and roles params" do
        resource.range "s0"
        resource.roles %w{sysadm_r staff_r}
        expect(provider.semanage_user_args).to eq(" -r s0 -R 'staff_r sysadm_r'")
      end
    end
  end
end
