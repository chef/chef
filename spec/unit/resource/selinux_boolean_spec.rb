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

describe Chef::Resource::SelinuxBoolean do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxBoolean.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:set) }
  let(:selinux_state) { double("shellout!", stdout: "permissive") }

  it "sets boolean proprty as name_property" do
    expect(resource.boolean).to eql("fakey_fakerton")
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports :set action" do
    expect { resource.action :set }.not_to raise_error
  end

  context "coercing value property" do
    it "should set value properly to 'on' when valid parameter is sent and is literal positive" do
      resource.value = 1
      expect(resource.value).to eql("on")

      resource.value = "true"
      expect(resource.value).to eql("on")

      resource.value = true
      expect(resource.value).to eql("on")
    end

    it "should set value properly to 'off' when valid parameter is sent and is literal negative" do
      resource.value = 0
      expect(resource.value).to eql("off")

      resource.value = "false"
      expect(resource.value).to eql("off")

      resource.value = false
      expect(resource.value).to eql("off")
    end

    it "should raise an exception if invalid parameter is sent" do
      expect do
        resource.value = "ON"
      end.to raise_error(ArgumentError)
    end
  end

  describe "#Chef::SELinux::CommonHelpers" do
    context "#selinux_permissive?" do
      it "should return true if selinux_state is :permissive" do
        allow(provider).to receive(:shell_out!).and_return(selinux_state)
        expect(provider.selinux_permissive?).to eql(true)
      end
    end

    context "#selinux_disabled?" do
      it "should return false if selinux_state is :permissive" do
        allow(provider).to receive(:shell_out!).and_return(selinux_state)
        expect(provider.selinux_disabled?).to eql(false)
      end
    end

    context "#selinux_enforcing?" do
      it "should return false if selinux_state is :permissive" do
        allow(provider).to receive(:shell_out!).and_return(selinux_state)
        expect(provider.selinux_enforcing?).to eql(false)
      end
    end
  end
end
