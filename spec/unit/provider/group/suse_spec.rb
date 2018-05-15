#
# Author:: Tom Duffield (<tom@chef.io>)
# Copyright:: Copyright 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Provider::Group::Suse do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_members) { %w{root new_user} }
  let(:new_resource) do
    Chef::Resource::Group.new("new_group").tap do |r|
      r.gid 50
      r.members new_members
      r.system false
      r.non_unique false
    end
  end
  let(:current_resource) do
    Chef::Resource::Group.new("new_group").tap do |r|
      r.gid 50
      r.members %w{root}
      r.system false
      r.non_unique false
    end
  end
  let(:provider) do
    described_class.new(new_resource, run_context).tap do |p|
      p.current_resource = current_resource
    end
  end

  describe "when determining the current group state" do
    before(:each) do
      allow(File).to receive(:exist?).and_return(true)
      provider.action = :create
      provider.define_resource_requirements
    end

    # Checking for required binaries is already done in the spec
    # for Chef::Provider::Group - no need to repeat it here.  We'll
    # include only what's specific to this provider.
    it "should raise an error if the required binary /usr/sbin/groupmod doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/groupmod").and_return(false)
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end

    it "should raise error if one of the member users does not exist" do
      expect(Etc).to receive(:getpwnam).with("new_user").and_raise ArgumentError
      expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Group)
    end
  end

  describe "#set_members" do
    it "should add missing members and remove deleted members" do
      expect(provider).not_to receive(:remove_member)
      expect(provider).to receive(:add_member).with("new_user")
      provider.set_members(new_members)
    end
  end

  describe "#add_member" do
    it "should call out to groupmod to add user" do
      expect(provider).to receive(:shell_out!).with("groupmod", "-A", "new_user", "new_group")
      provider.add_member("new_user")
    end
  end

  describe "#remove_member" do
    it "should call out to groupmod to remove user" do
      expect(provider).to receive(:shell_out!).with("groupmod", "-R", "new_user", "new_group")
      provider.remove_member("new_user")
    end
  end
end
