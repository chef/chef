#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

describe Chef::Provider::RemoteFile::Fetcher do

  let(:current_resource) { double("current resource") }
  let(:new_resource) { double("new resource") }
  let(:fetcher_instance) { double("fetcher") }

  describe "when passed a network share" do
    before do
      expect(Chef::Provider::RemoteFile::NetworkFile).to receive(:new).and_return(fetcher_instance)
    end

    context "when host is a name" do
      let(:source) { "\\\\foohost\\fooshare\\Foo.tar.gz" }
      it "returns a network file fetcher" do
        expect(described_class.for_resource(source, new_resource, current_resource)).to eq(fetcher_instance)
      end
    end

    context "when host is an ip" do
      let(:source) { "\\\\127.0.0.1\\fooshare\\Foo.tar.gz" }
      it "returns a network file fetcher" do
        expect(described_class.for_resource(source, new_resource, current_resource)).to eq(fetcher_instance)
      end
    end
  end

  describe "when passed an http url" do
    let(:uri) { double("uri", :scheme => "http" ) }
    before do
      expect(Chef::Provider::RemoteFile::HTTP).to receive(:new).and_return(fetcher_instance)
    end
    it "returns an http fetcher" do
      expect(described_class.for_resource(uri, new_resource, current_resource)).to eq(fetcher_instance)
    end
  end

  describe "when passed an https url" do
    let(:uri) { double("uri", :scheme => "https" ) }
    before do
      expect(Chef::Provider::RemoteFile::HTTP).to receive(:new).and_return(fetcher_instance)
    end
    it "returns an http fetcher" do
      expect(described_class.for_resource(uri, new_resource, current_resource)).to eq(fetcher_instance)
    end
  end

  describe "when passed an ftp url" do
    let(:uri) { double("uri", :scheme => "ftp" ) }
    before do
      expect(Chef::Provider::RemoteFile::FTP).to receive(:new).and_return(fetcher_instance)
    end
    it "returns an ftp fetcher" do
      expect(described_class.for_resource(uri, new_resource, current_resource)).to eq(fetcher_instance)
    end
  end

  describe "when passed a file url" do
    let(:uri) { double("uri", :scheme => "file" ) }
    before do
      expect(Chef::Provider::RemoteFile::LocalFile).to receive(:new).and_return(fetcher_instance)
    end
    it "returns a localfile fetcher" do
      expect(described_class.for_resource(uri, new_resource, current_resource)).to eq(fetcher_instance)
    end
  end

  describe "when passed a url we do not recognize" do
    let(:uri) { double("uri", :scheme => "xyzzy" ) }
    it "throws an ArgumentError exception" do
      expect { described_class.for_resource(uri, new_resource, current_resource) }.to raise_error(ArgumentError)
    end
  end

end
