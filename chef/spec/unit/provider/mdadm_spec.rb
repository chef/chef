#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright (c) 2009 Joe Williams
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

require 'spec_helper'

describe Chef::Provider::Mdadm do
  include SpecHelpers::Provider

  let(:resource_name) { md_device }
  let(:resource_class) { Chef::Resource::Mdadm }

  let(:new_resource_attributes) do
    { :devices => devices,
      :level   => level,
      :chunk   => chunk }
  end

  let(:md_device) { '/dev/md1' }
  let(:devices) { %w(/dev/sdz1 /dev/sdz2) }
  let(:level) { 1 }
  let(:chunk) { 256 }
  let(:stdout) { md_device }

  describe "#load_current_resource" do
    subject { provider.load_current_resource }

    it "should set the current resources mount point to the new resources mount point" do
      should_shell_out!

      subject.name.should eql md_device
      subject.raid_device.should eql md_device
    end

    it "determines that the metadevice exists when mdadm output shows the metadevice" do
      provider.stub!(:shell_out!).with("mdadm --detail --scan").and_return(status)
      provider.load_current_resource
      provider.current_resource.exists.should be_true
    end
  end

  describe "after the metadevice status is known" do
    before(:each) do
      current_resource.devices devices
      current_resource.level   level
      current_resource.chunk   chunk
      provider.current_resource = current_resource
    end

    #let(:expected_command) { "yes | mdadm --create /dev/md1 --chunk=256 --level 1 --metadata=0.90 --raid-devices 2 /dev/sdz1 /dev/sdz2" }
    let(:expected_command) { "yes | mdadm --create /dev/md1 --chunk=256 --level 1 --metadata=0.90 --bitmap=none --raid-devices 2 /dev/sdz1 /dev/sdz2" }

    describe "#action_create" do
      it "should create the raid device if it doesnt exist" do
        current_resource.exists false
        provider.should_receive(:shell_out!).with(expected_command)
        provider.action_create
      end

      it "should not create the raid device if it does exist" do
        current_resource.exists true
        provider.should_not_receive(:shell_out!)
        provider.action_create
      end
    end

    describe "#action_assemble" do
      let(:expected_mdadm_cmd) { "yes | mdadm --assemble /dev/md1 /dev/sdz1 /dev/sdz2" }

      it "should assemble the raid device if it doesnt exist" do
        current_resource.exists false
        provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        provider.action_assemble
      end

      it "should not assemble the raid device if it doesnt exist" do
        current_resource.exists true
        provider.should_not_receive(:shell_out!)
        provider.action_assemble
      end
    end

    describe "#action_stop" do
      let(:expected_mdadm_cmd) { "yes | mdadm --stop /dev/md1" }

      it "should stop the raid device if it exists" do
        current_resource.exists true
        provider.should_receive(:shell_out!).with(expected_mdadm_cmd)
        provider.action_stop
      end

      it "should not attempt to stop the raid device if it does not exist" do
        current_resource.exists false
        provider.should_not_receive(:shell_out!)
        provider.action_stop
      end
    end
  end
end
