#
# Author:: Lamont Granquist (<lamont@chef.io>)
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

#
# shared code for Chef::REST and Chef::HTTP::Simple and other Chef::HTTP wrappers
#

module ChefHTTPShared
  def nyan_uncompressed_filename
    File.join(CHEF_SPEC_DATA, "remote_file", "nyan_cat.png")
  end

  def nyan_compressed_filename
    File.join(CHEF_SPEC_DATA, "remote_file", "nyan_cat.png.gz")
  end

  def binread(file)
    content = File.open(file, "rb") do |f|
      f.read
    end
    content.force_encoding(Encoding::BINARY) if "".respond_to?(:force_encoding)
    content
  end

  def start_tiny_server(server_opts = {})
    nyan_uncompressed_size = File::Stat.new(nyan_uncompressed_filename).size
    nyan_compressed_size   = File::Stat.new(nyan_compressed_filename).size

    @server = TinyServer::Manager.new(server_opts)
    @server.start
    @api = TinyServer::API.instance
    @api.clear

    #
    # trivial endpoints
    #

    # just a normal file
    # (expected_content should be uncompressed)
    @api.get("/nyan_cat.png", 200) do
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    end

    # this ends in .gz, we do not uncompress it and drop it on the filesystem as a .gz file (the internet often lies)
    # (expected_content should be compressed)
    @api.get("/nyan_cat.png.gz", 200, nil, { "Content-Type" => "application/gzip", "Content-Encoding" => "gzip" } ) do
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    end

    # this is an uncompressed file that was compressed by some mod_gzip-ish webserver thingy, so we will expand it
    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_compressed.png", 200, nil, { "Content-Type" => "application/gzip", "Content-Encoding" => "gzip" } ) do
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    end

    #
    # endpoints that set Content-Length correctly
    #

    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_content_length.png", 200, nil,
      {
        "Content-Length" => nyan_uncompressed_size.to_s,
      }
    ) do
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    end

    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_content_length_compressed.png", 200, nil,
      {
        "Content-Length"   => nyan_compressed_size.to_s,
        "Content-Type"     => "application/gzip",
        "Content-Encoding" => "gzip",
      }
    ) do
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    end

    #
    # endpoints that simulate truncated downloads (bad content-length header)
    #

    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_truncated.png", 200, nil,
      {
        "Content-Length" => (nyan_uncompressed_size + 1).to_s,
      }
    ) do
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    end

    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_truncated_compressed.png", 200, nil,
      {
        "Content-Length"   => (nyan_compressed_size + 1).to_s,
        "Content-Type"     => "application/gzip",
        "Content-Encoding" => "gzip",
      }
    ) do
      File.open(nyan_compressed_filename, "rb") do |f|
        f.read
      end
    end

    #
    # in the presence of a transfer-encoding header, we must ignore the content-length (this bad content-length should work)
    #

    # (expected_content should be uncompressed)
    @api.get("/nyan_cat_transfer_encoding.png", 200, nil,
      {
        "Content-Length"    => (nyan_uncompressed_size + 1).to_s,
        "Transfer-Encoding" => "anything",
      }
    ) do
      File.open(nyan_uncompressed_filename, "rb") do |f|
        f.read
      end
    end

    #
    # 403 with a Content-Length
    #
    @api.get("/forbidden", 403, "Forbidden",
      {
        "Content-Length" => "Forbidden".bytesize.to_s,
      }
    )

    @api.post("/posty", 200, "Hi!")

    #
    # 400 with an error
    #
    @api.get("/bad_request", 400, '{ "error": [ "Your request is just terrible." ] }')
    @api.post("/bad_request", 400, '{ "error": [ "Your request is just terrible." ] }')
  end

  def stop_tiny_server
    @server.stop
    @server = @api = nil
  end

end

shared_examples_for "downloading all the things" do

  describe "when downloading a simple uncompressed file" do
    let(:source) { "http://localhost:9000/nyan_cat.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading a compressed file that should be left compressed" do
    let(:source) { "http://localhost:9000/nyan_cat.png.gz" }
    let(:expected_content) { binread(nyan_compressed_filename) }

    # its the callers responsibility to disable_gzip when downloading a .gz url
    let(:http_client) { http_client_disable_gzip }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading a file that has been compressed by the webserver" do
    let(:source) { "http://localhost:9000/nyan_cat_compressed.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading an uncompressed file with a correct content_length" do
    let(:source) { "http://localhost:9000/nyan_cat_content_length.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading a file that has been compressed by the webserver with a correct content_length" do
    let(:source) { "http://localhost:9000/nyan_cat_content_length_compressed.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading an uncompressed file that is truncated" do
    let(:source) { "http://localhost:9000/nyan_cat_truncated.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "validates content length and throws an exception"
  end

  describe "when downloading a file that has been compressed by the webserver that is truncated" do
    let(:source) { "http://localhost:9000/nyan_cat_truncated_compressed.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "validates content length and throws an exception"
  end

  describe "when downloading a file that has transfer encoding set with a bad content length that should be ignored" do
    let(:source) { "http://localhost:9000/nyan_cat_transfer_encoding.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }

    it_behaves_like "downloads requests correctly"
  end

  describe "when downloading an endpoint that 403s" do
    let(:source) { "http://localhost:9000/forbidden" }

    it_behaves_like "an endpoint that 403s"
  end

  describe "when downloading an endpoint that 403s" do
    let(:source) { "http://localhost:9000/nyan_cat_content_length_compressed.png" }
    let(:expected_content) { binread(nyan_uncompressed_filename) }
    let(:source2) { "http://localhost:9000/forbidden" }

    it_behaves_like "a 403 after a successful request when reusing the request object"
  end
end
