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

describe Chef::Provider::RemoteFile::FTP, "fetch" do
  before(:each) do
    @ftp = mock(Net::FTP, { })
    Net::FTP.stub!(:new).and_return(@ftp)
    @ftp.stub!(:connect)
    @ftp.stub!(:login)
    @ftp.stub!(:voidcmd)
    @ftp.stub!(:getbinaryfile)
    @ftp.stub!(:close)
    @ftp.stub!(:passive=)
    @tempfile = Tempfile.new("chef-rspec-ftp_spec-line#{__LINE__}--")
    Tempfile.stub!(:new).and_return(@tempfile)
    @uri = URI.parse("ftp://opscode.com/seattle.txt")
  end

  describe "when parsing the uri" do
    it "throws an argument exception when no path is given" do
      @uri.path = ""
      lambda { Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close! }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when only a / is given" do
      @uri.path = "/"
      lambda { Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close! }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when no filename is given" do
      @uri.path = "/the/whole/path/"
      lambda { Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close! }.should raise_error(ArgumentError)
    end

    it "throws an argument exception when the typecode is invalid" do
      @uri.typecode = "d"
      lambda { Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close! }.should raise_error(ArgumentError)
    end
  end

  describe "when connecting to the remote" do
    it "should connect to the host from the uri on the default port 21" do
      @ftp.should_receive(:connect).with("opscode.com", 21)
      Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close!
    end

    it "should connect on an alternate port when one is provided" do
      @ftp.should_receive(:connect).with("opscode.com", 8021)
      Chef::Provider::RemoteFile::FTP.fetch(URI.parse("ftp://opscode.com:8021/seattle.txt"), false).close!
    end

    it "should set passive true when ftp_active_mode is false" do
      @ftp.should_receive(:passive=).with(true)
      Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close!
    end

    it "should set passive false when ftp_active_mode is false" do
      @ftp.should_receive(:passive=).with(false)
      Chef::Provider::RemoteFile::FTP.fetch(@uri, true).close!
    end

    it "should use anonymous ftp when no userinfo is provided" do
      @ftp.should_receive(:login).with("anonymous", nil)
      Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close!
    end

    it "should use authenticated ftp when userinfo is provided" do
      @ftp.should_receive(:login).with("the_user", "the_password")
      Chef::Provider::RemoteFile::FTP.fetch(URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt"), false).close!
    end

    it "should accept ascii for the typecode" do
      @uri.typecode = "a"
      @ftp.should_receive(:voidcmd).with("TYPE A").once
      Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close!
    end

    it "should accept image for the typecode" do
      @uri.typecode = "i"
      @ftp.should_receive(:voidcmd).with("TYPE I").once
      Chef::Provider::RemoteFile::FTP.fetch(@uri, false).close!
    end

    it "should fetch the file from the correct path" do
      @ftp.should_receive(:voidcmd).with("CWD the").once
      @ftp.should_receive(:voidcmd).with("CWD whole").once
      @ftp.should_receive(:voidcmd).with("CWD path").once
      @ftp.should_receive(:getbinaryfile).with("seattle.txt", @tempfile.path)
      Chef::Provider::RemoteFile::FTP.fetch(URI.parse("ftp://opscode.com/the/whole/path/seattle.txt"), false).close!
    end
  end

  describe "when it finishes downloading" do
    it "should return a tempfile" do
      ftpfile = Chef::Provider::RemoteFile::FTP.fetch(@uri, false)
      ftpfile.should equal @tempfile
      ftpfile.close!
    end
  end
end
