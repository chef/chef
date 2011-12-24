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

require 'ostruct'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Directory do
  before(:each) do
    @new_resource = Chef::Resource::Directory.new('/tmp')
    @new_resource.owner(500)
    @new_resource.group(500)
    @new_resource.mode(0644)
    @node = Chef::Node.new
    @run_context = Chef::RunContext.new(@node, {})

    @directory = Chef::Provider::Directory.new(@new_resource, @run_context)
  end

  it "should load the current resource based on the new resource" do
    File.stub!(:exist?).and_return(true)
    File.should_receive(:directory?).once.and_return(true)
    cstats = mock("stats")
    cstats.stub!(:uid).and_return(500)
    cstats.stub!(:gid).and_return(500)
    cstats.stub!(:mode).and_return(0755)
    File.should_receive(:stat).once.and_return(cstats)
    @directory.load_current_resource
    @directory.current_resource.path.should eql(@new_resource.path)
    @directory.current_resource.owner.should eql(500)
    @directory.current_resource.group.should eql(500)
    @directory.current_resource.mode.should eql("755")
  end

  it "should create a new directory on create, setting updated to true" do
    load_mock_provider
    File.should_receive(:exists?).once.and_return(false)
    Dir.should_receive(:mkdir).with(@new_resource.path).once.and_return(true)
    @directory.should_receive(:enforce_ownership_and_permissions)
    @directory.action_create
    @directory.new_resource.should be_updated
  end

  it "should not create the directory if it already exists" do
    load_mock_provider
    File.should_receive(:exists?).once.and_return(true)
    Dir.should_not_receive(:mkdir).with(@new_resource.path)
    @directory.should_receive(:enforce_ownership_and_permissions)
    @directory.action_create
  end

  it "should delete the directory if it exists, and is writable with action_delete" do
    load_mock_provider
    File.should_receive(:directory?).once.and_return(true)
    File.should_receive(:writable?).once.and_return(true)
    Dir.should_receive(:delete).with(@new_resource.path).once.and_return(true)
    @directory.action_delete
  end

  it "should raise an exception if it cannot delete the file due to bad permissions" do
    load_mock_provider
    File.stub!(:exists?).and_return(true)
    File.stub!(:writable?).and_return(false)
    lambda { @directory.action_delete }.should raise_error(RuntimeError)
  end

  def load_mock_provider
    File.stub!(:exist?).and_return(true)
    File.stub!(:directory?).and_return(true)
    cstats = mock("stats")
    cstats.stub!(:uid).and_return(500)
    cstats.stub!(:gid).and_return(500)
    cstats.stub!(:mode).and_return(0755)
    File.stub!(:stat).once.and_return(cstats)
    @directory.load_current_resource
  end
end
