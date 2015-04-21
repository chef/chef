#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
require 'uri'
require 'net/https'
require 'stringio'

SIGNING_KEY_DOT_PEM="-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA49TA0y81ps0zxkOpmf5V4/c4IeR5yVyQFpX3JpxO4TquwnRh
8VSUhrw8kkTLmB3cS39Db+3HadvhoqCEbqPE6915kXSuk/cWIcNozujLK7tkuPEy
YVsyTioQAddSdfe+8EhQVf3oHxaKmUd6waXrWqYCnhxgOjxocenREYNhZ/OETIei
PbOku47vB4nJK/0GhKBytL2XnsRgfKgDxf42BqAi1jglIdeq8lAWZNF9TbNBU21A
O1iuT7Pm6LyQujhggPznR5FJhXKRUARXBJZawxpGV4dGtdcahwXNE4601aXPra+x
PcRd2puCNoEDBzgVuTSsLYeKBDMSfs173W1QYwIDAQABAoIBAGF05q7vqOGbMaSD
2Q7YbuE/JTHKTBZIlBI1QC2x+0P5GDxyEFttNMOVzcs7xmNhkpRw8eX1LrInrpMk
WsIBKAFFEfWYlf0RWtRChJjNl+szE9jQxB5FJnWtJH/FHa78tR6PsF24aQyzVcJP
g0FGujBihwgfV0JSCNOBkz8MliQihjQA2i8PGGmo4R4RVzGfxYKTIq9vvRq/+QEa
Q4lpVLoBqnENpnY/9PTl6JMMjW2b0spbLjOPVwDaIzXJ0dChjNXo15K5SHI5mALJ
I5gN7ODGb8PKUf4619ez194FXq+eob5YJdilTFKensIUvt3YhP1ilGMM+Chi5Vi/
/RCTw3ECgYEA9jTw4wv9pCswZ9wbzTaBj9yZS3YXspGg26y6Ohq3ZmvHz4jlT6uR
xK+DDcUiK4072gci8S4Np0fIVS7q6ivqcOdzXPrTF5/j+MufS32UrBbUTPiM1yoO
ECcy+1szl/KoLEV09bghPbvC58PFSXV71evkaTETYnA/F6RK12lEepcCgYEA7OSy
bsMrGDVU/MKJtwqyGP9ubA53BorM4Pp9VVVSCrGGVhb9G/XNsjO5wJC8J30QAo4A
s59ZzCpyNRy046AB8jwRQuSwEQbejSdeNgQGXhZ7aIVUtuDeFFdaIz/zjVgxsfj4
DPOuzieMmJ2MLR4F71ocboxNoDI7xruPSE8dDhUCgYA3vx732cQxgtHwAkeNPJUz
dLiE/JU7CnxIoSB9fYUfPLI+THnXgzp7NV5QJN2qzMzLfigsQcg3oyo6F2h7Yzwv
GkjlualIRRzCPaCw4Btkp7qkPvbs1QngIHALt8fD1N69P3DPHkTwjG4COjKWgnJq
qoHKS6Fe/ZlbigikI6KsuwKBgQCTlSLoyGRHr6oj0hqz01EDK9ciMJzMkZp0Kvn8
OKxlBxYW+jlzut4MQBdgNYtS2qInxUoAnaz2+hauqhSzntK3k955GznpUatCqx0R
b857vWviwPX2/P6+E3GPdl8IVsKXCvGWOBZWTuNTjQtwbDzsUepWoMgXnlQJSn5I
YSlLxQKBgQD16Gw9kajpKlzsPa6XoQeGmZALT6aKWJQlrKtUQIrsIWM0Z6eFtX12
2jjHZ0awuCQ4ldqwl8IfRogWMBkHOXjTPVK0YKWWlxMpD/5+bGPARa5fir8O1Zpo
Y6S6MeZ69Rp89ma4ttMZ+kwi1+XyHqC/dlcVRW42Zl5Dc7BALRlJjQ==
-----END RSA PRIVATE KEY-----"

describe Chef::REST do
  let(:base_url) { "http://chef.example.com:4000" }

  let(:monkey_uri) { URI.parse("http://chef.example.com:4000/monkey") }

  let(:log_stringio) { StringIO.new }

  let(:request_id) {"1234"}

  let(:rest) do
    allow(Chef::REST::CookieJar).to receive(:instance).and_return({})
    allow(Chef::RequestID.instance).to receive(:request_id).and_return(request_id)
    rest = Chef::REST.new(base_url, nil, nil)
    Chef::REST::CookieJar.instance.clear
    rest
  end

  let(:standard_read_headers) {{"Accept"=>"application/json", "Accept"=>"application/json", "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "X-REMOTE-REQUEST-ID"=>request_id}}
  let(:standard_write_headers) {{"Accept"=>"application/json", "Content-Type"=>"application/json", "Accept"=>"application/json", "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "X-REMOTE-REQUEST-ID"=>request_id}}

  before(:each) do
    Chef::Log.init(log_stringio)
  end

  it "should have content length validation middleware after compressor middleware" do
    middlewares = rest.instance_variable_get(:@middlewares)
    content_length = middlewares.find_index { |e| e.is_a? Chef::HTTP::ValidateContentLength }
    decompressor = middlewares.find_index { |e| e.is_a? Chef::HTTP::Decompressor }

    expect(content_length).not_to be_nil
    expect(decompressor).not_to be_nil
    expect(decompressor < content_length).to be_truthy
  end

  it "should allow the options hash to be frozen" do
    options = {}.freeze
    # should not raise any exception
    Chef::REST.new(base_url, nil, nil, options)
  end

  context 'when created with a chef zero URL' do

    let(:url) { "chefzero://localhost:1" }

    it "does not load the signing key" do
      expect { Chef::REST.new(url) }.to_not raise_error
    end
  end

  describe "calling an HTTP verb on a path or absolute URL" do
    it "adds a relative URL to the base url it was initialized with" do
      expect(rest.create_url("foo/bar/baz")).to eq(URI.parse(base_url + "/foo/bar/baz"))
    end

    it "replaces the base URL when given an absolute URL" do
      expect(rest.create_url("http://chef-rulez.example.com:9000")).to eq(URI.parse("http://chef-rulez.example.com:9000"))
    end

    it "makes a :GET request with the composed url object" do
      expect(rest).to receive(:send_http_request).
        with(:GET, monkey_uri, standard_read_headers, false).
        and_return([1,2,3])
      expect(rest).to receive(:apply_response_middleware).with(1,2,3).and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.get_rest("monkey")
    end

    it "makes a :GET reqest for a streaming download with the composed url" do
      expect(rest).to receive(:streaming_request).with('monkey', {})
      rest.get_rest("monkey", true)
    end

    it "makes a :DELETE request with the composed url object" do
      expect(rest).to receive(:send_http_request).
        with(:DELETE, monkey_uri, standard_read_headers, false).
        and_return([1,2,3])
      expect(rest).to receive(:apply_response_middleware).with(1,2,3).and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.delete_rest("monkey")
    end

    it "makes a :POST request with the composed url object and data" do
      expect(rest).to receive(:send_http_request).
        with(:POST, monkey_uri, standard_write_headers, "\"data\"").
        and_return([1,2,3])
      expect(rest).to receive(:apply_response_middleware).with(1,2,3).and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.post_rest("monkey", "data")
    end

    it "makes a :PUT request with the composed url object and data" do
      expect(rest).to receive(:send_http_request).
        with(:PUT, monkey_uri, standard_write_headers, "\"data\"").
        and_return([1,2,3])
      expect(rest).to receive(:apply_response_middleware).with(1,2,3).and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.put_rest("monkey", "data")
    end
  end

  describe "legacy API" do
    let(:rest) do
      Chef::REST.new(base_url)
    end

    before(:each) do
      Chef::Config[:node_name]  = "webmonkey.example.com"
      Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    end

    it 'responds to raw_http_request as a public method' do
      expect(rest.public_methods.map(&:to_s)).to include("raw_http_request")
    end

    it 'calls the authn middleware' do
      data = "\"secure data\""

      auth_headers = standard_write_headers.merge({"auth_done"=>"yep"})

      expect(rest.authenticator).to receive(:handle_request).
        with(:POST, monkey_uri, standard_write_headers, data).
        and_return([:POST, monkey_uri, auth_headers, data])
      expect(rest).to receive(:send_http_request).
        with(:POST, monkey_uri, auth_headers, data).
        and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.raw_http_request(:POST, monkey_uri, standard_write_headers, data)
    end

    it 'sets correct authn headers' do
      data = "\"secure data\""
      method, uri, auth_headers, d = rest.authenticator.handle_request(:POST, monkey_uri, standard_write_headers, data)

      expect(rest).to receive(:send_http_request).
        with(:POST, monkey_uri, auth_headers, data).
        and_return([1,2,3])
      expect(rest).to receive('success_response?'.to_sym).with(1).and_return(true)
      rest.raw_http_request(:POST, monkey_uri, standard_write_headers, data)
    end
  end


  describe "when configured to authenticate to the Chef server" do
    let(:base_url) { URI.parse("http://chef.example.com:4000") }

    let(:rest) do
      Chef::REST.new(base_url)
    end

    before do
      Chef::Config[:node_name]  = "webmonkey.example.com"
      Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    end

    it "configures itself to use the node_name and client_key in the config by default" do
      expect(rest.client_name).to eq("webmonkey.example.com")
      expect(rest.signing_key_filename).to eq(CHEF_SPEC_DATA + "/ssl/private_key.pem")
    end

    it "provides access to the raw key data" do
      expect(rest.signing_key).to eq(SIGNING_KEY_DOT_PEM)
    end

    it "does not error out when initialized without credentials" do
      rest = Chef::REST.new(base_url, nil, nil) #should_not raise_error hides the bt from you, so screw it.
      expect(rest.client_name).to be_nil
      expect(rest.signing_key).to be_nil
    end

    it "indicates that requests should not be signed when it has no credentials" do
      rest = Chef::REST.new(base_url, nil, nil)
      expect(rest.sign_requests?).to be_falsey
    end

    it "raises PrivateKeyMissing when the key file doesn't exist" do
      expect {Chef::REST.new(base_url, "client-name", "/dev/null/nothing_here")}.to raise_error(Chef::Exceptions::PrivateKeyMissing)
    end

    it "raises InvalidPrivateKey when the key file doesnt' look like a key" do
      invalid_key_file = CHEF_SPEC_DATA + "/bad-config.rb"
      expect {Chef::REST.new(base_url, "client-name", invalid_key_file)}.to raise_error(Chef::Exceptions::InvalidPrivateKey)
    end

    it "can take private key as a sting :raw_key in options during initializaton" do
      expect(Chef::REST.new(base_url, "client-name", nil, :raw_key => SIGNING_KEY_DOT_PEM).signing_key).to eq(SIGNING_KEY_DOT_PEM)
    end

    it "raises InvalidPrivateKey when the key passed as string :raw_key in options doesnt' look like a key" do
      expect {Chef::REST.new(base_url, "client-name", nil, :raw_key => "bad key string")}.to raise_error(Chef::Exceptions::InvalidPrivateKey)
    end

  end

  context "when making REST requests" do
    let(:body) { "ninja" }

    let(:http_response) do
      http_response = Net::HTTPSuccess.new("1.1", "200", "successful rest req")
      allow(http_response).to receive(:read_body)
      allow(http_response).to receive(:body).and_return(body)
      http_response["Content-Length"] = body.bytesize.to_s
      http_response
    end

    let(:host_header) { "one" }

    let(:url) { URI.parse("http://one:80/?foo=bar") }

    let(:base_url) { "http://chef.example.com:4000" }

    let!(:http_client) do
      http_client = Net::HTTP.new(url.host, url.port)
      allow(http_client).to receive(:request).and_yield(http_response).and_return(http_response)
      http_client
    end

    let(:rest) do
      allow(Net::HTTP).to receive(:new).and_return(http_client)
      allow(Chef::REST::CookieJar).to receive(:instance).and_return({})
      allow(Chef::RequestID.instance).to receive(:request_id).and_return(request_id)
      rest = Chef::REST.new(base_url, nil, nil)
      Chef::REST::CookieJar.instance.clear
      rest
    end

    let(:base_headers) do
      {
        'Accept' => 'application/json',
        'X-Chef-Version' => Chef::VERSION,
        'Accept-Encoding' => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE,
        'X-REMOTE-REQUEST-ID' => request_id
      }
    end

    let (:req_with_body_headers) do
      base_headers.merge("Content-Type" => "application/json", "Content-Length" => '13')
    end

    before(:each) do
      Chef::Config[:ssl_client_cert] = nil
      Chef::Config[:ssl_client_key]  = nil
    end

    describe "as JSON API requests" do
      let(:request_mock) { {} }

      let(:base_headers) do  #FIXME: huh?
        {
          'Accept' => 'application/json',
          'X-Chef-Version' => Chef::VERSION,
          'Accept-Encoding' => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE,
          'Host' => host_header,
          'X-REMOTE-REQUEST-ID' => request_id
        }
      end

      before do
        allow(Net::HTTP::Get).to receive(:new).and_return(request_mock)
      end

      it "should always include the X-Chef-Version header" do
        expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", base_headers).and_return(request_mock)
        rest.request(:GET, url, {})
      end

      it "should always include the X-Remote-Request-Id header" do
        expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", base_headers).and_return(request_mock)
        rest.request(:GET, url, {})
      end

      it "sets the user agent to chef-client" do
        # XXX: must reset to default b/c knife changes the UA
        Chef::REST::RESTRequest.user_agent = Chef::REST::RESTRequest::DEFAULT_UA
        rest.request(:GET, url, {})
        expect(request_mock['User-Agent']).to match(/^Chef Client\/#{Chef::VERSION}/)
      end

      # CHEF-3140
      context "when configured to disable compression" do
        let(:rest) do
          allow(Net::HTTP).to receive(:new).and_return(http_client)
          Chef::REST.new(base_url, nil, nil,  :disable_gzip => true)
        end

        it "does not accept encoding gzip" do
          expect(rest.send(:build_headers, :GET, url, {})).not_to have_key("Accept-Encoding")
        end

        it "does not decompress a response encoded as gzip" do
          http_response.add_field("content-encoding", "gzip")
          request = Net::HTTP::Get.new(url.path)
          expect(Net::HTTP::Get).to receive(:new).and_return(request)
          # will raise a Zlib error if incorrect
          expect(rest.request(:GET, url, {})).to eq("ninja")
        end
      end

      context "when configured with custom http headers" do
        let(:custom_headers) do
          {
            'X-Custom-ChefSecret' => 'sharpknives',
            'X-Custom-RequestPriority' => 'extremely low'
          }
        end

        before(:each) do
          Chef::Config[:custom_http_headers] = custom_headers
        end

        after(:each) do
          Chef::Config[:custom_http_headers] = nil
        end

        it "should set them on the http request" do
          url_string = an_instance_of(String)
          header_hash = hash_including(custom_headers)
          expect(Net::HTTP::Get).to receive(:new).with(url_string, header_hash)
          rest.request(:GET, url, {})
        end
      end

      context "when setting cookies" do
        let(:rest) do
          allow(Net::HTTP).to receive(:new).and_return(http_client)
          Chef::REST::CookieJar.instance["#{url.host}:#{url.port}"] = "cookie monster"
          allow(Chef::RequestID.instance).to receive(:request_id).and_return(request_id)
          rest = Chef::REST.new(base_url, nil, nil)
          rest
        end

        it "should set the cookie for this request if one exists for the given host:port" do
          expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", base_headers.merge('Cookie' => "cookie monster")).and_return(request_mock)
          rest.request(:GET, url, {})
        end
      end

      it "should build a new HTTP GET request" do
        expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", base_headers).and_return(request_mock)
        rest.request(:GET, url, {})
      end

      it "should build a new HTTP POST request" do
        request = Net::HTTP::Post.new(url.path)
        expected_headers = base_headers.merge("Content-Type" => 'application/json', 'Content-Length' => '13')

        expect(Net::HTTP::Post).to receive(:new).with("/?foo=bar", expected_headers).and_return(request)
        rest.request(:POST, url, {}, {:one=>:two})
        expect(request.body).to eq('{"one":"two"}')
      end

      it "should build a new HTTP PUT request" do
        request = Net::HTTP::Put.new(url.path)
        expected_headers = base_headers.merge("Content-Type" => 'application/json', 'Content-Length' => '13')
        expect(Net::HTTP::Put).to receive(:new).with("/?foo=bar",expected_headers).and_return(request)
        rest.request(:PUT, url, {}, {:one=>:two})
        expect(request.body).to eq('{"one":"two"}')
      end

      it "should build a new HTTP DELETE request" do
        expect(Net::HTTP::Delete).to receive(:new).with("/?foo=bar", base_headers).and_return(request_mock)
        rest.request(:DELETE, url)
      end

      it "should raise an error if the method is not GET/PUT/POST/DELETE" do
        expect { rest.request(:MONKEY, url) }.to raise_error(ArgumentError)
      end

      it "returns nil when the response is successful but content-type is not JSON" do
        expect(rest.request(:GET, url)).to eq("ninja")
      end

      it "should fail if the response is truncated" do
        http_response["Content-Length"] = (body.bytesize + 99).to_s
        expect { rest.request(:GET, url) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
      end

      context "when JSON is returned" do
        let(:body) { '{"ohai2u":"json_api"}' }
        it "should inflate the body as to an object" do
          http_response.add_field('content-type', "application/json")
          expect(rest.request(:GET, url, {})).to eq({"ohai2u"=>"json_api"})
        end

        it "should fail if the response is truncated" do
          http_response.add_field('content-type', "application/json")
          http_response["Content-Length"] = (body.bytesize + 99).to_s
          expect { rest.request(:GET, url, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
        end
      end

      %w[ HTTPFound HTTPMovedPermanently HTTPSeeOther HTTPUseProxy HTTPTemporaryRedirect HTTPMultipleChoice ].each do |resp_name|
        describe "when encountering a #{resp_name} redirect" do
          let(:http_response) do
            resp_cls  = Net.const_get(resp_name)
            resp_code = Net::HTTPResponse::CODE_TO_OBJ.keys.detect { |k| Net::HTTPResponse::CODE_TO_OBJ[k] == resp_cls }
            http_response = Net::HTTPFound.new("1.1", resp_code, "bob is somewhere else again")
            http_response.add_field("location", url.path)
            allow(http_response).to receive(:read_body)
            http_response
          end
          it "should call request again" do

            expect { rest.request(:GET, url) }.to raise_error(Chef::Exceptions::RedirectLimitExceeded)

            [:PUT, :POST, :DELETE].each do |method|
              expect { rest.request(method, url) }.to raise_error(Chef::Exceptions::InvalidRedirect)
            end
          end
        end
      end

      context "when the response is 304 NotModified" do
        let (:http_response) do
          http_response = Net::HTTPNotModified.new("1.1", "304", "it's the same as when you asked 5 minutes ago")
          allow(http_response).to receive(:read_body)
          http_response
        end

        it "should return `false`" do
          expect(rest.request(:GET, url)).to be_falsey
        end
      end

      describe "when the request fails" do
        before do
          @original_log_level = Chef::Log.level
          Chef::Log.level = :info
        end

        after do
          Chef::Log.level = @original_log_level
        end

        context "on an unsuccessful response with a JSON error" do
          let(:http_response) do
            http_response = Net::HTTPServerError.new("1.1", "500", "drooling from inside of mouth")
            http_response.add_field("content-type", "application/json")
            allow(http_response).to receive(:body).and_return('{ "error":[ "Ears get sore!", "Not even four" ] }')
            allow(http_response).to receive(:read_body)
            http_response
          end

          it "should show the JSON error message" do
            allow(rest).to receive(:sleep)

            expect {rest.request(:GET, url)}.to raise_error(Net::HTTPFatalError)
            expect(log_stringio.string).to match(Regexp.escape('INFO: HTTP Request Returned 500 drooling from inside of mouth: Ears get sore!, Not even four'))
          end
        end

        context "on an unsuccessful response with a JSON error that is compressed" do
          let(:http_response) do
            http_response = Net::HTTPServerError.new("1.1", "500", "drooling from inside of mouth")
            http_response.add_field("content-type", "application/json")
            http_response.add_field("content-encoding", "deflate")
            unzipped_body = '{ "error":[ "Ears get sore!", "Not even four" ] }'
            gzipped_body = Zlib::Deflate.deflate(unzipped_body)
            gzipped_body.force_encoding(Encoding::BINARY) if "strings".respond_to?(:force_encoding)

            allow(http_response).to receive(:body).and_return gzipped_body
            allow(http_response).to receive(:read_body)
            http_response
          end

          before do
            allow(rest).to receive(:sleep)
            allow(rest).to receive(:http_retry_count).and_return(0)
          end

          it "decompresses the JSON error message" do
            expect {rest.request(:GET, url)}.to raise_error(Net::HTTPFatalError)
            expect(log_stringio.string).to match(Regexp.escape('INFO: HTTP Request Returned 500 drooling from inside of mouth: Ears get sore!, Not even four'))
          end

          it "fails when the compressed body is truncated" do
            http_response["Content-Length"] = (body.bytesize + 99).to_s
            expect {rest.request(:GET, url)}.to raise_error(Chef::Exceptions::ContentLengthMismatch)
          end
        end

        context "on a generic unsuccessful request" do
          let(:http_response) do
            http_response = Net::HTTPServerError.new("1.1", "500", "drooling from inside of mouth")
            allow(http_response).to receive(:body)
            allow(http_response).to receive(:read_body)
            http_response
          end

          it "retries then throws an exception" do
            allow(rest).to receive(:sleep)
            expect {rest.request(:GET, url)}.to raise_error(Net::HTTPFatalError)
            count = Chef::Config[:http_retry_count]
            expect(log_stringio.string).to match(Regexp.escape("ERROR: Server returned error 500 for #{url}, retrying #{count}/#{count}"))
          end
        end
      end
    end

    context "when streaming downloads to a tempfile" do
      let!(:tempfile) {  Tempfile.open("chef-rspec-rest_spec-line-@{__LINE__}--") }

      let(:request_mock) { {} }

      let(:http_response) do
        http_response = Net::HTTPSuccess.new("1.1",'200', "it-works")

        allow(http_response).to receive(:read_body)
        expect(http_response).not_to receive(:body)
        http_response["Content-Length"] = "0" # call set_content_length (in test), if otherwise
        http_response
      end

      def set_content_length
        content_length = 0
        http_response.read_body do |chunk|
          content_length += chunk.bytesize
        end
        http_response["Content-Length"] = content_length.to_s
      end

      before do
        allow(Tempfile).to receive(:new).with("chef-rest").and_return(tempfile)
        allow(Net::HTTP::Get).to receive(:new).and_return(request_mock)
      end

      after do
        tempfile.close!
      end

      it " build a new HTTP GET request without the application/json accept header" do
        expected_headers = {'Accept' => "*/*",
                            'X-Chef-Version' => Chef::VERSION,
                            'Accept-Encoding' => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE,
                            'Host' => host_header,
                            'X-REMOTE-REQUEST-ID'=> request_id
                            }
        expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", expected_headers).and_return(request_mock)
        rest.streaming_request(url, {})
      end

      it "build a new HTTP GET request with the X-Remote-Request-Id header" do
        expected_headers = {'Accept' => "*/*",
                            'X-Chef-Version' => Chef::VERSION,
                            'Accept-Encoding' => Chef::REST::RESTRequest::ENCODING_GZIP_DEFLATE,
                            'Host' => host_header,
                            'X-REMOTE-REQUEST-ID'=> request_id
                            }
        expect(Net::HTTP::Get).to receive(:new).with("/?foo=bar", expected_headers).and_return(request_mock)
        rest.streaming_request(url, {})
      end

      it "returns a tempfile containing the streamed response body" do
        expect(rest.streaming_request(url, {})).to equal(tempfile)
      end

      it "writes the response body to a tempfile" do
        allow(http_response).to receive(:read_body).and_yield("real").and_yield("ultimate").and_yield("power")
        set_content_length
        rest.streaming_request(url, {})
        expect(IO.read(tempfile.path).chomp).to eq("realultimatepower")
      end

      it "closes the tempfile" do
        rest.streaming_request(url, {})
        expect(tempfile).to be_closed
      end

      it "yields the tempfile containing the streamed response body and then unlinks it when given a block" do
        allow(http_response).to receive(:read_body).and_yield("real").and_yield("ultimate").and_yield("power")
        set_content_length
        tempfile_path = nil
        rest.streaming_request(url, {}) do |tempfile|
          tempfile_path = tempfile.path
          expect(File.exist?(tempfile.path)).to be_truthy
          expect(IO.read(tempfile.path).chomp).to eq("realultimatepower")
        end
        expect(File.exist?(tempfile_path)).to be_falsey
      end

      it "does not raise a divide by zero exception if the content's actual size is 0" do
        http_response['Content-Length'] = "5"
        allow(http_response).to receive(:read_body).and_yield('')
        expect { rest.streaming_request(url, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
      end

      it "does not raise a divide by zero exception when the Content-Length is 0" do
        http_response['Content-Length'] = "0"
        allow(http_response).to receive(:read_body).and_yield("ninja")
        expect { rest.streaming_request(url, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
      end

      it "it raises an exception when the download is truncated" do
        http_response["Content-Length"] = (body.bytesize + 99).to_s
        allow(http_response).to receive(:read_body).and_yield("ninja")
        expect { rest.streaming_request(url, {}) }.to raise_error(Chef::Exceptions::ContentLengthMismatch)
      end

      it "fetches a file and yields the tempfile it is streamed to" do
        allow(http_response).to receive(:read_body).and_yield("real").and_yield("ultimate").and_yield("power")
        set_content_length
        tempfile_path = nil
        rest.fetch("cookbooks/a_cookbook") do |tempfile|
          tempfile_path = tempfile.path
          expect(IO.read(tempfile.path).chomp).to eq("realultimatepower")
        end
        expect(File.exist?(tempfile_path)).to be_falsey
      end

      it "closes and unlinks the tempfile if there is an error while streaming the content to the tempfile" do
        path = tempfile.path
        expect(path).not_to be_nil
        allow(tempfile).to receive(:write).and_raise(IOError)
        rest.fetch("cookbooks/a_cookbook") {|tmpfile| "shouldn't get here"}
        expect(File.exists?(path)).to be_falsey
      end

      it "closes and unlinks the tempfile when the response is a redirect" do
        tempfile = double("A tempfile", :path => "/tmp/ragefist", :close => true, :binmode => true)
        expect(tempfile).to receive(:close!).at_least(1).times
        allow(Tempfile).to receive(:new).with("chef-rest").and_return(tempfile)

        redirect = Net::HTTPFound.new("1.1", "302", "bob is taking care of that one for me today")
        redirect.add_field("location", url.path)
        allow(redirect).to receive(:read_body)

        expect(http_client).to receive(:request).and_yield(redirect).and_return(redirect)
        expect(http_client).to receive(:request).and_yield(http_response).and_return(http_response)
        rest.fetch("cookbooks/a_cookbook") {|tmpfile| "shouldn't get here"}
      end

      it "passes the original block to the redirected request" do
        http_redirect = Net::HTTPFound.new("1.1", "302", "bob is taking care of that one for me today")
        http_redirect.add_field("location","/that-thing-is-here-now")
        allow(http_redirect).to receive(:read_body)

        block_called = false
        allow(http_client).to receive(:request).and_yield(http_response).and_return(http_redirect, http_response)
        rest.fetch("cookbooks/a_cookbook") do |tmpfile|
          block_called = true
        end
        expect(block_called).to be_truthy
      end
    end
  end

  context "when following redirects" do
    let(:rest) do
      Chef::REST.new(base_url)
    end

    before do
      Chef::Config[:node_name]  = "webmonkey.example.com"
      Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    end

    it "raises a RedirectLimitExceeded when redirected more than 10 times" do
      redirected = lambda {rest.follow_redirect { redirected.call }}
      expect {redirected.call}.to raise_error(Chef::Exceptions::RedirectLimitExceeded)
    end

    it "does not count redirects from previous calls against the redirect limit" do
      total_redirects = 0
      redirected = lambda do
        rest.follow_redirect do
          total_redirects += 1
          redirected.call unless total_redirects >= 9
        end
      end
      expect {redirected.call}.not_to raise_error
      total_redirects = 0
      expect {redirected.call}.not_to raise_error
    end

    it "does not sign the redirected request when sign_on_redirect is false" do
      rest.sign_on_redirect = false
      rest.follow_redirect { expect(rest.sign_requests?).to be_falsey }
    end

    it "resets sign_requests to the original value after following an unsigned redirect" do
      rest.sign_on_redirect = false
      expect(rest.sign_requests?).to be_truthy

      rest.follow_redirect { expect(rest.sign_requests?).to be_falsey }
      expect(rest.sign_requests?).to be_truthy
    end

    it "configures the redirect limit" do
      total_redirects = 0
      redirected = lambda do
        rest.follow_redirect do
          total_redirects += 1
          redirected.call unless total_redirects >= 9
        end
      end
      expect {redirected.call}.not_to raise_error

      total_redirects = 0
      rest.redirect_limit = 3
      expect {redirected.call}.to raise_error(Chef::Exceptions::RedirectLimitExceeded)
    end

  end
end
