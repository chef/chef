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
require "uri"
require "addressable/uri"

describe Chef::Provider::RemoteFile::LocalFile do

  let(:uri) { URI.parse("file:///nyan_cat.png") }

  let(:new_resource) { Chef::Resource::RemoteFile.new("local file backend test (new_resource)") }
  let(:current_resource) { Chef::Resource::RemoteFile.new("local file backend test (current_resource)") }
  subject(:fetcher) { Chef::Provider::RemoteFile::LocalFile.new(uri, new_resource, current_resource) }

  context "when parsing source path on windows" do

    before do
      allow(Chef::Platform).to receive(:windows?).and_return(true)
    end

    describe "when given local unix path" do
      let(:uri) { URI.parse("file:///nyan_cat.png") }
      it "returns a correct unix path" do
        expect(fetcher.source_path).to eq("/nyan_cat.png")
      end
    end

    describe "when given local windows path" do
      let(:uri) { URI.parse("file:///z:/windows/path/file.txt") }
      it "returns a valid windows local path" do
        expect(fetcher.source_path).to eq("z:/windows/path/file.txt")
      end
    end

    describe "when given local windows path with spaces" do
      let(:uri) { URI.parse(Addressable::URI.encode("file:///z:/windows/path/foo & bar.txt")) }
      it "returns a valid windows local path" do
        expect(fetcher.source_path).to eq("z:/windows/path/foo & bar.txt")
      end
    end

    describe "when given unc windows path" do
      let(:uri) { URI.parse("file:////server/share/windows/path/file.txt") }
      it "returns a valid windows unc path" do
        expect(fetcher.source_path).to eq("//server/share/windows/path/file.txt")
      end
    end

    describe "when given unc windows path with spaces" do
      let(:uri) { URI.parse(Addressable::URI.encode("file:////server/share/windows/path/foo & bar.txt")) }
      it "returns a valid windows unc path" do
        expect(fetcher.source_path).to eq("//server/share/windows/path/foo & bar.txt")
      end
    end
  end

  context "when first created" do

    it "stores the uri it is passed" do
      expect(fetcher.uri).to eq(uri)
    end

    it "stores the new_resource" do
      expect(fetcher.new_resource).to eq(new_resource)
    end

  end

  describe "when fetching the object" do

    let(:tempfile) { double("Tempfile", :path => "/tmp/foo/bar/nyan.png", :close => nil) }
    let(:chef_tempfile) { double("Chef::FileContentManagement::Tempfile", :tempfile => tempfile) }

    before do
      current_resource.source("file:///nyan_cat.png")
    end

    it "stages the local file to a temporary file" do
      expect(Chef::FileContentManagement::Tempfile).to receive(:new).with(new_resource).and_return(chef_tempfile)
      expect(::FileUtils).to receive(:cp).with(uri.path, tempfile.path)
      expect(tempfile).to receive(:close)

      result = fetcher.fetch
      expect(result).to eq(tempfile)
    end

  end

end
