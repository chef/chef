#
# Author:: Stephen Haynes (<sh@nomitor.com>)
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

describe Chef::Provider::Group::Pw do
  let(:logger) { double("Mixlib::Log::Child").as_null_object }

  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    allow(@run_context).to receive(:logger).and_return(logger)

    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.gid 50
    @new_resource.members %w{root aj}

    @current_resource = Chef::Resource::Group.new("aj")
    @current_resource.gid 50
    @current_resource.members %w{root aj}
    @provider = Chef::Provider::Group::Pw.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when setting options for the pw command" do
    it "does not set the gid option if gids match or are unmanaged" do
      expect(@provider.set_options).to eq(["wheel"])
    end

    it "sets the option for gid if it is not nil" do
      @new_resource.gid(42)
      expect(@provider.set_options).to eql(["wheel", "-g", 42])
    end
  end

  describe "when creating a group" do
    it "should run pw groupadd with the return of set_options and set_members_option" do
      @new_resource.gid(23)
      expect(@provider).to receive(:shell_out_compacted!).with("pw", "groupadd", "wheel", "-g", "23", "-M", "root,aj").and_return(true)
      @provider.create_group
    end
  end

  describe "when managing the group" do

    it "should run pw groupmod with the return of set_options" do
      @new_resource.gid(42)
      @new_resource.members(["someone"])
      expect(@provider).to receive(:shell_out_compacted!).with("pw", "groupmod", "wheel", "-g", "42", "-m", "someone").and_return(true)
      expect(@provider).to receive(:shell_out_compacted!).with("pw", "groupmod", "wheel", "-g", "42", "-d", "root,aj").and_return(true)
      @provider.manage_group
    end

  end

  describe "when removing the group" do
    it "should run pw groupdel with the new resources group name" do
      expect(@provider).to receive(:shell_out_compacted!).with("pw", "groupdel", "wheel").and_return(true)
      @provider.remove_group
    end
  end

  describe "when setting group membership" do

    describe "with an empty members array in both the new and current resource" do
      before do
        @new_resource.members([])
        allow(@current_resource).to receive(:members).and_return([])
      end

      it "should set no options" do
        expect(@provider.set_members_options).to eql([ ])
      end
    end

    describe "with an empty members array in the new resource and existing members in the current resource" do
      before do
        @new_resource.members([])
        allow(@current_resource).to receive(:members).and_return(%w{all your base})
      end

      it "should log an appropriate message" do
        expect(logger).to receive(:debug).with("group[wheel] removing group members: all,your,base")
        @provider.set_members_options
      end

      it "should set the -d option with the members joined by ','" do
        expect(@provider.set_members_options).to eql([ ["-d", "all,your,base"] ])
      end
    end

    describe "with supplied members array in the new resource and an empty members array in the current resource" do
      before do
        @new_resource.members(%w{all your base})
        allow(@current_resource).to receive(:members).and_return([])
      end

      it "should log an appropriate debug message" do
        expect(logger).to receive(:debug).with("group[wheel] adding group members: all,your,base")
        @provider.set_members_options
      end

      it "should set the -m option with the members joined by ','" do
        expect(@provider.set_members_options).to eql([[ "-m", "all,your,base" ]])
      end
    end
  end

  describe "load_current_resource" do
    before(:each) do
      @provider.action = :create
      @provider.load_current_resource
      @provider.define_resource_requirements
    end
    it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/pw").and_return(false)
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "shouldn't raise an error if /usr/sbin/pw exists" do
      allow(File).to receive(:exist?).and_return(true)
      expect { @provider.process_resource_requirements }.not_to raise_error
    end
  end
end
