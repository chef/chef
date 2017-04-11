#
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Provider::Group::Usermod do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.members %w{all your base}
    @new_resource.excluded_members [ ]
    @provider = Chef::Provider::Group::Usermod.new(@new_resource, @run_context)
    allow(@provider).to receive(:run_command)
  end

  describe "modify_group_members" do

    describe "with an empty members array" do
      before do
        @new_resource.append(true)
        @new_resource.members([])
      end

      it "should log an appropriate message" do
        expect(@provider).not_to receive(:shell_out!)
        @provider.modify_group_members
      end
    end

    describe "with supplied members" do
      platforms = {
        "openbsd" => [ "-G" ],
        "netbsd" => [ "-G" ],
        "solaris" => [ "-a", "-G" ],
        "suse" => [ "-a", "-G" ],
        "opensuse" => [ "-a", "-G" ],
        "smartos" => [ "-G" ],
        "omnios" => [ "-G" ],
      }

      before do
        @new_resource.members(%w{all your base})
        allow(File).to receive(:exist?).and_return(true)
      end

      it "should raise an error when setting the entire group directly" do
        @provider.define_resource_requirements
        @provider.load_current_resource
        @provider.instance_variable_set("@group_exists", true)
        @provider.action = :modify
        expect { @provider.run_action(@provider.process_resource_requirements) }.to raise_error(Chef::Exceptions::Group, "setting group members directly is not supported by #{@provider}, must set append true in group")
      end

      it "should raise an error when excluded_members are set" do
        @provider.define_resource_requirements
        @provider.load_current_resource
        @provider.instance_variable_set("@group_exists", true)
        @provider.action = :modify
        @new_resource.append(true)
        @new_resource.excluded_members(["someone"])
        expect { @provider.run_action(@provider.process_resource_requirements) }.to raise_error(Chef::Exceptions::Group, "excluded_members is not supported by #{@provider}")
      end

      platforms.each do |platform, flags|
        it "should usermod each user when the append option is set on #{platform}" do
          current_resource = @new_resource.dup
          current_resource.members([ ])
          @provider.current_resource = current_resource
          @node.automatic_attrs[:platform] = platform
          @new_resource.append(true)
          expect(@provider).to receive(:shell_out!).with("usermod", *flags, "wheel", "all")
          expect(@provider).to receive(:shell_out!).with("usermod", *flags, "wheel", "your")
          expect(@provider).to receive(:shell_out!).with("usermod", *flags, "wheel", "base")
          @provider.modify_group_members
        end
      end
    end
  end

  describe "when loading the current resource" do
    before(:each) do
      allow(File).to receive(:exist?).and_return(false)
      @provider.action = :create
      @provider.define_resource_requirements
    end

    it "should raise an error if the required binary /usr/sbin/usermod doesn't exist" do
      allow(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:exist?).with("/usr/sbin/usermod").and_return(false)
      expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "shouldn't raise an error if the required binaries exist" do
      allow(File).to receive(:exist?).and_return(true)
      expect { @provider.process_resource_requirements }.not_to raise_error
    end
  end
end
