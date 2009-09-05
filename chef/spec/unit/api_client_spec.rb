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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'chef/api_client'

describe Chef::ApiClient do
  before(:each) do
    @client = Chef::ApiClient.new
  end

  describe "initialize" do
    it "should be a Chef::ApiClient" do
      @client.should be_a_kind_of(Chef::ApiClient)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @client.name("ops_master").should == "ops_master"
    end

    it "should return the current name" do
      @client.name "ops_master"
      @client.name.should == "ops_master"
    end

    it "should not accept spaces" do
      lambda { @client.name "ops master" }.should raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      lambda { @client.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "public_key" do
    it "should let you set the public key" do
      @client.public_key("super public").should == "super public"
    end

    it "should return the current public key" do
      @client.public_key("super public")
      @client.public_key.should == "super public"
    end

    it "should throw an ArgumentError if you feed it something lame" do
      lambda { @client.public_key Hash.new }.should raise_error(ArgumentError)
    end 
  end

  describe "serialize" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @serial = @client.to_json
    end

    it "should serialize to a json hash" do
      @client.to_json.should match(/^\{.+\}$/)
    end

    %w{
      name
      public_key
    }.each do |t| 
      it "should include '#{t}'" do
        @serial.should =~ /"#{t}":"#{@client.send(t.to_sym)}"/
      end
    end
  end

  describe "deserialize" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @deserial = JSON.parse(@client.to_json)
    end

    it "should deserialize to a Chef::ApiClient object" do
      @deserial.should be_a_kind_of(Chef::ApiClient)
    end

    %w{
      name
      public_key
    }.each do |t| 
      it "should match '#{t}'" do
        @deserial.send(t.to_sym).should == @client.send(t.to_sym)
      end
    end

  end
end


