#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::CookbookUploader do

  let(:http_client) { double("Chef::ServerAPI") }

  let(:cookbook_loader) do
    loader = Chef::CookbookLoader.new(File.join(CHEF_SPEC_DATA, "cookbooks"))
    loader.load_cookbooks
    loader.cookbooks_by_name["apache2"].identifier = apache2_identifier
    loader.cookbooks_by_name["java"].identifier = java_identifier
    loader
  end

  let(:apache2_identifier) { "6644e6cb2ade90b8aff2ebb44728958fbc939ebf" }

  let(:apache2_cookbook) { cookbook_loader.cookbooks_by_name["apache2"] }

  let(:java_identifier) { "edd40c30c4e0ebb3658abde4620597597d2e9c17" }

  let(:java_cookbook) { cookbook_loader.cookbooks_by_name["java"] }

  let(:cookbooks_to_upload) { [apache2_cookbook, java_cookbook] }

  let(:checksums_of_cookbook_files) { apache2_cookbook.checksums.merge(java_cookbook.checksums) }

  let(:checksums_set) do
    checksums_of_cookbook_files.keys.inject({}) do |set, cksum|
      set[cksum] = nil
      set
    end
  end

  let(:sandbox_commit_uri) { "https://chef.example.org/sandboxes/abc123" }

  let(:policy_mode) { false }

  let(:uploader) { described_class.new(cookbooks_to_upload, rest: http_client, policy_mode: policy_mode) }

  it "defaults to not enabling policy mode" do
    expect(described_class.new(cookbooks_to_upload, rest: http_client).policy_mode?).to be(false)
  end

  it "has a list of cookbooks to upload" do
    expect(uploader.cookbooks).to eq(cookbooks_to_upload)
  end

  it "creates an HTTP client with default configuration when not initialized with one" do
    default_http_client = double("Chef::ServerAPI")
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], version_class: Chef::CookbookManifestVersions).and_return(default_http_client)
    uploader = described_class.new(cookbooks_to_upload)
    expect(uploader.rest).to eq(default_http_client)
  end

  describe "uploading cookbooks" do

    def url_for(cksum)
      "https://storage.example.com/#{cksum}"
    end

    let(:sandbox_response) do
      sandbox_checksums = cksums_not_on_remote.inject({}) do |cksum_map, cksum|
        cksum_map[cksum] = { "needs_upload" => true, "url" => url_for(cksum) }
        cksum_map
      end
      { "checksums" => sandbox_checksums, "uri" => sandbox_commit_uri }
    end

    def expect_sandbox_create
      expect(http_client).to receive(:post).
        with("sandboxes", { :checksums => checksums_set }).
        and_return(sandbox_response)
    end

    def expect_checksum_upload
      checksums_of_cookbook_files.each do |md5, file_path|
        next unless cksums_not_on_remote.include?(md5)

        upload_headers = {
          "content-type" => "application/x-binary",
          "content-md5"  => an_instance_of(String),
          "accept"       => "application/json",
        }

        expect(http_client).to receive(:put).
          with(url_for(md5), IO.binread(file_path), upload_headers)

      end
    end

    def expected_save_url(cookbook)
      "cookbooks/#{cookbook.name}/#{cookbook.version}"
    end

    def expect_sandbox_commit
      expect(http_client).to receive(:put).with(sandbox_commit_uri, { :is_completed => true })
    end

    def expect_cookbook_create
      cookbooks_to_upload.each do |cookbook|

        expect(http_client).to receive(:put).
          with(expected_save_url(cookbook), cookbook)

      end
    end

    context "when no files exist on the server" do

      let(:cksums_not_on_remote) do
        checksums_of_cookbook_files.keys
      end

      it "uploads all files in a sandbox transaction, then creates cookbooks on the server" do
        expect_sandbox_create
        expect_checksum_upload
        expect_sandbox_commit
        expect_cookbook_create

        uploader.upload_cookbooks
      end

    end

    context "when some files exist on the server" do

      let(:cksums_not_on_remote) do
        checksums_of_cookbook_files.keys[0, 1]
      end

      it "uploads all files in a sandbox transaction, then creates cookbooks on the server" do
        expect_sandbox_create
        expect_checksum_upload
        expect_sandbox_commit
        expect_cookbook_create

        uploader.upload_cookbooks
      end

    end

    context "when all files already exist on the server" do

      let(:cksums_not_on_remote) { [] }

      it "uploads all files in a sandbox transaction, then creates cookbooks on the server" do
        expect_sandbox_create
        expect_checksum_upload
        expect_sandbox_commit
        expect_cookbook_create

        uploader.upload_cookbooks
      end

    end

    context "when policy_mode is specified" do

      let(:cksums_not_on_remote) do
        checksums_of_cookbook_files.keys
      end

      let(:policy_mode) { true }

      def expected_save_url(cookbook)
        "cookbook_artifacts/#{cookbook.name}/#{cookbook.identifier}"
      end

      it "uploads all files in a sandbox transaction, then creates cookbooks on the server using cookbook_artifacts API" do
        expect_sandbox_create
        expect_checksum_upload
        expect_sandbox_commit
        expect_cookbook_create

        uploader.upload_cookbooks
      end

    end
  end

end
