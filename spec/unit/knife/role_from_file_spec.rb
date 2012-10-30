#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

Chef::Knife::RoleFromFile.load_deps

describe Chef::Knife::RoleFromFile do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::RoleFromFile.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = [ "adam.rb" ]
    @knife.stub!(:output).and_return(true)
    @knife.stub!(:confirm).and_return(true)
    @role = Chef::Role.new()
    @role.stub!(:save)
    @knife.loader.stub!(:load_from).and_return(@role)
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should load from a file" do
      @knife.loader.should_receive(:load_from).with('roles', 'adam.rb').and_return(@role)
      @knife.run
    end

    it "should not print the role" do
      @knife.should_not_receive(:output)
      @knife.run
    end

    describe "with -p or --print-after" do
      it "should print the role" do
        @knife.config[:print_after] = true
        @knife.should_receive(:output)
        @knife.run
      end
    end
  end

  describe "run with multiple arguments" do
    it "should load each file" do
      @knife.name_args = [ "adam.rb", "caleb.rb" ]
      @knife.loader.should_receive(:load_from).with('roles', 'adam.rb').and_return(@role)
      @knife.loader.should_receive(:load_from).with('roles', 'caleb.rb').and_return(@role)
      @knife.run
    end
  end

end
