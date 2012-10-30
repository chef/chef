#
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'spec_helper'
require 'etc'
require 'ostruct'

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
    Chef::FileAccessControl.any_instance.should_receive(:set_all)
    @provider.enforce_ownership_and_permissions
  end

  context "when nothing was updated" do
    before do
      Chef::FileAccessControl.any_instance.stub(:uid_from_resource).and_return(0)
      Chef::FileAccessControl.any_instance.stub(:requires_changes?).and_return(false)

      passwd_struct = if windows?
                        Struct::Passwd.new("root", "x", 0, 0, "/root", "/bin/bash")
                      else
                        Struct::Passwd.new("root", "x", 0, 0, "root", "/root", "/bin/bash")
                      end
      group_struct = OpenStruct.new(:name => "root", :passwd => "x", :gid => 0)
      Etc.stub!(:getpwuid).and_return(passwd_struct)
      Etc.stub!(:getgrgid).and_return(group_struct)
    end

    it "does not set updated_by_last_action on the new resource" do
      @provider.new_resource.should_not_receive(:updated_by_last_action)

      Chef::FileAccessControl.any_instance.stub(:set_all)
      @provider.run_action(:create)
    end

  end

  context "when something was modified" do
    before do
      Chef::FileAccessControl.any_instance.stub(:requires_changes?).and_return(true)
      Chef::FileAccessControl.any_instance.stub(:uid_from_resource).and_return(0)

      passwd_struct = if windows?
                        Struct::Passwd.new("root", "x", 0, 0, "/root", "/bin/bash")
                      else
                        Struct::Passwd.new("root", "x", 0, 0, "root", "/root", "/bin/bash")
                      end
      group_struct = OpenStruct.new(:name => "root", :passwd => "x", :gid => 0)
      Etc.stub!(:getpwuid).and_return(passwd_struct)
      Etc.stub!(:getgrgid).and_return(group_struct)
    end

    it "sets updated_by_last_action on the new resource" do
      @provider.new_resource.owner(0) # CHEF-3557 hack - Set these because we don't for windows
      @provider.new_resource.group(0) # CHEF-3557 hack - Set these because we don't for windows
      @provider.new_resource.should_receive(:updated_by_last_action)
      Chef::FileAccessControl.any_instance.stub(:set_all)
      @provider.run_action(:create)
    end
  end

end
