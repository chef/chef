#
# Author:: Adam Edwards (<adamed@chef.io>)
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
require "uri"

describe Chef::Provider::RemoteFile::CacheControlData do

  before do
    @original_config = Chef::Config.hash_dup
  end

  after do
    Chef::Config.configuration = @original_config if @original_config
  end

  before(:each) do
    Chef::Config[:file_cache_path] = Dir.mktmpdir
  end

  after(:each) do
    FileUtils.rm_rf(Chef::Config[:file_cache_path])
  end

  let(:uri) { URI.parse("http://www.bing.com/robots.txt") }

  describe "when the cache control data save method is invoked" do

    subject(:cache_control_data) do
      Chef::Provider::RemoteFile::CacheControlData.load_and_validate(uri, file_checksum)
    end

    # the checksum of the file last we fetched it.
    let(:file_checksum) { "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" }

    let(:etag) { "\"a-strong-identifier\"" }
    let(:mtime) { "Thu, 01 Aug 2013 08:16:32 GMT" }

    before do
      cache_control_data.etag = etag
      cache_control_data.mtime = mtime
      cache_control_data.checksum = file_checksum
    end

    it "writes data to the cache" do
      cache_control_data.save
    end

    it "writes the data to the cache and the same data can be read back" do
      cache_control_data.save
      saved_cache_control_data = Chef::Provider::RemoteFile::CacheControlData.load_and_validate(uri, file_checksum)
      expect(saved_cache_control_data.etag).to eq(cache_control_data.etag)
      expect(saved_cache_control_data.mtime).to eq(cache_control_data.mtime)
      expect(saved_cache_control_data.checksum).to eq(cache_control_data.checksum)
    end

    # Cover the very long remote file path case -- see CHEF-4422 where
    # local cache file names generated from the long uri exceeded
    # local file system path limits resulting in exceptions from
    # file system API's on both Windows and Unix systems.
    context "when the length of the uri exceeds the path length limits for the local file system" do
      let(:uri_exceeds_file_system_limit) do
        URI.parse("http://www.bing.com/" + ("0" * 1024))
      end

      let(:uri) { uri_exceeds_file_system_limit }

      it "writes data to the cache" do
        expect do
          cache_control_data.save
        end.not_to raise_error
      end

      it "writes the data to the cache and the same data can be read back" do
        cache_control_data.save
        saved_cache_control_data = Chef::Provider::RemoteFile::CacheControlData.load_and_validate(uri, file_checksum)
        expect(saved_cache_control_data.etag).to eq(cache_control_data.etag)
        expect(saved_cache_control_data.mtime).to eq(cache_control_data.mtime)
        expect(saved_cache_control_data.checksum).to eq(cache_control_data.checksum)
      end

    end
  end

end
