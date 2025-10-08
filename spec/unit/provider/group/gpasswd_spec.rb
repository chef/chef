#
# Author:: AJ Christensen (<aj@chef.io>)
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

describe Chef::Provider::Group::Gpasswd, "modify_group_members" do
  let(:logger) { double("Mixlib::Log::Child").as_null_object }

  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    allow(@run_context).to receive(:logger).and_return(logger)
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.members %w{lobster rage fist}
    @new_resource.append false
    @provider = Chef::Provider::Group::Gpasswd.new(@new_resource, @run_context)
    # @provider.stub(:run_command).and_return(true)
  end

  describe "when determining the current group state" do
    before(:each) do
      @provider.action = :create
      @provider.load_current_resource
      @provider.define_resource_requirements
    end

    # Checking for required binaries is already done in the spec
    # for Chef::Provider::Group - no need to repeat it here.  We'll
    # include only what's specific to this provider.
    it "should raise an error if the required binary /usr/bin/gpasswd doesn't exist" do
      allow(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:exist?).with("/usr/bin/gpasswd").and_return(false)
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "shouldn't raise an error if the required binaries exist" do
      allow(File).to receive(:exist?).and_return(true)
      expect { @provider.process_resource_requirements }.not_to raise_error
    end
  end

  describe "after the group's current state is known" do
    before do
      @current_resource = @new_resource.dup
      @provider.current_resource = @new_resource
    end

    describe "when no group members are specified and append is not set" do
      before do
        @new_resource.append(false)
        @new_resource.members([])
      end

      it "logs a message and sets group's members to 'none'" do
        expect(logger).to receive(:debug).with("group[wheel] setting group members to: none")
        expect(@provider).to receive(:shell_out_compacted!).with("gpasswd", "-M", "", "wheel")
        @provider.modify_group_members
      end
    end

    describe "when no group members are specified and append is set" do
      before do
        @new_resource.append(true)
        @new_resource.members([])
      end

      it "does not modify group membership" do
        expect(@provider).not_to receive(:shell_out_compacted!)
        @provider.modify_group_members
      end
    end

    describe "when the resource specifies group members" do
      it "should log an appropriate debug message" do
        expect(logger).to receive(:debug).with("group[wheel] setting group members to: lobster, rage, fist")
        allow(@provider).to receive(:shell_out_compacted!)
        @provider.modify_group_members
      end

      it "should run gpasswd with the members joined by ',' followed by the target group" do
        expect(@provider).to receive(:shell_out_compacted!).with("gpasswd", "-M", "lobster,rage,fist", "wheel")
        @provider.modify_group_members
      end

      describe "when no user exists in the system" do
        before do
          current_resource = @new_resource.dup
          current_resource.members([ ])
          @provider.current_resource = current_resource
        end

        it "should run gpasswd individually for each user when the append option is set" do
          @new_resource.append(true)
          expect(@provider).to receive(:shell_out_compacted!).with("gpasswd", "-a", "lobster", "wheel")
          expect(@provider).to receive(:shell_out_compacted!).with("gpasswd", "-a", "rage", "wheel")
          expect(@provider).to receive(:shell_out_compacted!).with("gpasswd", "-a", "fist", "wheel")
          @provider.modify_group_members
        end
      end

    end
  end
end
