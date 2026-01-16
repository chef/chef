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

describe Chef::Resource::SelinuxLogin do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxLogin.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:manage) }

  it "sets login property as name_property" do
    expect(resource.login).to eql("fakey_fakerton")
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

  describe "#semanage_login_args" do
    let(:provider) { resource.provider_for_action(:modify) }

    context "when no parameters are provided" do
      it "returns an empty string" do
        expect(provider.semanage_login_args).to eq("")
      end
    end

    context "when all parameters are provided" do
      it "returns all params" do
        resource.user "user_u"
        resource.range "s0"
        expect(provider.semanage_login_args).to eq(" -s user_u -r s0")
      end
    end

    context "when no user is provided" do
      it "returns range param" do
        resource.range "s0"
        expect(provider.semanage_login_args).to eq(" -r s0")
      end
    end

    context "when no range is provided" do
      it "returns user param" do
        resource.user "user_u"
        expect(provider.semanage_login_args).to eq(" -s user_u")
      end
    end
  end
end
