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

describe Chef::Provider::Group::Groupadd do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::Group.new("aj").tap do |r|
      r.gid 50
      r.members %w{root aj}
      r.system false
      r.non_unique false
    end
  end
  let(:current_resource) do
    Chef::Resource::Group.new("aj").tap do |r|
      r.gid 50
      r.members %w{root aj}
      r.system false
      r.non_unique false
    end
  end
  let(:provider) do
    described_class.new(new_resource, run_context).tap do |p|
      p.current_resource = current_resource
    end
  end

  describe "#set_options" do
    field_list = {
      gid: "-g",
    }

    field_list.each do |attribute, option|
      it "should check for differences in #{attribute} between the current and new resources" do
        expect(new_resource).to receive(attribute)
        expect(current_resource).to receive(attribute)
        provider.set_options
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
        allow(new_resource).to receive(attribute).and_return("wowaweea")
        expect(provider.set_options).to eql([ option, new_resource.send(attribute), new_resource.group_name])
      end
    end

    it "should combine all the possible options" do
      match_array = []
      field_list.sort { |a, b| a[0] <=> b[0] }.each do |attribute, option|
        allow(new_resource).to receive(attribute).and_return("hola")
        match_array << option
        match_array << "hola"
      end
      match_array << "aj"
      expect(provider.set_options).to eql(match_array)
    end

    describe "when we want to create a system group" do
      it "should not set groupadd_options '-r' when system is false" do
        new_resource.system(false)
        expect(provider.groupadd_options).to eq([])
      end

      it "should set groupadd -r if system is true" do
        new_resource.system(true)
        expect(provider.groupadd_options).to eq(["-r"])
      end

      context "on Solaris" do
        before { node.automatic["platform"] = "solaris2" }
        it "should not set groupadd -r if system is true" do
          new_resource.system(true)
          expect(provider.groupadd_options).to eql([])
        end
      end
    end

    describe "when we want to create a non_unique gid group" do
      it "should not set groupadd_options '-o' when non_unique is false" do
        new_resource.non_unique(false)
        expect(provider.groupadd_options).to eq([])
      end

      it "should set groupadd -o if non_unique is true" do
        new_resource.non_unique(true)
        expect(provider.groupadd_options).to eq(["-o"])
      end
    end
  end

  describe "#create_group" do
    before do
      allow(provider).to receive(:shell_out!).and_return(true)
      allow(provider).to receive(:set_options).and_return("monkey")
      allow(provider).to receive(:groupadd_options).and_return([])
      allow(provider).to receive(:modify_group_members).and_return(true)
    end

    it "should run groupadd with the return of set_options" do
      expect(provider).to receive(:shell_out!).with("groupadd", "monkey").and_return(true)
      provider.create_group
    end

    it "should modify the group members" do
      expect(provider).to receive(:modify_group_members).and_return(true)
      provider.create_group
    end
  end

  describe "#manage_group" do
    before do
      allow(provider).to receive(:shell_out!).and_return(true)
      allow(provider).to receive(:set_options).and_return("monkey")
    end

    it "should run groupmod with the return of set_options" do
      allow(provider).to receive(:modify_group_members).and_return(true)
      expect(provider).to receive(:shell_out!).with("groupmod", "monkey").and_return(true)
      provider.manage_group
    end

    it "should modify the group members" do
      expect(provider).to receive(:modify_group_members).and_return(true)
      provider.manage_group
    end
  end

  describe "#remove_group" do
    before do
      allow(provider).to receive(:shell_out!).and_return(true)
      allow(provider).to receive(:set_options).and_return("monkey")
    end

    it "should run groupdel with the new resources group name" do
      expect(provider).to receive(:shell_out!).with("groupdel", "aj").and_return(true)
      provider.remove_group
    end
  end

  [:add_member, :remove_member, :set_members].each do |m|
    it "should raise an error when calling #{m}" do
      expect { provider.send(m, [ ]) }.to raise_error(Chef::Exceptions::Group, "you must override #{m} in #{provider}")
    end
  end

  describe "#load_current_resource" do
    before do
      allow(provider).to receive(:shell_out!).and_return(true)
      allow(provider).to receive(:set_options).and_return("monkey")
    end

    before do
      allow(File).to receive(:exist?).and_return(false)
      provider.define_resource_requirements
    end

    it "should raise an error if the required binary /usr/sbin/groupadd doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/groupadd").and_return(false)
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "should raise an error if the required binary /usr/sbin/groupmod doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/groupadd").and_return(true)
      expect(File).to receive(:exist?).with("/usr/sbin/groupmod").and_return(false)
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "should raise an error if the required binary /usr/sbin/groupdel doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/groupadd").and_return(true)
      expect(File).to receive(:exist?).with("/usr/sbin/groupmod").and_return(true)
      expect(File).to receive(:exist?).with("/usr/sbin/groupdel").and_return(false)
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

  end
end
