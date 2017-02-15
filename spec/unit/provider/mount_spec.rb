#
# Author:: Joshua Timberman (<joshua@chef.io>)
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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

describe Chef::Provider::Mount do

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) do
    new_resource = Chef::Resource::Mount.new("/tmp/foo")
    new_resource.device      "/dev/sdz1"
    new_resource.name        "/tmp/foo"
    new_resource.mount_point "/tmp/foo"
    new_resource.fstype      "ext3"
    new_resource
  end

  let(:current_resource) do
    # this abstract superclass has no load_current_resource to call
    current_resource = Chef::Resource::Mount.new("/tmp/foo")
    current_resource.device      "/dev/sdz1"
    current_resource.name        "/tmp/foo"
    current_resource.mount_point "/tmp/foo"
    current_resource.fstype      "ext3"
    current_resource
  end

  let(:provider) do
    provider = Chef::Provider::Mount.new(new_resource, run_context)
    provider.current_resource = current_resource
    provider
  end

  describe "when the target state is a mounted filesystem" do

    it "should mount the filesystem if it isn't mounted" do
      allow(current_resource).to receive(:mounted).and_return(false)
      expect(provider).to receive(:mount_fs).and_return(true)
      provider.run_action(:mount)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "when the target state is an unmounted filesystem" do
    it "should umount the filesystem if it is mounted" do
      allow(current_resource).to receive(:mounted).and_return(true)
      expect(provider).to receive(:umount_fs).and_return(true)
      provider.run_action(:umount)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should unmount the filesystem if it is mounted" do
      allow(current_resource).to receive(:mounted).and_return(true)
      expect(provider).to receive(:umount_fs).and_return(true)
      provider.run_action(:unmount)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not umount the filesystem if it is not mounted" do
      allow(current_resource).to receive(:mounted).and_return(false)
      expect(provider).not_to receive(:umount_fs)
      provider.run_action(:umount)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "when the filesystem should be remounted and the resource supports remounting" do
    before do
      new_resource.supports[:remount] = true
    end

    it "should remount the filesystem if it is mounted" do
      allow(current_resource).to receive(:mounted).and_return(true)
      expect(provider).to receive(:remount_fs).and_return(true)
      provider.run_action(:remount)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not remount the filesystem if it is not mounted" do
      allow(current_resource).to receive(:mounted).and_return(false)
      expect(provider).not_to receive(:remount_fs)
      provider.run_action(:remount)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "when the filesystem should be remounted and the resource does not support remounting" do
    before do
      new_resource.supports[:remount] = false
      allow(current_resource).to receive(:mounted).and_return(true)
    end

    it "should try a umount/remount of the filesystem" do
      expect(provider).to receive(:umount_fs)
      expect(provider).to receive(:mounted?).and_return(true, false)
      expect(provider).to receive(:mount_fs)
      provider.run_action(:remount)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should fail when it runs out of remounts" do
      provider.unmount_retries = 1
      expect(provider).to receive(:umount_fs)
      expect(provider).to receive(:mounted?).and_return(true, true)
      expect { provider.run_action(:remount) }.to raise_error(Chef::Exceptions::Mount)
    end
  end

  describe "when enabling the filesystem to be mounted" do
    it "should enable the mount if it isn't enable" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).not_to receive(:mount_options_unchanged?)
      expect(provider).to receive(:enable_fs).and_return(true)
      provider.run_action(:enable)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should enable the mount if it is enabled and mount options have changed" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:mount_options_unchanged?).and_return(false)
      expect(provider).to receive(:enable_fs).and_return(true)
      provider.run_action(:enable)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not enable the mount if it is enabled and mount options have not changed" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:mount_options_unchanged?).and_return(true)
      expect(provider).not_to receive(:enable_fs)
      provider.run_action(:enable)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "when the target state is to disable the mount" do
    it "should disable the mount if it is enabled" do
      allow(current_resource).to receive(:enabled).and_return(true)
      expect(provider).to receive(:disable_fs).and_return(true)
      provider.run_action(:disable)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should not disable the mount if it isn't enabled" do
      allow(current_resource).to receive(:enabled).and_return(false)
      expect(provider).not_to receive(:disable_fs)
      provider.run_action(:disable)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  it "should delegates the mount implementation to subclasses" do
    expect { provider.mount_fs }.to raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the umount implementation to subclasses" do
    expect { provider.umount_fs }.to raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the remount implementation to subclasses" do
    expect { provider.remount_fs }.to raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the enable implementation to subclasses" do
    expect { provider.enable_fs }.to raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should delegates the disable implementation to subclasses" do
    expect { provider.disable_fs }.to raise_error(Chef::Exceptions::UnsupportedAction)
  end
end
