#
# Author:: Tyler Ball (<tball@chef.io>)
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

require "knife_spec_helper"
require "chef/knife"
require "chef/config"
require "tempfile"

class ExampleDataBagCommand < Chef::Knife
  include Chef::Knife::DataBagSecretOptions
end

describe Chef::Knife::DataBagSecretOptions do
  let(:example_db) do
    k = ExampleDataBagCommand.new
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  let(:stdout) { StringIO.new }

  let(:secret) { "abc123SECRET" }
  let(:secret_file) do
    sfile = Tempfile.new("encrypted_data_bag_secret")
    sfile.puts(secret)
    sfile.flush
    sfile
  end

  after do
    secret_file.close
    secret_file.unlink
  end

  describe "#validate_secrets" do

    it "throws an error when provided with both --secret and --secret-file on the CL" do
      example_db.config[:cl_secret_file] = secret_file.path
      example_db.config[:cl_secret] = secret
      expect(example_db).to receive(:exit).with(1)
      expect(example_db.ui).to receive(:fatal).with("Please specify only one of --secret, --secret-file")

      example_db.validate_secrets
    end

    it "throws an error when provided with `secret` and `secret_file` in knife.rb" do
      Chef::Config[:knife][:secret_file] = secret_file.path
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db).to receive(:exit).with(1)
      expect(example_db.ui).to receive(:fatal).with("Please specify only one of 'secret' or 'secret_file' in your config file")

      example_db.validate_secrets
    end

  end

  describe "#read_secret" do

    it "returns the secret first" do
      example_db.config[:cl_secret] = secret
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db.read_secret).to eq(secret)
    end

    it "returns the secret_file only if secret does not exist" do
      example_db.config[:cl_secret_file] = secret_file.path
      Chef::Config[:knife][:secret_file] = secret_file.path
      example_db.merge_configs
      expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(secret_file.path).and_return("secret file contents")
      expect(example_db.read_secret).to eq("secret file contents")
    end

    it "returns the secret from the knife.rb config" do
      Chef::Config[:knife][:secret_file] = secret_file.path
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db.read_secret).to eq(secret)
    end

    it "returns the secret_file from the knife.rb config only if the secret does not exist" do
      Chef::Config[:knife][:secret_file] = secret_file.path
      example_db.merge_configs
      expect(Chef::EncryptedDataBagItem).to receive(:load_secret).with(secret_file.path).and_return("secret file contents")
      expect(example_db.read_secret).to eq("secret file contents")
    end

  end

  describe "#encryption_secret_provided?" do

    it "returns true if the secret is passed on the CL" do
      example_db.config[:cl_secret] = secret
      expect(example_db.encryption_secret_provided?).to eq(true)
    end

    it "returns true if the secret_file is passed on the CL" do
      example_db.config[:cl_secret_file] = secret_file.path
      expect(example_db.encryption_secret_provided?).to eq(true)
    end

    it "returns true if --encrypt is passed on the CL and :secret is in config" do
      example_db.config[:encrypt] = true
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db.encryption_secret_provided?).to eq(true)
    end

    it "returns true if --encrypt is passed on the CL and :secret_file is in config" do
      example_db.config[:encrypt] = true
      Chef::Config[:knife][:secret_file] = secret_file.path
      example_db.merge_configs
      expect(example_db.encryption_secret_provided?).to eq(true)
    end

    it "throws an error if --encrypt is passed and there is not :secret or :secret_file in the config" do
      example_db.config[:encrypt] = true
      expect(example_db).to receive(:exit).with(1)
      expect(example_db.ui).to receive(:fatal).with("No secret or secret_file specified in config, unable to encrypt item.")
      example_db.encryption_secret_provided?
    end

    it "returns false if no secret is passed" do
      expect(example_db.encryption_secret_provided?).to eq(false)
    end

    it "returns false if --encrypt is not provided and :secret is in the config" do
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db.encryption_secret_provided?).to eq(false)
    end

    it "returns false if --encrypt is not provided and :secret_file is in the config" do
      Chef::Config[:knife][:secret_file] = secret_file.path
      example_db.merge_configs
      expect(example_db.encryption_secret_provided?).to eq(false)
    end

    it "returns true if --encrypt is not provided, :secret is in the config and need_encrypt_flag is false" do
      Chef::Config[:knife][:secret] = secret
      example_db.merge_configs
      expect(example_db.encryption_secret_provided_ignore_encrypt_flag?).to eq(true)
    end

    it "returns true if --encrypt is not provided, :secret_file is in the config and need_encrypt_flag is false" do
      Chef::Config[:knife][:secret_file] = secret_file.path
      example_db.merge_configs
      expect(example_db.encryption_secret_provided_ignore_encrypt_flag?).to eq(true)
    end

    it "returns false if --encrypt is not provided and need_encrypt_flag is false" do
      expect(example_db.encryption_secret_provided_ignore_encrypt_flag?).to eq(false)
    end

  end

end
