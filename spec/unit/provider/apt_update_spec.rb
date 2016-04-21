#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

describe Chef::Provider::AptUpdate do
  let(:new_resource) { Chef::Resource::AptUpdate.new("update") }

  let(:config_dir) { Dir.mktmpdir("apt_update_apt_conf_d") }
  let(:config_file) { File.join(config_dir, "15update-stamp") }
  let(:stamp_dir) { Dir.mktmpdir("apt_update_periodic") }

  before do
    stub_const("Chef::Provider::AptUpdate::APT_CONF_DIR", config_dir)
    stub_const("Chef::Provider::AptUpdate::STAMP_DIR", stamp_dir)
  end

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::AptUpdate.new(new_resource, run_context)
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  context "when the apt config directory does not exist" do
    before do
      FileUtils.rmdir config_dir
      expect(File.exist?(config_dir)).to be false
      allow_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!).with("apt-get -q update", anything())
    end

    it "should create the directory" do
      provider.run_action(:update)
      expect(File.exist?(config_dir)).to be true
      expect(File.directory?(config_dir)).to be true
    end

    it "should create the config file" do
      provider.run_action(:update)
      expect(File.exist?(config_file)).to be true
      expect(File.read(config_file)).to match(/^APT::Update.*#{stamp_dir}/)
    end
  end

  describe "#action_update" do
    it "should update the apt cache" do
      provider.load_current_resource
      expect_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!).with("apt-get -q update", anything())
      provider.run_action(:update)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "#action_periodic" do
    before do
      allow(File).to receive(:exist?)
      allow(File).to receive(:exist?).with(Dir.tmpdir).and_return(true)
      expect(File).to receive(:exist?).with("#{stamp_dir}/update-success-stamp").and_return(true)
    end

    it "should run if the time stamp is old" do
      expect(File).to receive(:mtime).with("#{stamp_dir}/update-success-stamp").and_return(Time.now - 86_500)
      expect_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!).with("apt-get -q update", anything())
      provider.run_action(:periodic)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not run if the time stamp is new" do
      expect(File).to receive(:mtime).with("#{stamp_dir}/update-success-stamp").and_return(Time.now)
      expect_any_instance_of(Chef::Provider::Execute).not_to receive(:shell_out!).with("apt-get -q update", anything())
      provider.run_action(:periodic)
      expect(new_resource).to_not be_updated_by_last_action
    end

    context "with a different frequency" do
      before do
        new_resource.frequency(400)
      end

      it "should run if the time stamp is old" do
        expect(File).to receive(:mtime).with("#{stamp_dir}/update-success-stamp").and_return(Time.now - 500)
        expect_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!).with("apt-get -q update", anything())
        provider.run_action(:periodic)
        expect(new_resource).to be_updated_by_last_action
      end

      it "should not run if the time stamp is new" do
        expect(File).to receive(:mtime).with("#{stamp_dir}/update-success-stamp").and_return(Time.now - 300)
        expect_any_instance_of(Chef::Provider::Execute).not_to receive(:shell_out!).with("apt-get -q update", anything())
        provider.run_action(:periodic)
        expect(new_resource).to_not be_updated_by_last_action
      end
    end
  end
end
