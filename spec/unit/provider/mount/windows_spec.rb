#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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

class Chef
  class Util
    class Windows
      class NetUse
      end
      class Volume
      end
    end
  end
end

GUID = "\\\\?\\Volume{578e72b5-6e70-11df-b5c5-000c29d4a7d9}\\"
REMOTE = "\\\\server-name\\path"

describe Chef::Provider::Mount::Windows do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Mount.new("X:")
    @new_resource.device GUID
    @current_resource = Chef::Resource::Mount.new("X:")
    allow(Chef::Resource::Mount).to receive(:new).and_return(@current_resource)

    @net_use = double("Chef::Util::Windows::NetUse")
    allow(Chef::Util::Windows::NetUse).to receive(:new).and_return(@net_use)
    @vol = double("Chef::Util::Windows::Volume")
    allow(Chef::Util::Windows::Volume).to receive(:new).and_return(@vol)

    @provider = Chef::Provider::Mount::Windows.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when loading the current resource" do
    it "should set mounted true if the mount point is found" do
      allow(@vol).to receive(:device).and_return(@new_resource.device)
      expect(@current_resource).to receive(:mounted).with(true)
      @provider.load_current_resource
    end

    it "should set mounted false if the mount point is not found" do
      allow(@vol).to receive(:device).and_raise(ArgumentError)
      expect(@current_resource).to receive(:mounted).with(false)
      @provider.load_current_resource
    end

    describe "with a local device" do
      before do
        @new_resource.device GUID
        allow(@vol).to receive(:device).and_return(@new_resource.device)
        allow(@net_use).to receive(:device).and_raise(ArgumentError)
      end

      it "should determine the device is a volume GUID" do
        expect(@provider).to receive(:is_volume).with(@new_resource.device).and_return(true)
        @provider.load_current_resource
      end
    end

    describe "with a remote device" do
      before do
        @new_resource.device REMOTE
        allow(@net_use).to receive(:device).and_return(@new_resource.device)
        allow(@vol).to receive(:device).and_raise(ArgumentError)
      end

      it "should determine the device is remote" do
        expect(@provider).to receive(:is_volume).with(@new_resource.device).and_return(false)
        @provider.load_current_resource
      end
    end

    describe "when mounting a file system" do
      before do
        @new_resource.device GUID
        allow(@vol).to receive(:add)
        allow(@vol).to receive(:device).and_raise(ArgumentError)
        @provider.load_current_resource
      end

      it "should mount the filesystem if it is not mounted" do
        expect(@vol).to receive(:add).with(:remote => @new_resource.device,
                                           :username => @new_resource.username,
                                           :domainname => @new_resource.domain,
                                           :password => @new_resource.password)
        @provider.mount_fs
      end

      it "should not mount the filesystem if it is mounted" do
        expect(@vol).not_to receive(:add)
        allow(@current_resource).to receive(:mounted).and_return(true)
        @provider.mount_fs
      end

      context "mount_options_unchanged?" do
        it "should return true if mounted device is the same" do
          allow(@current_resource).to receive(:device).and_return(GUID)
          expect(@provider.send :mount_options_unchanged?).to be true
        end

        it "should return false if mounted device has changed" do
          allow(@current_resource).to receive(:device).and_return("XXXX")
          expect(@provider.send :mount_options_unchanged?).to be false
        end
      end
    end

    describe "when unmounting a file system" do
      before do
        @new_resource.device GUID
        allow(@vol).to receive(:delete)
        allow(@vol).to receive(:device).and_raise(ArgumentError)
        @provider.load_current_resource
      end

      it "should umount the filesystem if it is mounted" do
        allow(@current_resource).to receive(:mounted).and_return(true)
        expect(@vol).to receive(:delete)
        @provider.umount_fs
      end

      it "should not umount the filesystem if it is not mounted" do
        allow(@current_resource).to receive(:mounted).and_return(false)
        expect(@vol).not_to receive(:delete)
        @provider.umount_fs
      end
    end
  end
end
