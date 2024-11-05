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
#

require "spec_helper"
require "chef/context"
require "openssl"

describe Chef::Context do
  describe "when executed normally" do
    before(:each) do
      described_class.send(:reset_context)
    end

    it "#test_kitchen_context? should return false" do
      expect(described_class.test_kitchen_context?).to be_falsey
    end

    it "#context_secret should be empty" do
      expect(described_class.send(:context_secret)).to eq("")
    end
  end

  context "when executed from test kitchen" do
    let(:context_key) { "key-123" }

    before(:each) do
      described_class.send(:reset_context)
      allow(ENV).to receive(:fetch).with("TEST_KITCHEN_CONTEXT", "").and_return(context_key)

      # Mock the signed file content
      nonce = Base64.encode64(SecureRandom.random_bytes(16)).strip
      timestamp = Time.now.utc.to_i
      signature = OpenSSL::HMAC.hexdigest("SHA256", context_key, "#{nonce}:#{timestamp}")

      file_data = "nonce:#{nonce}\ntimestamp:#{timestamp}\nsignature:#{signature}"
      allow(File).to receive(:exist?).with(described_class.send(:signed_file_path)).and_return(true)
      allow(File).to receive(:open).with(described_class.send(:signed_file_path), "r:bom|utf-16le:utf-8").and_yield(StringIO.new(file_data))
      allow(File).to receive(:delete).with(described_class.send(:signed_file_path)).and_return(true)
    end

    it "#context_secret should return the context key" do
      expect(described_class.send(:context_secret)).to eq(context_key)
    end

    it "#test_kitchen_context? should return true" do
      expect(described_class.test_kitchen_context?).to eq(true)
    end
  end
end