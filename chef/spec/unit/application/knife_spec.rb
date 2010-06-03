#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Application::Knife do
  before(:each) do
    @knife = Chef::Application::Knife.new
    @knife.stub!(:puts)
    Chef::Knife.stub!(:list_commands)
  end

  describe "run" do
    it "should exit 1 and print the options if no arguments are given at all" do
      with_argv([]) do
        lambda { @knife.run }.should raise_error(SystemExit) { |e| e.status.should == 1 }
      end
    end

    it "should exit 2 if run without a sub command" do
      with_argv("--user", "adam") do
        Chef::Log.should_receive(:fatal).with(/you need to pass a sub\-command/)
        lambda { @knife.run }.should raise_error(SystemExit) { |e| e.status.should == 2 }
      end
    end

    it "should run a sub command with the applications command line option prototype" do
      with_argv("node", "show", "latte.local") do
        knife = mock(Chef::Knife, :null_object => true)
        Chef::Knife.should_receive(:find_command).with(ARGV, Chef::Application::Knife.options).and_return(knife)
        @knife.should_receive(:exit).with(0)
        @knife.run
      end
    end
  end
end
