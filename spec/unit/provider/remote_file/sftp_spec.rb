#
# Author:: John Kerry (<john@kerryhouse.net>)
# Copyright:: Copyright 2013-2016, John Kerry
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

describe Chef::Provider::RemoteFile::SFTP do
  #built out dependencies
  let(:enclosing_directory) do
    canonicalize_path(File.expand_path(File.join(CHEF_SPEC_DATA, "templates")))
  end
  let(:resource_path) do
    canonicalize_path(File.expand_path(File.join(enclosing_directory, "seattle.txt")))
  end

  let(:new_resource) do
    r = Chef::Resource::RemoteFile.new("remote file sftp backend test (new resource)")
    r.path(resource_path)
    r
  end

  let(:current_resource) do
    Chef::Resource::RemoteFile.new("remote file sftp backend test (current resource)'")
  end

  let(:uri) { URI.parse("sftp://conan:cthu1hu@opscode.com/seattle.txt") }

  let(:sftp) do
    sftp = double(Net::SFTP, {})
    allow(sftp).to receive(:download!)
    sftp
  end

  let(:tempfile_path) { "/tmp/somedir/remote-file-sftp-backend-spec-test" }

  let(:tempfile) do
    t = StringIO.new
    allow(t).to receive(:path).and_return(tempfile_path)
    t
  end

  before(:each) do
    allow(Net::SFTP).to receive(:start).with(any_args).and_return(sftp)
    allow(Tempfile).to receive(:new).and_return(tempfile)
  end
  describe "on initialization without user and password provided in the URI" do
    it "throws an argument exception with no userinfo is given" do
      uri.userinfo = nil
      uri.password = nil
      uri.user = nil
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception with no user name is given" do
      uri.userinfo = ":cthu1hu"
      uri.password = "cthu1hu"
      uri.user = nil
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception with no password is given" do
      uri.userinfo = "conan:"
      uri.password = nil
      uri.user = "conan"
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

  end

  describe "on initialization with user and password provided in the URI" do

    it "throws an argument exception when no path is given" do
      uri.path = ""
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception when only a / is given" do
      uri.path = "/"
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

    it "throws an argument exception when no filename is given" do
      uri.path = "/the/whole/path/"
      expect { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end

  end

  describe "when fetching the object" do

    let(:cache_control_data) { Chef::Provider::RemoteFile::CacheControlData.new(uri) }
    let(:current_resource_checksum) { "e2a8938cc31754f6c067b35aab1d0d4864272e9bf8504536ef3e79ebf8432305" }

    subject(:fetcher) { Chef::Provider::RemoteFile::SFTP.new(uri, new_resource, current_resource) }

    before do
      current_resource.checksum(current_resource_checksum)
    end

    it "should attempt to download a file from the provided url and path" do
      expect(sftp).to receive(:download!).with("/seattle.txt", "/tmp/somedir/remote-file-sftp-backend-spec-test")
      fetcher.fetch
    end

    context "and the URI specifies an alternate port" do
      let(:uri) { URI.parse("sftp://conan:cthu1hu@opscode.com:8021/seattle.txt") }

      it "should connect on an alternate port when one is provided" do
        expect(Net::SFTP).to receive(:start).with("opscode.com:8021", "conan", :password => "cthu1hu")
        fetcher.fetch
      end

    end

    context "and the uri specifies a nested path" do
      let(:uri) { URI.parse("sftp://conan:cthu1hu@opscode.com/the/whole/path/seattle.txt") }

      it "should fetch the file from the correct path" do
        expect(sftp).to receive(:download!).with("/the/whole/path/seattle.txt", "/tmp/somedir/remote-file-sftp-backend-spec-test")
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
  end
end
