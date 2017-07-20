require "spec_helper"

SIGNING_KEY_DOT_PEM = "-----BEGIN RSA PRIVATE KEY-----
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
-----END RSA PRIVATE KEY-----".freeze

describe Chef::ServerAPI do
  let(:url) { "http://chef.example.com:4000" }
  let(:key_path) { "/tmp/foo" }

  let(:client) do
    Chef::ServerAPI.new(url)
  end

  before do
    Chef::Config[:node_name] = "silent-bob"
    Chef::Config[:client_key] = CHEF_SPEC_DATA + "/ssl/private_key.pem"
    Chef::Config[:http_retry_delay] = 0
  end

  describe "#initialize" do
    it "uses the configured key file" do
      allow(IO).to receive(:read).with(key_path).and_return(SIGNING_KEY_DOT_PEM)
      Chef::Config[:client_key] = key_path

      api = described_class.new(url)
      expect(api.options[:signing_key_filename]).to eql(key_path)
    end

    it "allows a user to set a raw_key" do
      api = described_class.new(url, raw_key: SIGNING_KEY_DOT_PEM)
      expect(api.options[:signing_key_filename]).to be_nil
      expect(api.options[:raw_key]).to eql(SIGNING_KEY_DOT_PEM)
    end
  end

  context "versioned apis" do
    class VersionedClassV0
      extend Chef::Mixin::VersionedAPI
      minimum_api_version 0
    end

    class VersionedClassV2
      extend Chef::Mixin::VersionedAPI
      minimum_api_version 2
    end

    class VersionedClassVersions
      extend Chef::Mixin::VersionedAPIFactory
      add_versioned_api_class VersionedClassV0
      add_versioned_api_class VersionedClassV2
    end

    before do
      Chef::ServerAPIVersions.instance.reset!
    end

    let(:versioned_client) do
      Chef::ServerAPI.new(url, version_class: VersionedClassVersions)
    end

    it "on protocol negotiation it posts the same message body without doubly-encoding the json string" do
      WebMock.disable_net_connect!
      post_body = { bar: "baz" }
      body_406 = '{"error":"invalid-x-ops-server-api-version","message":"Specified version 2 not supported","min_version":0,"max_version":1}'
      stub_request(:post, "http://chef.example.com:4000/foo").with(body: post_body.to_json, headers: { "X-Ops-Server-Api-Version" => "2" }).to_return(status: [406, "Not Acceptable"], body: body_406 )
      stub_request(:post, "http://chef.example.com:4000/foo").with(body: post_body.to_json, headers: { "X-Ops-Server-Api-Version" => "0" }).to_return(status: 200, body: "", headers: {})
      versioned_client.post("foo", post_body)
    end
  end

  context "retrying normal requests" do
    it "500 on a post retries and posts correctly " do
      WebMock.disable_net_connect!
      post_body = { bar: "baz" }
      headers = { "Accept" => "application/json", "Content-Type" => "application/json", "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Content-Length" => "13", "Host" => "chef.example.com:4000", "X-Chef-Version" => Chef::VERSION, "X-Ops-Sign" => "algorithm=sha1;version=1.1;", "X-Ops-Userid" => "silent-bob" }
      stub_request(:post, "http://chef.example.com:4000/foo").with(body: post_body.to_json, headers: headers).to_return(status: [500, "Internal Server Error"])
      stub_request(:post, "http://chef.example.com:4000/foo").with(body: post_body.to_json, headers: headers).to_return(status: 200, body: "", headers: {})
      client.post("foo", post_body)
    end

    it "500 on a put retries and puts correctly " do
      WebMock.disable_net_connect!
      put_body = { bar: "baz" }
      headers = { "Accept" => "application/json", "Content-Type" => "application/json", "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Content-Length" => "13", "Host" => "chef.example.com:4000", "X-Chef-Version" => Chef::VERSION, "X-Ops-Sign" => "algorithm=sha1;version=1.1;", "X-Ops-Userid" => "silent-bob" }
      stub_request(:put, "http://chef.example.com:4000/foo").with(body: put_body.to_json, headers: headers).to_return(status: [500, "Internal Server Error"])
      stub_request(:put, "http://chef.example.com:4000/foo").with(body: put_body.to_json, headers: headers).to_return(status: 200, body: "", headers: {})
      client.put("foo", put_body)
    end

    it "500 on a get retries and gets correctly " do
      WebMock.disable_net_connect!
      get_body = { bar: "baz" }
      headers = { "Accept" => "application/json", "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Host" => "chef.example.com:4000", "X-Chef-Version" => Chef::VERSION, "X-Ops-Sign" => "algorithm=sha1;version=1.1;", "X-Ops-Userid" => "silent-bob" }
      stub_request(:get, "http://chef.example.com:4000/foo").with(headers: headers).to_return(status: [500, "Internal Server Error"])
      stub_request(:get, "http://chef.example.com:4000/foo").with(headers: headers).to_return(status: 200, body: "", headers: {})
      client.get("foo")
    end
  end
end
