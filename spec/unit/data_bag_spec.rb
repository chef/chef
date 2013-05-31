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
require 'chef/data_bag'

describe Chef::DataBag do
  before(:each) do
    @data_bag = Chef::DataBag.new
  end

  describe "initialize" do
    it "should be a Chef::DataBag" do
      @data_bag.should be_a_kind_of(Chef::DataBag)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @data_bag.name("clowns").should == "clowns"
    end

    it "should return the current name" do
      @data_bag.name "clowns"
      @data_bag.name.should == "clowns"
    end

    it "should not accept spaces" do
      lambda { @data_bag.name "clown masters" }.should raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      lambda { @data_bag.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "deserialize" do
    before(:each) do
      @data_bag.name('mars_volta')
      @deserial = Chef::JSONCompat.from_json(@data_bag.to_json)
    end

    it "should deserialize to a Chef::DataBag object" do
      @deserial.should be_a_kind_of(Chef::DataBag)
    end

    %w{
      name
    }.each do |t|
      it "should match '#{t}'" do
        @deserial.send(t.to_sym).should == @data_bag.send(t.to_sym)
      end
    end

  end

  describe "when saving" do 
    before do
      @data_bag.name('piggly_wiggly')
      @rest = mock("Chef::REST")
      Chef::REST.stub!(:new).and_return(@rest)
    end

    it "should update the data bag when it already exists" do
      @rest.should_receive(:put_rest).with("data/piggly_wiggly", @data_bag) 
      @data_bag.save
    end

    it "should create the data bag when it is not found" do 
      exception = mock("404 error", :code => "404")
      @rest.should_receive(:put_rest).and_raise(Net::HTTPServerException.new("foo", exception))
      @rest.should_receive(:post_rest).with("data", @data_bag)
      @data_bag.save
    end 

    describe "when whyrun mode is enabled" do
      before do
        Chef::Config[:why_run] = true
      end
      after do
        Chef::Config[:why_run] = false
      end
      it "should not save" do
        @rest.should_not_receive(:put_rest)
        @rest.should_not_receive(:post_rest)
        @data_bag.save
      end
    end

  end
  describe "when loading" do
    describe "from an API call" do
      before do
        Chef::Config[:chef_server_url] = 'https://myserver.example.com'
        @http_client = mock('Chef::REST')
      end

      it "should get the data bag from the server" do
        Chef::REST.should_receive(:new).with('https://myserver.example.com').and_return(@http_client)
        @http_client.should_receive(:get_rest).with('data/foo')
        Chef::DataBag.load('foo')
      end

      it "should return the data bag" do
        Chef::REST.stub!(:new).and_return(@http_client)
        @http_client.should_receive(:get_rest).with('data/foo').and_return({'bar' => 'https://myserver.example.com/data/foo/bar'})
        data_bag = Chef::DataBag.load('foo')
        data_bag.should == {'bar' => 'https://myserver.example.com/data/foo/bar'}
      end
    end

    describe "in solo mode" do
      before do
        Chef::Config[:solo] = true
        Chef::Config[:data_bag_path] = '/var/chef/data_bags'
      end

      after do
        Chef::Config[:solo] = false
      end

      it "should get the data bag from the data_bag_path" do
        File.should_receive(:directory?).with('/var/chef/data_bags').and_return(true)
        Dir.should_receive(:glob).with('/var/chef/data_bags/foo/*.json').and_return([])
        Chef::DataBag.load('foo')
      end

      it "should get the data bag from the data_bag_path by symbolic name" do
        File.should_receive(:directory?).with('/var/chef/data_bags').and_return(true)
        Dir.should_receive(:glob).with('/var/chef/data_bags/foo/*.json').and_return([])
        Chef::DataBag.load(:foo)
      end

      it "should return the data bag" do
        File.should_receive(:directory?).with('/var/chef/data_bags').and_return(true)
        Dir.stub!(:glob).and_return(["/var/chef/data_bags/foo/bar.json", "/var/chef/data_bags/foo/baz.json"])
        IO.should_receive(:read).with('/var/chef/data_bags/foo/bar.json').and_return('{"id": "bar", "name": "Bob Bar" }')
        IO.should_receive(:read).with('/var/chef/data_bags/foo/baz.json').and_return('{"id": "baz", "name": "John Baz" }')
        data_bag = Chef::DataBag.load('foo')
        data_bag.should == { 'bar' => { 'id' => 'bar', 'name' => 'Bob Bar' }, 'baz' => { 'id' => 'baz', 'name' => 'John Baz' }}
      end

      it "should return the data bag list" do
        File.should_receive(:directory?).with('/var/chef/data_bags').and_return(true)
        Dir.should_receive(:glob).and_return(["/var/chef/data_bags/foo", "/var/chef/data_bags/bar"])
        data_bag_list = Chef::DataBag.list
        data_bag_list.should == { 'bar' => 'bar', 'foo' => 'foo' }
      end

      it 'should raise an error if the configured data_bag_path is invalid' do
        File.should_receive(:directory?).with('/var/chef/data_bags').and_return(false)

        lambda {
          Chef::DataBag.load('foo')
        }.should raise_error Chef::Exceptions::InvalidDataBagPath, "Data bag path '/var/chef/data_bags' is invalid"
      end

    end
  end

end
