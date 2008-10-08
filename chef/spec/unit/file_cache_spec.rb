#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

describe Chef::FileCache, "store method" do
  before(:each) do
    Chef::Config[:file_cache_path] = "/tmp/foo"
    Dir.stub!(:mkdir).and_return(true)
    File.stub!(:directory?).and_return(true)
    @io = mock("IO", { :print => true, :close => true })
    File.stub!(:open).and_return(@io)
  end
  
  it "should create the directories leading up to bang" do
    File.stub!(:directory?).and_return(false)
    Dir.should_receive(:mkdir).with("/tmp").and_return(true)
    Dir.should_receive(:mkdir).with("/tmp/foo").and_return(true)
    Dir.should_receive(:mkdir).with("/tmp/foo/whiz").and_return(true)
    Dir.should_not_receive(:mkdir).with("/tmp/foo/whiz/bang").and_return(true)
    Chef::FileCache.store("whiz/bang", "I found a poop")
  end
  
  it "should create a file at /tmp/foo/whiz/bang" do
    File.should_receive(:open).with("/tmp/foo/whiz/bang", "w").and_return(@io)
    Chef::FileCache.store("whiz/bang", "I found a poop")
  end
  
  it "should print the contents to the file" do
    @io.should_receive(:print).with("I found a poop")
    Chef::FileCache.store("whiz/bang", "I found a poop")
  end
  
  it "should close the file" do
    @io.should_receive(:close)
    Chef::FileCache.store("whiz/bang", "I found a poop")
  end

end

describe Chef::FileCache, "load method" do
  before(:each) do
    Chef::Config[:file_cache_path] = "/tmp/foo"
    Dir.stub!(:mkdir).and_return(true)
    File.stub!(:directory?).and_return(true)
    File.stub!(:exists?).and_return(true)
    File.stub!(:read).and_return("I found a poop")
  end
  
  it "should find the full path to whiz/bang" do
    File.should_receive(:read).with("/tmp/foo/whiz/bang").and_return(true)
    Chef::FileCache.load('whiz/bang')
  end
  
  it "should raise a Chef::Exception::FileNotFound if the file doesn't exist" do
    File.stub!(:exists?).and_return(false)
    lambda { Chef::FileCache.load('whiz/bang') }.should raise_error(Chef::Exception::FileNotFound)
  end
end
 
describe Chef::FileCache, "delete method" do
  before(:each) do
    Chef::Config[:file_cache_path] = "/tmp/foo"
    Dir.stub!(:mkdir).and_return(true)
    File.stub!(:directory?).and_return(true)
    File.stub!(:exists?).and_return(true)
    File.stub!(:unlink).and_return(true)
  end
  
  it "should unlink the full path to whiz/bang" do
    File.should_receive(:unlink).with("/tmp/foo/whiz/bang").and_return(true)
    Chef::FileCache.delete("whiz/bang")
  end
  
end

describe Chef::FileCache, "list method" do
  before(:each) do
    Chef::Config[:file_cache_path] = "/tmp/foo"
    Dir.stub!(:[]).and_return(["/tmp/foo/whiz/bang", "/tmp/foo/snappy/patter"])
    File.stub!(:file?).and_return(true)
  end
  
  it "should return the relative paths" do
    Chef::FileCache.list.should eql([ "whiz/bang", "snappy/patter" ])
  end
end

describe Chef::FileCache, "has_key? method" do
  before(:each) do
    Chef::Config[:file_cache_path] = "/tmp/foo"
  end
  
  it "should check the full path to the file" do
    File.should_receive(:exists?).with("/tmp/foo/whiz/bang")
    Chef::FileCache.has_key?("whiz/bang")
  end
  
  it "should return true if the file exists" do
    File.stub!(:exists?).and_return(true)
    Chef::FileCache.has_key?("whiz/bang").should eql(true)
  end
  
  it "should return false if the file does not exist" do
    File.stub!(:exists?).and_return(false)
    Chef::FileCache.has_key?("whiz/bang").should eql(false)
  end
end

