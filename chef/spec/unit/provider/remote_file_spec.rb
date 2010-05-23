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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::RemoteFile, "action_create" do
  before(:each) do
    pending("requires resolution of remote file by cw&&tim [DAN 5/23/2010]")
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.join(CHEF_SPEC_DATA, "templates", "seattle.txt"))
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
  
  describe "when checking if the file is at the target version" do
    it "considers the current file to be at the target version if it exists and matches the user-provided checksum" do
      @resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.current_resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
      @provider.current_resource_matches_target_checksum?.should be_true
    end
    
    it "considers the current file to be at the target version if it exists and matches the checksum of the downloaded source file" do
      @provider.load_current_resource
      File.open(CHEF_SPEC_DATA + '/templates/seattle.txt') do |f|
        @provider.matches_current_checksum?(f).should be_true
      end
    end
  end
end

describe Chef::Provider::RemoteFile, "do_remote_file" do
  before(:each) do
    pending("Requires resolution of remote file by cw && tim [DAN 5/23/2010]")
    @rest = mock(Chef::REST, { })
    @tempfile = Tempfile.new("chef-rspec-remote_file_spec-line#{__LINE__}")
    @rest.stub!(:fetch).and_yield(@tempfile)
    @resource = Chef::Resource::RemoteFile.new("seattle")
    @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "seattle.txt")))
    @resource.source("foo")
    @resource.cookbook_name = "monkey"
    @node = Chef::Node.new
    @node.name "latte"
    @node.fqdn "latte.local"
    @provider = Chef::Provider::RemoteFile.new(@node, @resource)
    @provider.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    @provider.current_resource = @resource.clone
    @provider.current_resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    File.stub!(:exists?).and_return(true)
    FileUtils.stub!(:cp).and_return(true)
    Chef::Platform.stub!(:find_platform_and_version).and_return([ :mac_os_x, "10.5.1" ])
  end

  after do
    @tempfile.close!
  end

  def do_remote_file
    Chef::REST.stub!(:new).and_return(@rest)
    @provider.do_remote_file(@resource.source, @resource.path)
  end
  
  context "when the source is an absolute URI" do
    before do
      @resource.source("http://opscode.com/seattle.txt")
    end

    describe "and the resource specifies a checksum" do

      it "should not download the file if the checksum matches" do
        @resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
        @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        do_remote_file
      end

      it "should not download the file if the checksum is a partial match from the beginning" do
        @resource.checksum("0fd012fd")
        @rest.should_not_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        do_remote_file
      end


      it "should download the file if the checksum does not match" do
        @resource.checksum("this hash doesn't match")
        @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        do_remote_file
      end

      it "should download the file if the checksum matches, but not from the beginning" do
        @resource.checksum("fd012fd")
        @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        do_remote_file
      end

    end

    describe "and the resource doesn't specify a checksum" do
      it "should download the file from the remote URL" do
        @resource.checksum(nil)
        @rest.should_receive(:fetch).with("http://opscode.com/seattle.txt").and_return(@tempfile)
        do_remote_file
      end
    end
  end

  describe "when the source is not an absolute URI" do
    describe "and using chef-solo" do
      it "should load the file from the local cookbook" do
        Chef::Config[:solo] = true
        File.stub!(:open).and_return(@tempfile)
        @provider.should_receive(:find_preferred_file).with("monkey", :remote_file, @resource.source, "latte.local", nil, nil).and_return(@tempfile.path)
        do_remote_file
      end

      after(:each) do
        Chef::Config[:solo] = false
      end
    end

    it "should call generate_url with the current checksum as an extra attribute" do
      @provider.should_receive(:generate_url).with(@resource.source, "files", { :checksum => "0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa"})
      do_remote_file
    end

    it "should call get_rest with a correctly composed url" do
      url = "cookbooks/#{@resource.cookbook_name}/files?id=#{@resource.source}"
      url += "&platform=mac_os_x"
      url += "&version=10.5.1"
      url += "&fqdn=latte.local"
      url += "&node_name=latte"
      url += "&checksum=0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa"
      @rest.should_receive(:fetch).with(url).and_yield(@tempfile)
      do_remote_file
    end
  end

  it "should not transfer the file if it has not been changed" do
    r = Net::HTTPNotModified.new("one", "two", "three")
    e = Net::HTTPRetriableError.new("304", r)
    @rest.stub!(:fetch).and_raise(e)
    do_remote_file.should eql(false)
  end

  it "should raise an exception if it's any other kind of retriable response than 304" do
    r = Net::HTTPMovedPermanently.new("one", "two", "three")
    e = Net::HTTPRetriableError.new("301", r)
    @rest.stub!(:fetch).and_raise(e)
    lambda { do_remote_file }.should raise_error(Net::HTTPRetriableError)
  end

  it "should raise an exception if anything else happens" do
    r = Net::HTTPBadRequest.new("one", "two", "three")
    e = Net::HTTPServerException.new("fake exception", r)
    @rest.stub!(:fetch).and_raise(e)
    lambda { do_remote_file }.should raise_error(Net::HTTPServerException)
  end

  it "should checksum the raw file" do
    @provider.should_receive(:checksum).with(@tempfile.path).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
    do_remote_file
  end

  describe "when the target file does not exist" do
    before do
      ::File.stub!(:exists?).with(@resource.path).and_return(false)
      @provider.stub!(:get_from_server).and_return(@tempfile)
    end

    it "should copy the raw file to the new resource" do
      FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
      do_remote_file
    end

    it "should set the new resource to updated" do
      @resource.should_receive(:updated=).with(true)
      do_remote_file
    end
  end

  describe "when the target file already exists" do
    before do
      ::File.stub!(:exists?).with(@resource.path).and_return(true)
      @provider.stub!(:get_from_server).and_return(@tempfile)
    end

    describe "and the checksum doesn't match" do
      before do
        @provider.
          current_resource.
          checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924ab")
      end

      it "should backup the original file" do
        @provider.should_receive(:backup).with(@resource.path).and_return(true)
        do_remote_file
      end

      it "should copy the raw file to the new resource" do
        FileUtils.should_receive(:cp).with(@tempfile.path, @resource.path).and_return(true)
        do_remote_file
      end

      it "should set the new resource to updated" do
        @resource.should_receive(:updated=).with(true)
        do_remote_file
      end
    end

    it "shouldn't backup the original file when it's the same" do
      @provider.should_not_receive(:backup).with(@resource.path).and_return(true)
      do_remote_file
    end
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

end
