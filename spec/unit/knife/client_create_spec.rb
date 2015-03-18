#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

Chef::Knife::ClientCreate.load_deps

describe Chef::Knife::ClientCreate do
  let(:stderr) { StringIO.new }

  let(:default_client_hash) do
    {
      "name" => "adam",
      "validator" => false,
      "admin" => false
    }
  end

  let(:client) do
    c = double("Chef::ApiClient")
    allow(c).to receive(:save).and_return({"private_key" => ""})
    allow(c).to receive(:to_s).and_return("client[adam]")
    c
  end

  let(:knife) do
    k = Chef::Knife::ClientCreate.new
    k.name_args = [ "adam" ]
    k.ui.config[:disable_editing] = true
    allow(k.ui).to receive(:stderr).and_return(stderr)
    allow(k.ui).to receive(:stdout).and_return(stderr)
    k
  end

  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
  end

  describe "run" do
    it "should create and save the ApiClient" do
      expect(Chef::ApiClient).to receive(:from_hash).and_return(client)
      expect(client).to receive(:save)
      knife.run
    end

    it "should print a message upon creation" do
      expect(Chef::ApiClient).to receive(:from_hash).and_return(client)
      expect(client).to receive(:save)
      knife.run
      expect(stderr.string).to match /Created client.*adam/i
    end

    it "should set the Client name" do
      expect(Chef::ApiClient).to receive(:from_hash).with(hash_including("name" => "adam")).and_return(client)
      knife.run
    end

    it "by default it is not an admin" do
      expect(Chef::ApiClient).to receive(:from_hash).with(hash_including("admin" => false)).and_return(client)
      knife.run
    end

    it "by default it is not a validator" do
      expect(Chef::ApiClient).to receive(:from_hash).with(hash_including("validator" => false)).and_return(client)
      knife.run
    end

    it "should allow you to edit the data" do
      expect(knife).to receive(:edit_hash).with(default_client_hash).and_return(default_client_hash)
      allow(Chef::ApiClient).to receive(:from_hash).and_return(client)
      knife.run
    end

    describe "with -f or --file" do
      it "should write the private key to a file" do
        knife.config[:file] = "/tmp/monkeypants"
        allow_any_instance_of(Chef::ApiClient).to receive(:save).and_return({ 'private_key' => "woot" })
        filehandle = double("Filehandle")
        expect(filehandle).to receive(:print).with('woot')
        expect(File).to receive(:open).with("/tmp/monkeypants", "w").and_yield(filehandle)
        knife.run
      end
    end

    describe "with -a or --admin" do
      it "should create an admin client" do
        knife.config[:admin] = true
        expect(Chef::ApiClient).to receive(:from_hash).with(hash_including("admin" => true)).and_return(client)
        knife.run
      end
    end

    describe "with --validator" do
      it "should create an validator client" do
        knife.config[:validator] = true
        expect(Chef::ApiClient).to receive(:from_hash).with(hash_including("validator" => true)).and_return(client)
        knife.run
      end
    end
  end
end
