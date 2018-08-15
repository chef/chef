#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

Chef::Knife::ClientCreate.load_deps

describe Chef::Knife::ClientCreate do
  let(:stderr) { StringIO.new }
  let(:stdout) { StringIO.new }

  let(:default_client_hash) do
    {
      "name" => "adam",
      "validator" => false,
      "admin" => false,
    }
  end

  let(:client) do
    Chef::ApiClientV1.new
  end

  let(:knife) do
    k = Chef::Knife::ClientCreate.new
    k.name_args = []
    allow(k).to receive(:client).and_return(client)
    allow(k).to receive(:edit_hash).with(client).and_return(client)
    allow(k.ui).to receive(:stderr).and_return(stderr)
    allow(k.ui).to receive(:stdout).and_return(stdout)
    k
  end

  before do
    allow(client).to receive(:to_s).and_return("client[adam]")
    allow(knife).to receive(:create_client).and_return(client)
  end

  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
  end

  describe "run" do
    context "when nothing is passed" do
      # from spec/support/shared/unit/knife_shared.rb
      it_should_behave_like "mandatory field missing" do
        let(:name_args) { [] }
        let(:fieldname) { "client name" }
      end
    end

    context "when clientname is passed" do
      before do
        knife.name_args = ["adam"]
      end

      context "when public_key and prevent_keygen are passed" do
        before do
          knife.config[:public_key] = "some_key"
          knife.config[:prevent_keygen] = true
        end

        it "prints the usage" do
          expect(knife).to receive(:show_usage)
          expect { knife.run }.to raise_error(SystemExit)
        end

        it "prints a relevant error message" do
          expect { knife.run }.to raise_error(SystemExit)
          expect(stderr.string).to match /You cannot pass --public-key and --prevent-keygen/
        end
      end

      it "should create the ApiClient" do
        expect(knife).to receive(:create_client)
        knife.run
      end

      it "should print a message upon creation" do
        expect(knife).to receive(:create_client)
        knife.run
        expect(stderr.string).to match /Created client.*adam/i
      end

      it "should set the Client name" do
        knife.run
        expect(client.name).to eq("adam")
      end

      it "by default it is not an admin" do
        knife.run
        expect(client.admin).to be_falsey
      end

      it "by default it is not a validator" do
        knife.run
        expect(client.admin).to be_falsey
      end

      it "by default it should set create_key to true" do
        knife.run
        expect(client.create_key).to be_truthy
      end

      it "should allow you to edit the data" do
        expect(knife).to receive(:edit_hash).with(client).and_return(client)
        knife.run
      end

      describe "with -f or --file" do
        before do
          client.private_key "woot"
        end

        it "should write the private key to a file" do
          knife.config[:file] = "/tmp/monkeypants"
          filehandle = double("Filehandle")
          expect(filehandle).to receive(:print).with("woot")
          expect(File).to receive(:open).with("/tmp/monkeypants", "w").and_yield(filehandle)
          knife.run
        end
      end

      describe "with -a or --admin" do
        before do
          knife.config[:admin] = true
        end

        it "should create an admin client" do
          knife.run
          expect(client.admin).to be_truthy
        end
      end

      describe "with -p or --public-key" do
        before do
          knife.config[:public_key] = "some_key"
          allow(File).to receive(:read).and_return("some_key")
          allow(File).to receive(:expand_path)
        end

        it "sets the public key" do
          knife.run
          expect(client.public_key).to eq("some_key")
        end
      end

      describe "with -k or --prevent-keygen" do
        before do
          knife.config[:prevent_keygen] = true
        end

        it "does not set create_key" do
          knife.run
          expect(client.create_key).to be_falsey
        end
      end

      describe "with --validator" do
        before do
          knife.config[:validator] = true
        end

        it "should create an validator client" do
          knife.run
          expect(client.validator).to be_truthy
        end
      end
    end
  end
end
