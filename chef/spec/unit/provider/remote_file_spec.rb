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
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @resource.source("http://foo")
    @node = Chef::Node.new
    @node.name "latte"
    @provider = Chef::Provider::RemoteFile.new(@node, @resource)
    @provider.current_resource = @resource.clone
  end
  
  it "should call do_remote_file" do
    @provider.should_receive(:do_remote_file).with(@resource.source, @resource.path)
    @provider.action_create
  end
  
end

describe Chef::Provider::RemoteFile, "do_remote_file" do
  before(:each) do
    @rest = mock(Chef::REST, { })
    @tempfile = mock(Tempfile, { :path => "/tmp/foo", })
    @rest.stub!(:get_rest).and_return(@tempfile)
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.join(File.dirname(__FILE__), "..", "..", "data", "seattle.txt"))
    @resource.source("foo")
    @resource.cookbook_name = "monkey"
    @node = Chef::Node.new
    @node.name "latte"
    @node.fqdn "latte.local"
    @provider = Chef::Provider::RemoteFile.new(@node, @resource)
    @provider.stub!(:checksum).and_return("dad86c61eea237932f201009e5431609")
    @provider.current_resource = @resource.clone
    @provider.current_resource.checksum("dad86c61eea237932f201009e5431609")
    File.stub!(:exists?).and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    Chef::Platform.stub!(:find_platform_and_version).and_return([ :mac_os_x, "10.5.1" ])
  end
  
  def do_remote_file
    Chef::REST.stub!(:new).and_return(@rest)    
    @provider.do_remote_file(@resource.source, @resource.path)
  end
  
  it "should set the checksum if the file exists" do
    @provider.should_receive(:checksum).with(@resource.path)
    do_remote_file
  end
  
  it "should not set the checksum if the file doesn't exist" do
    File.stub!(:exists?).with(@resource.path).and_return(false)
    @provider.should_not_receive(:checksum).with(@resource.path)
    do_remote_file
  end
  
  it "should call generate_url with the current checksum as an extra attribute" do
    @provider.should_receive(:generate_url).with(@resource.source, "files", { :checksum => "dad86c61eea237932f201009e5431609"})
    do_remote_file
  end
  
  it "should call get_rest with a correctly composed url" do
    url = "cookbooks/#{@resource.cookbook_name}/files?id=#{@resource.source}"
    url += "&platform=mac_os_x"
    url += "&version=10.5.1"
    url += "&fqdn=latte.local"
    url += "&checksum=dad86c61eea237932f201009e5431609"
    @rest.should_receive(:get_rest).with(url, true).and_return(@tempfile)
    do_remote_file
  end
  
  it "should not transfer the file if it has not been changed" do
    r = Net::HTTPNotModified.new("one", "two", "three")
    e = Net::HTTPRetriableError.new("304", r)
    @rest.stub!(:get_rest).and_raise(e)
    do_remote_file.should eql(false)
  end
  
  it "should raise an exception if it's any other kind of retriable response than 304" do
    r = Net::HTTPMovedPermanently.new("one", "two", "three")
    e = Net::HTTPRetriableError.new("301", r)
    @rest.stub!(:get_rest).and_raise(e)
    lambda { do_remote_file }.should raise_error(Net::HTTPRetriableError)
  end
  
  it "should raise an exception if anything else happens" do
    r = Net::HTTPBadRequest.new("one", "two", "three")
    e = Net::HTTPServerException.new("fake exception", r)
    @rest.stub!(:get_rest).and_raise(e)
    lambda { do_remote_file }.should raise_error(Net::HTTPServerException)    
  end
  
  it "should checksum the raw file" do
    @provider.should_receive(:checksum).with(@tempfile.path).and_return("dad86c61eea237932f201009e5431608")
    do_remote_file
  end
  
  it "should backup the original file" do
    @provider.should_receive(:backup).with(@resource.path).and_return(true)
    do_remote_file
  end
  
  it "should set the new resource to updated" do
    @resource.should_receive(:updated=).with(true)    
    do_remote_file
  end
  
  it "should copy the raw file to the new resource" do
    FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)    
    do_remote_file
  end
  
  it "should set the owner if provided" do
    @resource.owner("adam")
    @provider.should_receive(:set_owner).and_return(true)
    do_remote_file
  end
  
  it "should set the group if provided" do
    @resource.group("adam")
    @provider.should_receive(:set_group).and_return(true)
    do_remote_file
  end
  
  it "should set the mode if provided" do
    @resource.mode(0676)
    @provider.should_receive(:set_mode).and_return(true)
    do_remote_file
  end
  
# TODO: Finish these tests

end
