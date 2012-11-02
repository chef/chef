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

    context "when loading multiple roles" do
      before(:each) do
        @env_apple = @role.dup
        @env_apple.name("apple")
        @knife.loader.stub!(:load_from).with("apple.rb").and_return @env_apple
      end

      it "loads multiple roles if given" do
        @knife.name_args = [ "spec.rb", "apple.rb" ]
        @role.should_receive(:save).twice
        @knife.run
      end

      it "loads all roles with -a" do
        File.stub!(:expand_path).with("./roles/*.{json,rb}").and_return("/tmp/roles")
        Dir.stub!(:glob).with("/tmp/roles").and_return(["spec.rb", "apple.rb"])
        @knife.name_args = []
        @knife.stub!(:config).and_return({:all => true})
        @role.should_receive(:save).twice
        @knife.run
      end

      it "loads both files and directories with -a and an argument" do
        File.stub!(:expand_path).with("dir_town/*.{json,rb}").and_return("/tmp/roles")
        Dir.stub!(:glob).with("/tmp/roles").and_return(["spec.rb", "apple.rb"])
        File.stub!(:directory?).with("foo.rb").and_return(false)
        File.stub!(:directory?).with("dir_town").and_return(true)
        @knife.name_args = [ "foo.rb", "dir_town" ]
        @knife.stub!(:config).and_return({:all => true})
        @role.should_receive(:save).exactly(3).times # foo.rb, dir_town/spec.rb, dir_town/apple.rb
        @knife.run
      end

      it "prints an error if passed a directory without --all" do
        @knife.name_args = [ "foo.rb", "dir_town" ]
        File.stub!(:directory?).with("foo.rb").and_return(false)
        File.stub!(:directory?).with("dir_town").and_return(true)
        @knife.ui.should_receive(:error)
        @knife.run
      end
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
