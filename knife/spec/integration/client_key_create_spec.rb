#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"
require "openssl"

describe "knife client key create", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:out) { "Created key: new" }

  when_the_chef_server "has a client" do
    before do
      client "bah", {}
    end

    it "creates a new client key" do
      knife("client key create -k new bah").should_succeed stderr: /^#{out}/, stdout: /.*BEGIN RSA PRIVATE KEY/
    end

    it "creates a new client key with an expiration date" do
      date = "2017-12-31T23:59:59Z"
      knife("client key create -k new -e #{date} bah").should_succeed stderr: /^#{out}/, stdout: /.*BEGIN RSA PRIVATE KEY/
      knife("client key show bah new").should_succeed(/expiration_date:.*#{date}/)
    end

    it "refuses to add an already existing key" do
      knife("client key create -k new bah")
      expect { knife("client key create -k new bah") }.to raise_error(Net::HTTPClientException)
    end

    it "saves the private key to a file" do
      Dir.mktmpdir do |tgt|
        knife("client key create -f #{tgt}/bah.pem -k new bah").should_succeed stderr: /^#{out}/
        expect(File).to exist("#{tgt}/bah.pem")
      end
    end

    it "reads the public key from a file" do
      Dir.mktmpdir do |tgt|
        key = OpenSSL::PKey::RSA.generate(1024)
        File.open("#{tgt}/public.pem", "w") { |pub| pub.write(key.public_key.to_pem) }
        knife("client key create -p #{tgt}/public.pem -k new bah").should_succeed stderr: /^#{out}/
      end
    end

  end
end
