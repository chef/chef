#
# Author:: Joe Williams (<joe@joetify.com>)
# Copyright:: Copyright 2009-2016, Joe Williams
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
require "ostruct"

describe Chef::Provider::Mdadm do

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Mdadm.new("/dev/md1")
    @new_resource.devices ["/dev/sdz1", "/dev/sdz2", "/dev/sdz3"]
    @provider = Chef::Provider::Mdadm.new(@new_resource, @run_context)
  end

  describe "when determining the current metadevice status" do
    it "should set the current resources mount point to the new resources mount point" do
      allow(@provider).to receive(:shell_out!).and_return(OpenStruct.new(:status => 0))
      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("/dev/md1")
      expect(@provider.current_resource.raid_device).to eq("/dev/md1")
    end

    it "determines that the metadevice exists when mdadm exit code is zero" do
      allow(@provider).to receive(:shell_out!).with("mdadm --detail --test /dev/md1", :returns => [0, 4]).and_return(OpenStruct.new(:status => 0))
      @provider.load_current_resource
      expect(@provider.current_resource.exists).to be_truthy
    end

    it "determines that the metadevice does not exist when mdadm exit code is 4" do
      allow(@provider).to receive(:shell_out!).with("mdadm --detail --test /dev/md1", :returns => [0, 4]).and_return(OpenStruct.new(:status => 4))
      @provider.load_current_resource
      expect(@provider.current_resource.exists).to be_falsey
    end
  end

  describe "after the metadevice status is known" do
    before(:each) do
      @current_resource = Chef::Resource::Mdadm.new("/dev/md1")
      @new_resource.level 5
      allow(@provider).to receive(:load_current_resource).and_return(true)
      @provider.current_resource = @current_resource
    end

    describe "when creating the metadevice" do
      it "should create the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_command = "yes | mdadm --create /dev/md1 --level 5 --chunk=16 --metadata=0.90 --raid-devices 3 /dev/sdz1 /dev/sdz2 /dev/sdz3"
        expect(@provider).to receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
      end

      it "should specify a bitmap only if set" do
        @current_resource.exists(false)
        @new_resource.bitmap("grow")
        expected_command = "yes | mdadm --create /dev/md1 --level 5 --chunk=16 --metadata=0.90 --bitmap=grow --raid-devices 3 /dev/sdz1 /dev/sdz2 /dev/sdz3"
        expect(@provider).to receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should specify a layout only if set" do
        @current_resource.exists(false)
        @new_resource.layout("rs")
        expected_command = "yes | mdadm --create /dev/md1 --level 5 --chunk=16 --metadata=0.90 --layout=rs --raid-devices 3 /dev/sdz1 /dev/sdz2 /dev/sdz3"
        expect(@provider).to receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should not specify a chunksize if raid level 1" do
        @current_resource.exists(false)
        @new_resource.level 1
        expected_command = "yes | mdadm --create /dev/md1 --level 1 --metadata=0.90 --raid-devices 3 /dev/sdz1 /dev/sdz2 /dev/sdz3"
        expect(@provider).to receive(:shell_out!).with(expected_command)
        @provider.run_action(:create)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should not create the raid device if it does exist" do
        @current_resource.exists(true)
        expect(@provider).not_to receive(:shell_out!)
        @provider.run_action(:create)
        expect(@new_resource).not_to be_updated_by_last_action
      end
    end

    describe "when asembling the metadevice" do
      it "should assemble the raid device if it doesnt exist" do
        @current_resource.exists(false)
        expected_mdadm_cmd = "yes | mdadm --assemble /dev/md1 /dev/sdz1 /dev/sdz2 /dev/sdz3"
        expect(@provider).to receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.run_action(:assemble)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should not assemble the raid device if it doesnt exist" do
        @current_resource.exists(true)
        expect(@provider).not_to receive(:shell_out!)
        @provider.run_action(:assemble)
        expect(@new_resource).not_to be_updated_by_last_action
      end
    end

    describe "when stopping the metadevice" do

      it "should stop the raid device if it exists" do
        @current_resource.exists(true)
        expected_mdadm_cmd = "yes | mdadm --stop /dev/md1"
        expect(@provider).to receive(:shell_out!).with(expected_mdadm_cmd)
        @provider.run_action(:stop)
        expect(@new_resource).to be_updated_by_last_action
      end

      it "should not attempt to stop the raid device if it does not exist" do
        @current_resource.exists(false)
        expect(@provider).not_to receive(:shell_out!)
        @provider.run_action(:stop)
        expect(@new_resource).not_to be_updated_by_last_action
      end
    end
  end
end
