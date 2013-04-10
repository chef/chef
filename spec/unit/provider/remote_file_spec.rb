#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright:: Copyright (c) 2008-2013 Opscode, Inc.
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

require 'support/shared/unit/provider/file'


describe Chef::Provider::RemoteFile do
  let(:resource) do
    resource = Chef::Resource::RemoteFile.new("seattle", @run_context)
    resource.path(resource_path)
    resource.source("http://foo")
    resource
  end

  before(:each) do
    ::File.stub!(:exists?).with("#{Chef::Config[:file_cache_path]}/remote_file/#{resource.name}").and_return(false)
  end

  let(:content) do
    content = mock('Chef::Provider::File::Content::RemoteFile')
  end

  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:enclosing_directory) { File.expand_path(File.join(CHEF_SPEC_DATA, "templates")) }
  let(:resource_path) { File.expand_path(File.join(enclosing_directory, "seattle.txt")) }

  # Subject

  let(:provider) do
    provider = described_class.new(resource, run_context)
    provider.stub!(:content).and_return(content)
    provider.stub!(:update_new_resource_checksum).and_return(nil) # XXX: otherwise it doesn't behave like a File provider
    provider
  end

  it_behaves_like Chef::Provider::File

#describe Chef::Provider::RemoteFile, "action_create" do
#  before(:each) do
#    @resource = Chef::Resource::RemoteFile.new("seattle")
#    @resource.path(File.expand_path(File.join(CHEF_SPEC_DATA, "seattle.txt")))
#    @resource.source("http://foo")
#    @node = Chef::Node.new
#    @node.name "latte"
#
#    @events = Chef::EventDispatch::Dispatcher.new
#    @run_context = Chef::RunContext.new(@node, {}, @events)
#
#    @provider = Chef::Provider::RemoteFile.new(@resource, @run_context)
#    #To prevent the current_resource.checksum from being overridden.
#    @provider.stub!(:load_current_resource)
#  end

#  describe "when fetching the file from the remote" do
#    before(:each) do
#      #@tempfile = Tempfile.new("chef-rspec-remote_file_spec-line#{__LINE__}--")
#
#      #@rest = mock(Chef::REST, { })
#      #Chef::REST.stub!(:new).and_return(@rest)
#      #@rest.stub!(:streaming_request).and_return(@tempfile)
#      #@rest.stub!(:last_response).and_return({})
#      resource.cookbook_name = "monkey"
#      resource.source("http://opscode.com/seattle.txt")
#
#      provider.stub!(:checksum).and_return("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
#      provider.current_resource = resource.clone
#      provider.current_resource.checksum("0fd012fdc96e96f8f7cf2046522a54aed0ce470224513e45da6bc1a17a4924aa")
#      #File.stub!(:exists?).and_return(true)
#      #FileUtils.stub!(:cp).and_return(true)
#      #Chef::Platform.stub!(:find_platform_and_version).and_return([ :mac_os_x, "10.5.1" ])
#      setup_normal_file
#    end
#
#    after do
#      #@tempfile.close!
#    end
#
#    # XXX: move to http
#
#    # CHEF-3140
#    # Some servers return tarballs as content type tar and encoding gzip, which
#    # is totally wrong. When this happens and gzip isn't disabled, Chef::REST
#    # will decompress the file for you, which is not at all what you expected
#    # to happen (you end up with an uncomressed tar archive instead of the
#    # gzipped tar archive you expected). To work around this behavior, we
#    # detect when users are fetching gzipped files and turn off gzip in
#    # Chef::REST.
#
#    context "and the source appears to be a tarball" do
#      before do
#        @resource.source("http://example.com/tarball.tgz")
#        Chef::REST.should_receive(:new).with(URI.parse("http://example.com/tarball.tgz"), nil, nil, :disable_gzip => true).and_return(@rest)
#      end
#
#      it "disables gzip in the http client" do
#        @provider.action_create
#      end
#    end
#
#    # XXX: move to file
#    context "and the uri scheme is file" do
#      before do
#        @resource.source("file:///nyan_cat.png")
#      end
#
#      it "should fetch the local file" do
#        Chef::Provider::RemoteFile::LocalFile.should_receive(:fetch).with(URI.parse("file:///nyan_cat.png"), nil).and_return(@tempfile)
#        @provider.run_action(:create)
#      end
#    end
#
#    # XXX: move to http
#    it "should raise an exception if it's any other kind of retriable response than 304" do
#      r = Net::HTTPMovedPermanently.new("one", "two", "three")
#      e = Net::HTTPRetriableError.new("301", r)
#      @rest.stub!(:streaming_request).and_raise(e)
#      lambda { @provider.run_action(:create) }.should raise_error(Net::HTTPRetriableError)
#    end
#
#    it "should raise an exception if anything else happens" do
#      r = Net::HTTPBadRequest.new("one", "two", "three")
#      e = Net::HTTPServerException.new("fake exception", r)
#      @rest.stub!(:streaming_request).and_raise(e)
#      lambda { @provider.run_action(:create) }.should raise_error(Net::HTTPServerException)
#    end
#
#  end
end
