#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::RhsmSubscription do
  let(:event_dispatch) { Chef::EventDispatch::Dispatcher.new }
  let(:node) { Chef::Node.new }
  let(:run_context) { Chef::RunContext.new(node, {}, event_dispatch) }

  let(:pool_id) { "8a8dd78c766232550226b46e59404aba" }
  let(:resource) { Chef::Resource::RhsmSubscription.new(pool_id, run_context) }
  let(:provider) { resource.provider_for_action(Array(resource.action).first) }

  before do
    allow(resource).to receive(:provider_for_action).with(:attach).and_return(provider)
  end

  it "has a resource name of :rhsm_subscription" do
    expect(resource.resource_name).to eql(:rhsm_subscription)
  end

  it "the pool_id property is the name_property" do
    expect(resource.pool_id).to eql(pool_id)
  end

  it "sets the default action as :attach" do
    expect(resource.action).to eql([:attach])
  end

  it "supports :attach, :remove actions" do
    expect { resource.action :attach }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#action_attach" do
    let(:yum_package_double) { instance_double("Chef::Resource::YumPackage") }
    let(:so_double) { instance_double("Mixlib::ShellOut", stdout: "Successfully attached a subscription for: My Subscription", exitstatus: 0, error?: false) }

    before do
      allow(provider).to receive(:shell_out!).with("subscription-manager attach --pool=#{resource.pool_id}").and_return(so_double)
      allow(provider).to receive(:build_resource).with(:package, "rhsm_subscription-#{pool_id}-flush_cache").and_return(yum_package_double)
      allow(yum_package_double).to receive(:run_action).with(:flush_cache)
    end

    context "when already attached to pool" do
      before do
        allow(provider).to receive(:subscription_attached?).with(resource.pool_id).and_return(true)
      end

      it "does not attach to pool" do
        expect(provider).not_to receive(:shell_out!)
        resource.run_action(:attach)
      end
    end

    context "when not attached to pool" do
      before do
        allow(provider).to receive(:subscription_attached?).with(resource.pool_id).and_return(false)
      end

      it "attaches to pool" do
        expect(provider).to receive(:shell_out!).with("subscription-manager attach --pool=#{resource.pool_id}")
        resource.run_action(:attach)
      end

      it "flushes package provider cache" do
        expect(yum_package_double).to receive(:run_action).with(:flush_cache)
        resource.run_action(:attach)
      end
    end
  end

  describe "#subscription_attached?" do
    let(:cmd)    { double("cmd") }
    let(:output) { "Pool ID:    pool123" }

    before do
      allow(Mixlib::ShellOut).to receive(:new).and_return(cmd)
      allow(cmd).to receive(:run_command)
      allow(cmd).to receive(:live_stream).and_return(output)
      allow(cmd).to receive(:stdout).and_return(output)
    end

    context "when the pool provided matches the output" do
      it "returns true" do
        expect(provider.subscription_attached?("pool123")).to eq(true)
      end
    end

    context "when the pool provided does not match the output" do
      it "returns false" do
        expect(provider.subscription_attached?("differentpool")).to eq(false)
      end
    end
  end

  describe "#serials_by_pool" do
    let(:cmd) { double("cmd") }
    let(:output) do
      <<~EOL
        Key1:       value1
        Pool ID:    pool1
        Serial:     serial1
        Key2:       value2

        Key1:       value1
        Pool ID:    pool2
        Serial:     serial2
        Key2:       value2
      EOL
    end

    it "parses the output correctly" do
      allow(Mixlib::ShellOut).to receive(:new).and_return(cmd)
      allow(cmd).to receive(:run_command)
      allow(cmd).to receive(:live_stream).and_return(output)
      allow(cmd).to receive(:stdout).and_return(output)

      expect(provider.serials_by_pool["pool1"]).to eq("serial1")
      expect(provider.serials_by_pool["pool2"]).to eq("serial2")
    end
  end

  describe "#pool_serial" do
    let(:serials) { { "pool1" => "serial1", "pool2" => "serial2" } }

    it "returns the serial for a given pool" do
      allow(provider).to receive(:serials_by_pool).and_return(serials)
      expect(provider.pool_serial("pool1")).to eq("serial1")
    end
  end
end
