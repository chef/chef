#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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
require 'tiny_server'

describe Chef::Resource::RemoteFile do

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

  let(:default_mode) { ((0100666 - File.umask) & 07777).to_s(8) }

  def start_tiny_server(server_opts={})
    nyan_uncompressed_filename = File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png')
    nyan_compressed_filename   = File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png.gz')
    nyan_uncompressed_size = File::Stat.new(nyan_uncompressed_filename).size
    nyan_compressed_size = File::Stat.new(nyan_compressed_filename).size

    @server = TinyServer::Manager.new(server_opts)
    @server.start
    @api = TinyServer::API.instance
    @api.clear

    #
    # trivial endpoints
    #

    @api.get("/nyan_cat.png", 200) {
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    }
    @api.get("/nyan_cat.png.gz", 200, nil, { 'Content-Type' => 'application/gzip', 'Content-Encoding' => 'gzip' } ) {
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    }

    #
    # endpoints that set Content-Length correctly
    #

    @api.get("/nyan_cat_content_length.png", 200, nil,
      {
        'Content-Length'   => nyan_uncompressed_size.to_s,
      }
    ) {
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    }

    # this is sent over the wire compressed by the server, but does not have a .gz extension
    @api.get("/nyan_cat_content_length_compressed.png", 200, nil,
      {
        'Content-Length'   => nyan_compressed_size.to_s,
        'Content-Type'     => 'application/gzip',
        'Content-Encoding' => 'gzip'
      }
    ) {
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    }

    #
    # endpoints that simulate truncated downloads (bad content-length header)
    #

    @api.get("/nyan_cat_truncated.png", 200, nil,
      {
        'Content-Length'   => (nyan_uncompressed_size + 1).to_s,
      }
    ) {
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    }
    # this is sent over the wire compressed by the server, but does not have a .gz extension
    @api.get("/nyan_cat_truncated_compressed.png", 200, nil,
      {
        'Content-Length'   => (nyan_compressed_size + 1).to_s,
        'Content-Type'     => 'application/gzip',
        'Content-Encoding' => 'gzip'
      }
    ) {
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    }

    #
    # in the presense of a transfer-encoding header, we must ignore the content-length (this bad content-length should work)
    #

    @api.get("/nyan_cat_transfer_encoding.png", 200, nil,
      {
        'Content-Length'    => (nyan_uncompressed_size + 1).to_s,
        'Transfer-Encoding' => 'anything',
      }
    ) {
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    }

  end

  def stop_tiny_server
    @server.stop
    @server = @api = nil
  end

  context "when fetching files over HTTP" do
    before(:all) do
      start_tiny_server
    end

    after(:all) do
      stop_tiny_server
    end

    describe "when redownload isn't necessary" do
      let(:source) { 'http://localhost:9000/seattle_capo.png' }

      before do
        @api.get("/seattle_capo.png", 304, "", { 'Etag' => 'abcdef' } )
      end

      it "does not fetch the file" do
        resource.run_action(:create)
      end

    end

    context "when using normal encoding" do
      let(:source) { 'http://localhost:9000/nyan_cat.png' }
      let(:expected_content) do
        content = File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'), "rb") do |f|
          f.read
        end
        content.force_encoding(Encoding::BINARY) if content.respond_to?(:force_encoding)
        content
      end

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

    context "when using gzip encoding" do
      let(:source) { 'http://localhost:9000/nyan_cat.png.gz' }
      let(:expected_content) do
        content = File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png.gz'), "rb") do |f|
          f.read
        end
        content.force_encoding(Encoding::BINARY) if content.respond_to?(:force_encoding)
        content
      end

      it_behaves_like "a file resource"

      it_behaves_like "a securable resource with reporting"
    end

  end

  context "when fetching files over HTTPS" do

    before(:all) do
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

    after(:all) do
      stop_tiny_server
    end

    let(:source) { 'https://localhost:9000/nyan_cat.png' }

    let(:expected_content) do
      content = File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'), "rb") do |f|
        f.read
      end
      content.force_encoding(Encoding::BINARY) if content.respond_to?(:force_encoding)
      content
    end

    it_behaves_like "a file resource"

  end

  context "when dealing with content length checking" do

    def binread(file)
      content = File.open(file, "rb") do |f|
        f.read
      end
      content.force_encoding(Encoding::BINARY) if "".respond_to?(:force_encoding)
      content
    end

    before(:all) do
      start_tiny_server
    end

    after(:all) do
      stop_tiny_server
    end

    context "when downloading compressed data" do
      let(:expected_content) { binread( File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png') ) }
      let(:source) { 'http://localhost:9000/nyan_cat_content_length_compressed.png' }

      before do
        File.should_not exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        File.should exist(path)
      end

      it "should mark the resource as updated" do
        resource.should be_updated_by_last_action
      end

      it "has the correct content" do
        binread(path).should == expected_content
      end
    end

    context "when downloding uncompressed data" do
      let(:expected_content) { binread( File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png') ) }
      let(:source) { 'http://localhost:9000/nyan_cat_content_length.png' }

      before do
        File.should_not exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        File.should exist(path)
      end

      it "should mark the resource as updated" do
        resource.should be_updated_by_last_action
      end

      it "has the correct content" do
        binread(path).should == expected_content
      end
    end

    context "when downloading truncated compressed data" do
      let(:source) { 'http://localhost:9000/nyan_cat_truncated_compressed.png' }

      before do
        File.should_not exist(path)
      end

      it "should raise ContentLengthMismatch" do
        lambda { resource.run_action(:create) }.should raise_error(Chef::Exceptions::ContentLengthMismatch)
        #File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding truncated uncompressed data" do
      let(:source) { 'http://localhost:9000/nyan_cat_truncated.png' }

      before do
        File.should_not exist(path)
      end

      it "should raise ContentLengthMismatch" do
        lambda { resource.run_action(:create) }.should raise_error(Chef::Exceptions::ContentLengthMismatch)
        #File.should_not exist(path) # XXX: CHEF-5081
      end
    end

    context "when downloding data with transfer-encoding set" do
      let(:expected_content) { binread( File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png') ) }
      let(:source) { 'http://localhost:9000/nyan_cat_transfer_encoding.png' }

      before do
        File.should_not exist(path)
        resource.run_action(:create)
      end

      it "should create the file" do
        File.should exist(path)
      end

      it "should mark the resource as updated" do
        resource.should be_updated_by_last_action
      end

      it "has the correct content" do
        binread(path).should == expected_content
      end
    end

  end
end
