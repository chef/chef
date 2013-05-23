#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright (c) 2013 Jesse Campbell
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

describe Chef::Provider::RemoteFile::FTP do
  let(:enclosing_directory) {
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  }
  let(:resource_path) {
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  }

  let(:new_resource) { mock('Chef::Resource::RemoteFile (new resource)', :ftp_active_mode => false, :path => resource_path, :name => "seattle.txt", :binmode => true) }
  let(:current_resource) {  mock('Chef::Resource::RemoteFile (current resource)', :source => nil) }

  let(:ftp) do
    ftp = mock(Net::FTP, { })
    ftp.stub!(:connect)
    ftp.stub!(:login)
    ftp.stub!(:voidcmd)
    ftp.stub!(:mtime).and_return(Time.now)
    ftp.stub!(:getbinaryfile)
    ftp.stub!(:close)
    ftp.stub!(:passive=)
    ftp
  end

  let(:tempfile_path) { "/tmp/somedir/remote-file-ftp-backend-spec-test" }

  let(:tempfile) do
    t = StringIO.new
    t.stub(:path).and_return(tempfile_path)
    t
  end

  let(:uri) { URI.parse("ftp://opscode.com/seattle.txt") }

  before(:each) do
    Net::FTP.stub!(:new).and_return(ftp)
    Tempfile.stub!(:new).and_return(tempfile)

  end

  describe "when constructing the object" do

    it "throws an argument exception when no path is given" do
      uri.path = ""
      lambda { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when only a / is given" do
      uri.path = "/"
      lambda { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when no filename is given" do
      uri.path = "/the/whole/path/"
      lambda { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when the typecode is invalid" do
      uri.typecode = "d"
      lambda { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.should raise_error(ArgumentError)
    end

    it "sets ftp_active_mode to true when new_resource sets ftp_active_mode" do
      new_resource.stub!(:ftp_active_mode).and_return(true)
      fetcher = Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource)
      fetcher.ftp_active_mode.should == true
    end

    it "sets ftp_active_mode to false when new_resource does not set ftp_active_mode" do
      new_resource.stub!(:ftp_active_mode).and_return(false)
      fetcher = Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource)
      fetcher.ftp_active_mode.should == false
    end
  end

  describe "when fetching the object" do

    let(:fetcher) { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }

    it "should connect to the host from the uri on the default port 21" do
      ftp.should_receive(:connect).with("opscode.com", 21)
      fetcher.fetch
    end

    it "should set passive true when ftp_active_mode is false" do
      new_resource.should_receive(:ftp_active_mode).and_return(false)
      ftp.should_receive(:passive=).with(true)
      fetcher.fetch
    end

    it "should set passive false when ftp_active_mode is false" do
      new_resource.should_receive(:ftp_active_mode).and_return(true)
      ftp.should_receive(:passive=).with(false)
      fetcher.fetch
    end

    it "should use anonymous ftp when no userinfo is provided" do
      ftp.should_receive(:login).with("anonymous", nil)
      fetcher.fetch
    end

    context "and the URI specifies an alternate port" do
      let(:uri) { URI.parse("ftp://opscode.com:8021/seattle.txt") }

      it "should connect on an alternate port when one is provided" do
        uri = URI.parse("ftp://opscode.com:8021/seattle.txt")
        ftp.should_receive(:connect).with("opscode.com", 8021)
        fetcher.fetch
      end

    end

    context "and the URI contains a username and password" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt") }

      it "should use authenticated ftp when userinfo is provided" do
        ftp.should_receive(:login).with("the_user", "the_password")
        fetcher.fetch
      end
    end

    context "and the uri sets the typecode to ascii" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt;type=a") }

      it "fetches the file with ascii typecode set" do
        ftp.should_receive(:voidcmd).with("TYPE A").once
        fetcher.fetch
      end

    end

    context "and the uri sets the typecode to image" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt;type=i") }

      it "should accept image for the typecode" do
        ftp.should_receive(:voidcmd).with("TYPE I").once
        fetcher.fetch
      end

    end

    context "and the uri specifies a nested path" do
      let(:uri) { URI.parse("ftp://opscode.com/the/whole/path/seattle.txt") }

      it "should fetch the file from the correct path" do
        ftp.should_receive(:voidcmd).with("CWD the").once
        ftp.should_receive(:voidcmd).with("CWD whole").once
        ftp.should_receive(:voidcmd).with("CWD path").once
        ftp.should_receive(:getbinaryfile).with("seattle.txt", tempfile.path)
        fetcher.fetch
      end

    end


    it "should return a tempfile in the result" do
      result = fetcher.fetch
      result.raw_file.should equal(tempfile)
    end

  end
end
