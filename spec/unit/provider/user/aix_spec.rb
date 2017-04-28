# Copyright:: Copyright 2017, Chef Software Inc.
#
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

require "mixlib/shellout"
require "spec_helper"

describe Chef::Provider::User::Aix do

  let(:shellcmdresult) do
    Struct.new(:stdout, :stderr, :exitstatus)
  end

  let(:node) do
    Chef::Node.new.tap do |node|
      node.automatic["platform"] = "solaris2"
    end
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::User::AixUser.new("adam", @run_context)
  end
  let(:current_resource) do
    Chef::Resource::User::AixUser.new("adam", @run_context).tap do |cr|
      cr.home "/home/adam"
    end
  end

  subject(:provider) do
    described_class.new(new_resource, run_context).tap do |p|
      p.current_resource = current_resource
    end
  end

  describe "when we set a password" do
    before do
      new_resource.password "Ostagazuzulum"
    end

    it "should call chpasswd correctly" do
      expect(provider).to receive(:shell_out!).with("echo 'adam:Ostagazuzulum' | chpasswd -e").and_return true
      provider.manage_user
    end
  end

  describe "#create_user" do
    context "with a system user" do
      before { new_resource.system(true) }
      it "should add the user to the system group" do
        expect(provider).to receive(:shell_out!).with("useradd", "-g", "system", "adam")
        provider.create_user
      end
    end

    context "with manage_home" do
      before do
        new_resource.manage_home(true)
        new_resource.home("/home/adam")
        allow(provider).to receive(:updating_home?).and_return(true)
      end

      it "should create the home directory" do
        allow(provider).to receive(:shell_out!).with("usermod", "-d", "/home/adam", "adam")
        expect(FileUtils).to receive(:mkdir_p).and_return(true)
        provider.manage_user
      end

      it "should move an existing home dir" do
        allow(provider).to receive(:shell_out!).with("usermod", "-d", "/mnt/home/adam", "adam")
        new_resource.home("/mnt/home/adam")
        allow(File).to receive(:directory?).with("/home/adam").and_return(true)
        expect(FileUtils).to receive(:mv).with("/home/adam", "/mnt/home/adam")
        provider.manage_user
      end

      it "should not pass -m" do
        allow(FileUtils).to receive(:mkdir_p).and_return(true)
        expect(provider).to receive(:shell_out!).with("usermod", "-d", "/home/adam", "adam")
        provider.manage_user
      end
    end
  end
end
