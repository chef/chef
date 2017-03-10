#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
require "tiny_server"
require "support/shared/functional/http"

describe Chef::Resource::RemoteFile do
  include ChefHTTPShared

  let(:file_cache_path) { Dir.mktmpdir }

  before(:each) do
    @old_file_cache = Chef::Config[:file_cache_path]
    Chef::Config[:file_cache_path] = file_cache_path
  end

  after(:each) do
    Chef::Config[:file_cache_path] = @old_file_cache
    FileUtils.rm_rf(file_cache_path)
  end

  include_context Chef::Resource::File

  let(:file_base) { "remote_file_spec" }

  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::RemoteFile.new(path, run_context)
    resource.source(source)
    resource
  end

  let(:resource) do
    create_resource
  end

  let(:default_mode) { (0666 & ~File.umask).to_s(8) }

  context "when fetching files over HTTP" do
    before(:each) do
      start_tiny_server
    end

    after(:each) do
      stop_tiny_server
    end

    describe "when redownload isn't necessary" do
      let(:source) { "http://localhost:9000/seattle_capo.png" }

      before do
        @api.get("/seattle_capo.png", 304, "", { "Etag" => "abcdef" } )
      end

      it "does not fetch the file" do
        resource.run_action(:create)
      end
    end

    context "when using normal encoding" do
      let(:source) { "http://localhost:9000/nyan_cat.png" }
      let(:expected_content) { binread(nyan_uncompressed_filename) }

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

    context "when using gzip encoding" do
      let(:source) { "http://localhost:9000/nyan_cat.png.gz" }
      let(:expected_content) { binread(nyan_compressed_filename) }

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

  end

  context "when fetching files over HTTPS" do

    before(:each) do
      cert_text = File.read(File.expand_path("ssl/chef-rspec.cert", CHEF_SPEC_DATA))
      cert = OpenSSL::X509::Certificate.new(cert_text)
      key_text = File.read(File.expand_path("ssl/chef-rspec.key", CHEF_SPEC_DATA))
      key = OpenSSL::PKey::RSA.new(key_text)

      server_opts = { :SSLEnable => true,
                      :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
                      :SSLCertificate => cert,
                      :SSLPrivateKey => key }

      start_tiny_server(server_opts)
    end

    after(:each) do
      stop_tiny_server
    end

    let(:source) { "https://localhost:9000/nyan_cat.png" }

    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "a file resource"

  end

  context "when dealing with content length checking" do
    before(:each) do
      start_tiny_server
    end

    after(:each) do
      stop_tiny_server
    end

    context "when downloading compressed data" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_content_length_compressed.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    context "when downloding uncompressed data" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_content_length.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    context "when downloading truncated compressed data" do
      let(:source) { "http://localhost:9000/nyan_cat_truncated_compressed.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should raise ContentLengthMismatch" do
        expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        #File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding truncated uncompressed data" do
      let(:source) { "http://localhost:9000/nyan_cat_truncated.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should raise ContentLengthMismatch" do
        expect { resource.run_action(:create) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        #File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding data with transfer-encoding set" do
      let(:expected_content) { binread(nyan_uncompressed_filename) }
      let(:source) { "http://localhost:9000/nyan_cat_transfer_encoding.png" }

      before do
        expect(File).not_to exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        expect(File).to exist(path)
      end

      it "should mark the resource as updated" do
        expect(resource).to be_updated_by_last_action
      end

      it "has the correct content" do
        expect(binread(path)).to eq(expected_content)
      end
    end

    describe "when the download of the source raises an exception" do
      let(:source) { "http://localhost:0000/seattle_capo.png" }

      before do
        expect(File).not_to exist(path)
      end

      it "should not create the file" do
        # This can legitimately raise either Errno::EADDRNOTAVAIL or Errno::ECONNREFUSED
        # in different Ruby versions.
        old_value = RSpec::Expectations.configuration.on_potential_false_positives
        RSpec::Expectations.configuration.on_potential_false_positives = :nothing
        begin
          expect { resource.run_action(:create) }.to raise_error
        ensure
          RSpec::Expectations.configuration.on_potential_false_positives = old_value
        end

        expect(File).not_to exist(path)
      end
    end
  end
end
