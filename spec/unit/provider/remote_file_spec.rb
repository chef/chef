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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::RemoteFile, "action_create" do
  before(:each) do
    @rest = mock(Chef::REST, { })
    @tempfile = mock(Tempfile, { :path => "/tmp/foo", })
    @rest.stub!(:get_rest).and_return(@tempfile)
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @resource.source("http://foo")
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::RemoteFile.new(@node, @resource)
    @provider.stub!(:checksum).and_return("dad86c61eea237932f201009e5431609")
    @provider.current_resource = @resource.clone
    @provider.current_resource.checksum("dad86c61eea237932f201009e5431609")
    File.stub!(:exists?).and_return(true)
    FileUtils.stub!(:cp).and_return(true)
  end
  
  def do_action_create
    Chef::REST.stub!(:new).and_return(@rest)    
    @provider.action_create
  end
  
  it "should set the checksum if the file exists" do
    @provider.should_receive(:checksum).with(@resource.path)
    do_action_create
  end
  
  it "should not set the checksum if the file doesn't exist" do
    File.stub!(:exists?).with(@resource.path).and_return(false)
    @provider.should_not_receive(:checksum).with(@resource.path)
    do_action_create
  end
  
  it "should call generate_url with the current checksum as an extra attribute" do
    @provider.should_receive(:generate_url).with(@resource.source, "files", { :checksum => "dad86c61eea237932f201009e5431609"})
    do_action_create
  end

# TODO: Finish these tests

end
