#
# Author:: Joshua Justice (<jjustice6@bloomberg.net>)
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

describe Chef::Provider::Group::Solaris do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Group.new("wheel")
    @new_resource.members %w{all your base}
    @new_resource.excluded_members [ ]
    @provider = Chef::Provider::Group::Solaris.new(@new_resource, @run_context)
    allow(@provider).to receive(:run_command)
  end

  describe "modify_group_members" do

    describe "with an empty members array" do
      before do
        @new_resource.append(true)
        @new_resource.members([])
      end

      it "should log an appropriate message" do
        expect(@provider).not_to receive(:shell_out_compacted!)
        @provider.modify_group_members
      end
    end

    describe "with supplied members" do
      platforms = {
        "solaris2" => [ "-G" ],
      }

      before do
        @new_resource.members(%w{all your base})
        allow(File).to receive(:exist?).and_return(true)
      end

      it "should groupmod the whole batch when append is false" do
        current_resource = @new_resource.dup
        @provider.current_resource = current_resource
        @node.automatic_attrs[:platform] = "solaris2"
        @new_resource.append(false)
        expect(@provider).to receive(:shell_out_compacted!).with("groupmod", "-U", "all,your,base", "wheel")
        @provider.modify_group_members
      end

      platforms.each do |platform, flags|
        it "should usermod +/- each user when the append option is set on #{platform}" do
          current_resource = @new_resource.dup
          current_resource.members(%w{are belong to us})
          @new_resource.excluded_members(%w{are belong to us})
          @provider.current_resource = current_resource
          @node.automatic_attrs[:platform] = platform
          @new_resource.append(true)
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "+wheel", "all")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "+wheel", "your")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "+wheel", "base")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "-wheel", "are")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "-wheel", "belong")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "-wheel", "to")
          expect(@provider).to receive(:shell_out_compacted!).with("usermod", *flags, "-wheel", "us")
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
