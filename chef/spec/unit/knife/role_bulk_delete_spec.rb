#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Knife::RoleBulkDelete do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::RoleBulkDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = ["."]
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.ui.stub!(:confirm).and_return(true)
    @roles = Hash.new
    %w{dev staging production}.each do |role_name|
      role = Chef::Role.new()
      role.name(role_name)
      role.stub!(:destroy).and_return(true)
      @roles[role_name] = role
    end
    Chef::Role.stub!(:list).and_return(@roles)
  end

  describe "run" do

    it "should get the list of the roles" do
      Chef::Role.should_receive(:list).and_return(@roles)
      @knife.run
    end

    it "should print the roles you are about to delete" do
      @knife.run
      @stdout.string.should match(/#{@knife.ui.list(@roles.keys.sort, :columns_down)}/)
    end

    it "should confirm you really want to delete them" do
      @knife.ui.should_receive(:confirm)
      @knife.run
    end

    it "should delete each role" do
      @roles.each_value do |r|
        r.should_receive(:destroy)
      end
      @knife.run
    end

    it "should only delete roles that match the regex" do
      @knife.name_args = ["dev"]
      @roles["dev"].should_receive(:destroy)
      @roles["staging"].should_not_receive(:destroy)
      @roles["production"].should_not_receive(:destroy)
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      lambda { @knife.run }.should raise_error(SystemExit)
    end

  end
end
