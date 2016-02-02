#
# Author:: Mark Mzyk (<mmzyk@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
require "etc"
require "ostruct"

describe Chef::Mixin::EnforceOwnershipAndPermissions do

  before(:each) do
    @node = Chef::Node.new
    @node.name "make_believe"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @tmpdir = Dir.mktmpdir
    @resource = Chef::Resource::File.new("#{@tmpdir}/madeup.txt")
    FileUtils.touch @resource.path
    @resource.owner "adam"
    @provider = Chef::Provider::File.new(@resource, @run_context)
    @provider.current_resource = @resource
  end

  after(:each) do
    FileUtils.rm_rf(@tmpdir)
  end

  it "should call set_all on the file access control object" do
    expect_any_instance_of(Chef::FileAccessControl).to receive(:set_all)
    @provider.enforce_ownership_and_permissions
  end

  context "when nothing was updated" do
    before do
      allow_any_instance_of(Chef::FileAccessControl).to receive(:uid_from_resource).and_return(0)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:requires_changes?).and_return(false)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:define_resource_requirements)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:describe_changes)

      passwd_struct = OpenStruct.new(:name => "root", :passwd => "x",
                                     :uid => 0, :gid => 0, :dir => "/root",
                                     :shell => "/bin/bash")

      group_struct = OpenStruct.new(:name => "root", :passwd => "x", :gid => 0)
      allow(Etc).to receive(:getpwuid).and_return(passwd_struct)
      allow(Etc).to receive(:getgrgid).and_return(group_struct)
    end

    it "does not set updated_by_last_action on the new resource" do
      expect(@provider.new_resource).not_to receive(:updated_by_last_action)

      allow_any_instance_of(Chef::FileAccessControl).to receive(:set_all)
      @provider.run_action(:create)
    end

  end

  context "when something was modified" do
    before do
      allow_any_instance_of(Chef::FileAccessControl).to receive(:requires_changes?).and_return(true)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:uid_from_resource).and_return(0)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:describe_changes)

      passwd_struct = OpenStruct.new(:name => "root", :passwd => "x",
                                     :uid => 0, :gid => 0, :dir => "/root",
                                     :shell => "/bin/bash")

      group_struct = OpenStruct.new(:name => "root", :passwd => "x", :gid => 0)
      allow(Etc).to receive(:getpwuid).and_return(passwd_struct)
      allow(Etc).to receive(:getgrgid).and_return(group_struct)
    end

    it "sets updated_by_last_action on the new resource" do
      @provider.new_resource.owner(0) # CHEF-3557 hack - Set these because we don't for windows
      @provider.new_resource.group(0) # CHEF-3557 hack - Set these because we don't for windows
      expect(@provider.new_resource).to receive(:updated_by_last_action)
      allow_any_instance_of(Chef::FileAccessControl).to receive(:set_all)
      @provider.run_action(:create)
    end
  end

end
