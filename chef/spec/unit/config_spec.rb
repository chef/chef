#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Config do
  
  it "should load a .rb file in context" do
    lambda { 
      Chef::Config.from_file(File.join(File.dirname(__FILE__), "..", "data", "config.rb"))
    }.should_not raise_error    
  end
  
  it "should raise an ArgumentError with an explanation if you try and set a non-existent variable" do
    lambda { 
      Chef::Config.from_file(File.join(File.dirname(__FILE__), "..", "data", "bad-config.rb")) 
    }.should raise_error(ArgumentError)
  end
  
  it "should raise an IOError if it can't find the file" do
    lambda { 
      Chef::Config.from_file("/tmp/timmytimmytimmy")
    }.should raise_error(IOError)
  end
  
  it "should have a default cookbook_path" do
    Chef::Config.cookbook_path.should be_kind_of(Array)
  end
  
  it "should allow you to set a cookbook_path with a string" do
    Chef::Config.cookbook_path("/etc/chef/cookbook")
    Chef::Config.cookbook_path.should eql("/etc/chef/cookbook")
  end
  
  it "should allow you to set a cookbook_path with multiple strings" do
    Chef::Config.cookbook_path("/etc/chef/cookbook", "/etc/chef/upstream-cookbooks")
    Chef::Config.cookbook_path.should eql([ 
      "/etc/chef/cookbook", 
      "/etc/chef/upstream-cookbooks" 
    ])
  end
  
  it "should allow you to set a cookbook_path with an array" do
    Chef::Config.cookbook_path ["one", "two"]
    Chef::Config.cookbook_path.should eql(["one", "two"])
  end
  
  it "should allow you to reference a value by index" do
    Chef::Config[:cookbook_path].should be_kind_of(Array)
  end
  
  it "should allow you to set a value by index" do
    Chef::Config[:cookbook_path] = "one"
    Chef::Config[:cookbook_path].should == "one"
  end
  
  it "should allow you to set config values with a block" do
    Chef::Config.configure do |c|
      c[:cookbook_path] = "monkey_rabbit"
      c[:otherthing] = "boo"
    end
    Chef::Config.cookbook_path.should == "monkey_rabbit"
    Chef::Config.otherthing.should == "boo"
  end
  
  it "should raise an ArgumentError if you access a config option that does not exist" do
    lambda { Chef::Config[:snob_hobbery] }.should raise_error(ArgumentError)
  end
  
  it "should return true or false with has_key?" do
    Chef::Config.has_key?(:monkey).should eql(false)
    Chef::Config[:monkey] = "gotcha"
    Chef::Config.has_key?(:monkey).should eql(true)
  end
  
end