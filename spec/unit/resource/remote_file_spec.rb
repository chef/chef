#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::RemoteFile do

  before(:each) do
    @resource = Chef::Resource::RemoteFile.new("fakey_fakerton")
  end

  describe "initialize" do
    it "should create a new Chef::Resource::RemoteFile" do
      expect(@resource).to be_a_kind_of(Chef::Resource)
      expect(@resource).to be_a_kind_of(Chef::Resource::File)
      expect(@resource).to be_a_kind_of(Chef::Resource::RemoteFile)
    end
  end

  it "says its provider is RemoteFile when the source is an absolute URI" do
    @resource.source("http://www.google.com/robots.txt")
    expect(@resource.provider).to eq(Chef::Provider::RemoteFile)
    expect(@resource.provider_for_action(:create)).to be_kind_of(Chef::Provider::RemoteFile)
  end

  it "says its provider is RemoteFile when the source is a network share" do
    @resource.source("\\\\fakey\\fakerton\\fake.txt")
    expect(@resource.provider).to eq(Chef::Provider::RemoteFile)
    expect(@resource.provider_for_action(:create)).to be_kind_of(Chef::Provider::RemoteFile)
  end

  describe "source" do
    it "does not have a default value for 'source'" do
      expect(@resource.source).to eql([])
    end

    it "should accept a URI for the remote file source" do
      @resource.source "http://opscode.com/"
      expect(@resource.source).to eql([ "http://opscode.com/" ])
    end

    it "should accept a windows network share source" do
      @resource.source "\\\\fakey\\fakerton\\fake.txt"
      expect(@resource.source).to eql([ "\\\\fakey\\fakerton\\fake.txt" ])
    end

    it "should accept file URIs with spaces" do
      @resource.source("file:///C:/foo bar")
      expect(@resource.source).to eql(["file:///C:/foo bar"])
    end

    it "should accept a delayed evalutator (string) for the remote file source" do
      @resource.source Chef::DelayedEvaluator.new { "http://opscode.com/" }
      expect(@resource.source).to eql([ "http://opscode.com/" ])
    end

    it "should accept an array of URIs for the remote file source" do
      @resource.source([ "http://opscode.com/", "http://puppetlabs.com/" ])
      expect(@resource.source).to eql([ "http://opscode.com/", "http://puppetlabs.com/" ])
    end

    it "should accept a delated evaluator (array) for the remote file source" do
      @resource.source Chef::DelayedEvaluator.new { [ "http://opscode.com/", "http://puppetlabs.com/" ] }
      expect(@resource.source).to eql([ "http://opscode.com/", "http://puppetlabs.com/" ])
    end

    it "should accept an multiple URIs as arguments for the remote file source" do
      @resource.source("http://opscode.com/", "http://puppetlabs.com/")
      expect(@resource.source).to eql([ "http://opscode.com/", "http://puppetlabs.com/" ])
    end

    it "should only accept a single argument if a delayed evalutor is used" do
      expect do
        @resource.source("http://opscode.com/", Chef::DelayedEvaluator.new { "http://opscode.com/" })
      end.to raise_error(Chef::Exceptions::InvalidRemoteFileURI)
    end

    it "should only accept a single array item if a delayed evalutor is used" do
      expect do
        @resource.source(["http://opscode.com/", Chef::DelayedEvaluator.new { "http://opscode.com/" }])
      end.to raise_error(Chef::Exceptions::InvalidRemoteFileURI)
    end

    it "does not accept a non-URI as the source" do
      expect { @resource.source("not-a-uri") }.to raise_error(Chef::Exceptions::InvalidRemoteFileURI)
    end

    it "does not accept a non-URI as the source when read from a delayed evaluator" do
      expect do
        @resource.source(Chef::DelayedEvaluator.new { "not-a-uri" })
        @resource.source
      end.to raise_error(Chef::Exceptions::InvalidRemoteFileURI)
    end

    it "should raise an exception when source is an empty array" do
      expect { @resource.source([]) }.to raise_error(ArgumentError)
    end

  end

  describe "checksum" do
    it "should accept a string for the checksum object" do
      @resource.checksum "asdf"
      expect(@resource.checksum).to eql("asdf")
    end

    it "should default to nil" do
      expect(@resource.checksum).to eq(nil)
    end
  end

  describe "ftp_active_mode" do
    it "should accept a boolean for the ftp_active_mode object" do
      @resource.ftp_active_mode true
      expect(@resource.ftp_active_mode).to be_truthy
    end

    it "should default to false" do
      expect(@resource.ftp_active_mode).to be_falsey
    end
  end

  describe "conditional get options" do
    it "defaults to using etags and last modified" do
      expect(@resource.use_etags).to be_truthy
      expect(@resource.use_last_modified).to be_truthy
    end

    it "enable or disables etag and last modified options as a group" do
      @resource.use_conditional_get(false)
      expect(@resource.use_etags).to be_falsey
      expect(@resource.use_last_modified).to be_falsey

      @resource.use_conditional_get(true)
      expect(@resource.use_etags).to be_truthy
      expect(@resource.use_last_modified).to be_truthy
    end

    it "disables etags indivdually" do
      @resource.use_etags(false)
      expect(@resource.use_etags).to be_falsey
      expect(@resource.use_last_modified).to be_truthy
    end

    it "disables last modified individually" do
      @resource.use_last_modified(false)
      expect(@resource.use_last_modified).to be_falsey
      expect(@resource.use_etags).to be_truthy
    end

  end

  describe "when it has group, mode, owner, source, and checksum" do
    before do
      if Chef::Platform.windows?
        @resource.path("C:/temp/origin/file.txt")
        @resource.rights(:read, "Everyone")
        @resource.deny_rights(:full_control, "Clumsy_Sam")
      else
        @resource.path("/this/path/")
        @resource.group("pokemon")
        @resource.mode("0664")
        @resource.owner("root")
      end
      @resource.source("https://www.google.com/images/srpr/logo3w.png")
      @resource.checksum("1" * 26)
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      if Chef::Platform.windows?
        puts state
        expect(state[:rights]).to eq([{ :permissions => :read, :principals => "Everyone" }])
        expect(state[:deny_rights]).to eq([{ :permissions => :full_control, :principals => "Clumsy_Sam" }])
      else
        expect(state[:group]).to eq("pokemon")
        expect(state[:mode]).to eq("0664")
        expect(state[:owner]).to eq("root")
        expect(state[:checksum]).to eq("1" * 26)
      end
    end

    it "returns the path as its identity" do
      if Chef::Platform.windows?
        expect(@resource.identity).to eq("C:/temp/origin/file.txt")
      else
        expect(@resource.identity).to eq("/this/path/")
      end
    end
  end
end
