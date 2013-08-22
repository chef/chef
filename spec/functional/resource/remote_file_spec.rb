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
    @server = TinyServer::Manager.new(server_opts)
    @server.start
    @api = TinyServer::API.instance
    @api.clear
    @api.get("/nyan_cat.png", 200) {
      File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png'), "rb") do |f|
        f.read
      end
    }
    @api.get("/nyan_cat.png.gz", 200, nil, { 'Content-Type' => 'application/gzip', 'Content-Encoding' => 'gzip' } ) {
      File.open(File.join(CHEF_SPEC_DATA, 'remote_file', 'nyan_cat.png.gz'), "rb") do |f|
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

end
