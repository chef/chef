#
# Author:: Jesse Campbell (<hikeit@gmail.com>)
# Copyright:: Copyright 2013-2016, Jesse Campbell
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

require "spec_helper"

describe Chef::Provider::RemoteFile::FTP do
  let(:enclosing_directory) do
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  end
  let(:resource_path) do
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  end

  let(:new_resource) do
    r = Chef::Resource::RemoteFile.new("remote file ftp backend test (new resource)")
    r.ftp_active_mode(false)
    r.path(resource_path)
    r
  end

  let(:current_resource) do
    Chef::Resource::RemoteFile.new("remote file ftp backend test (current resource)'")
  end

  let(:ftp) do
    ftp = double(Net::FTP, {})
    allow(ftp).to receive(:connect)
    allow(ftp).to receive(:login)
    allow(ftp).to receive(:voidcmd)
    allow(ftp).to receive(:mtime).and_return(Time.now)
    allow(ftp).to receive(:getbinaryfile)
    allow(ftp).to receive(:close)
    allow(ftp).to receive(:passive=)
    ftp
  end

  let(:tempfile_path) { "/tmp/somedir/remote-file-ftp-backend-spec-test" }

  let(:tempfile) do
    t = StringIO.new
    allow(t).to receive(:path).and_return(tempfile_path)
    t
  end

  let(:uri) { URI.parse("ftp://opscode.com/seattle.txt") }

  before(:each) do
    allow(Net::FTP).to receive(:new).with(no_args).and_return(ftp)
    allow(Tempfile).to receive(:new).and_return(tempfile)
  end

  describe "when first created" do

    it "throws an argument exception when no path is given" do
      uri.path = ""
      expect { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception when only a / is given" do
      uri.path = "/"
      expect { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception when no filename is given" do
      uri.path = "/the/whole/path/"
      expect { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception when the typecode is invalid" do
      uri.typecode = "d"
      expect { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "does not use passive mode when new_resource sets ftp_active_mode to true" do
      new_resource.ftp_active_mode(true)
      fetcher = Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource)
      expect(fetcher.use_passive_mode?).to be_falsey
    end

    it "uses passive mode when new_resource sets ftp_active_mode to false" do
      new_resource.ftp_active_mode(false)
      fetcher = Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource)
      expect(fetcher.use_passive_mode?).to be_truthy
    end
  end

  describe "when fetching the object" do

    let(:cache_control_data) { Chef::Provider::RemoteFile::CacheControlData.new(uri) }
    let(:current_resource_checksum) { "e2a8938cc31754f6c067b35aab1d0d4864272e9bf8504536ef3e79ebf8432305" }

    subject(:fetcher) { Chef::Provider::RemoteFile::FTP.new(uri, new_resource, current_resource) }

    before do
      current_resource.checksum(current_resource_checksum)
      #Chef::Provider::RemoteFile::CacheControlData.should_receive(:load_and_validate).with(uri, current_resource_checksum).and_return(cache_control_data)
    end

    it "should connect to the host from the uri on the default port 21" do
      expect(ftp).to receive(:connect).with("opscode.com", 21)
      fetcher.fetch
    end

    it "should set passive true when ftp_active_mode is false" do
      new_resource.ftp_active_mode(false)
      expect(ftp).to receive(:passive=).with(true)
      fetcher.fetch
    end

    it "should set passive false when ftp_active_mode is false" do
      new_resource.ftp_active_mode(true)
      expect(ftp).to receive(:passive=).with(false)
      fetcher.fetch
    end

    it "should use anonymous ftp when no userinfo is provided" do
      expect(ftp).to receive(:login).with("anonymous", nil)
      fetcher.fetch
    end

    context "and the URI specifies an alternate port" do
      let(:uri) { URI.parse("ftp://opscode.com:8021/seattle.txt") }

      it "should connect on an alternate port when one is provided" do
        uri = URI.parse("ftp://opscode.com:8021/seattle.txt")
        expect(ftp).to receive(:connect).with("opscode.com", 8021)
        fetcher.fetch
      end

    end

    context "and the URI contains a username and password" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt") }

      it "should use authenticated ftp when userinfo is provided" do
        expect(ftp).to receive(:login).with("the_user", "the_password")
        fetcher.fetch
      end
    end

    context "and the uri sets the typecode to ascii" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt;type=a") }

      it "fetches the file with ascii typecode set" do
        expect(ftp).to receive(:voidcmd).with("TYPE A").once
        fetcher.fetch
      end

    end

    context "and the uri sets the typecode to image" do
      let(:uri) { URI.parse("ftp://the_user:the_password@opscode.com/seattle.txt;type=i") }

      it "should accept image for the typecode" do
        expect(ftp).to receive(:voidcmd).with("TYPE I").once
        fetcher.fetch
      end

    end

    context "and the uri specifies a nested path" do
      let(:uri) { URI.parse("ftp://opscode.com/the/whole/path/seattle.txt") }

      it "should fetch the file from the correct path" do
        expect(ftp).to receive(:voidcmd).with("CWD the").once
        expect(ftp).to receive(:voidcmd).with("CWD whole").once
        expect(ftp).to receive(:voidcmd).with("CWD path").once
        expect(ftp).to receive(:getbinaryfile).with("seattle.txt", tempfile.path)
        fetcher.fetch
      end

    end

    context "when not using last modified based conditional fetching" do
      before do
        new_resource.use_last_modified(false)
      end

      it "should return a tempfile in the result" do
        result = fetcher.fetch
        expect(result).to equal(tempfile)
      end

    end

    context "and proxying is enabled" do
      before do
        stub_const("ENV", "ftp_proxy" => "socks5://bill:ted@socks.example.com:5000")
      end

      it "fetches the file via the proxy" do
        current_socks_server = ENV["SOCKS_SERVER"]
        expect(ENV).to receive(:[]=).with("SOCKS_SERVER", "socks5://bill:ted@socks.example.com:5000").ordered
        expect(ENV).to receive(:[]=).with("SOCKS_SERVER", current_socks_server).ordered
        result = fetcher.fetch
        expect(result).to equal(tempfile)
      end

    end

  end
end
