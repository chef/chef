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
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::ClientCreate.new
    @knife.config = {
      :file => nil,
      :admin => false,
      :validator => false
    }
    @knife.name_args = [ "adam" ]
    @client = Chef::ApiClient.new
    @client.stub(:save).and_return({ 'private_key' => '' })
    @knife.stub(:edit_data).and_return(@client)
    @knife.stub(:puts)
    Chef::ApiClient.stub(:new).and_return(@client)
    @stderr = StringIO.new
    @knife.ui.stub(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "should create a new Client" do
      Chef::ApiClient.should_receive(:new).and_return(@client)
      @knife.run
      @stderr.string.should match /created client.+adam/i
    end

    it "should set the Client name" do
      @client.should_receive(:name).with("adam")
      @knife.run
    end

    it "by default it is not an admin" do
      @client.should_receive(:admin).with(false)
      @knife.run
    end

    it "by default it is not a validator" do
      @client.should_receive(:validator).with(false)
      @knife.run
    end

    it "should allow you to edit the data" do
      @knife.should_receive(:edit_data).with(@client)
      @knife.run
    end

    it "should save the Client" do
      @client.should_receive(:save)
      @knife.run
    end

    describe "with -f or --file" do
      it "should write the private key to a file" do
        @knife.config[:file] = "/tmp/monkeypants"
        @client.stub(:save).and_return({ 'private_key' => "woot" })
        filehandle = double("Filehandle")
        filehandle.should_receive(:print).with('woot')
        File.should_receive(:open).with("/tmp/monkeypants", "w").and_yield(filehandle)
        @knife.run
      end
    end

    describe "with -a or --admin" do
      it "should create an admin client" do
        @knife.config[:admin] = true
        @client.should_receive(:admin).with(true)
        @knife.run
      end
    end

    describe "with --validator" do
      it "should create an validator client" do
        @knife.config[:validator] = true
        @client.should_receive(:validator).with(true)
        @knife.run
      end
    end

  end
end
