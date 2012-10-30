#
# Author:: Stephen Delano (<stephen@ospcode.com>)
# Author:: Seth Falcon (<seth@ospcode.com>)
# Copyright:: Copyright 2010 Opscode, Inc.
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

Chef::Knife::EnvironmentFromFile.load_deps

describe Chef::Knife::EnvironmentFromFile do
  before(:each) do
    @knife = Chef::Knife::EnvironmentFromFile.new
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.name_args = [ "spec.rb" ]

    @environment = Chef::Environment.new
    @environment.name("spec")
    @environment.description("runs the unit tests")
    @environment.cookbook_versions({"apt" => "= 1.2.3"})
    @environment.stub!(:save).and_return true
    @knife.loader.stub!(:load_from).and_return @environment
  end

  describe "run" do
    it "loads the environment data from a file and saves it" do
      @knife.loader.should_receive(:load_from).with('environments', 'spec.rb').and_return(@environment)
      @environment.should_receive(:save)
      @knife.run
    end

    context "when handling multiple environments" do
      before(:each) do
        @env_apple = @environment.dup
        @env_apple.name("apple")
        @knife.loader.stub!(:load_from).with("apple.rb").and_return @env_apple
      end
  
      it "loads multiple environments if given" do
        @knife.name_args = [ "spec.rb", "apple.rb" ]
        @environment.should_receive(:save).twice
        @knife.run
      end
  
      it "loads all environments with -a" do
        File.stub!(:expand_path).with("./environments/*.{json,rb}").and_return("/tmp/environments")
        Dir.stub!(:glob).with("/tmp/environments").and_return(["spec.rb", "apple.rb"])
        @knife.name_args = []
        @knife.stub!(:config).and_return({:all => true})
        @environment.should_receive(:save).twice
        @knife.run
      end
    end

    it "should not print the environment" do
      @knife.should_not_receive(:output)
      @knife.run
    end

    it "should show usage and exit if not filename is provided" do
      @knife.name_args = []
      @knife.ui.should_receive(:fatal)
      @knife.should_receive(:show_usage)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe "with --print-after" do
      it "should pretty print the environment, formatted for display" do
        @knife.config[:print_after] = true
        @knife.should_receive(:output)
        @knife.run
      end
    end
  end
end
