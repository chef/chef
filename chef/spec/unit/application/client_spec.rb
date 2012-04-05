#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require 'spec_helper'

describe Chef::Application::Client, "reconfigure" do
  before do
    @original_config = Chef::Config.configuration

    @app = Chef::Application::Client.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config[:json_attribs] = nil
    Chef::Config[:interval] = 10
    Chef::Config[:splay] = nil

    Chef::Config[:once] = false
  end

  after do
    Chef::Config.configuration.replace(@original_config)
  end

  describe "when in daemonized mode and no interval has been set" do
    before do
      Chef::Config[:daemonize] = true
      Chef::Config[:interval] = nil
    end

    it "should set the interval to 1800" do
      @app.reconfigure
      Chef::Config.interval.should == 1800
    end
  end

  describe "when configured to run once" do
    before do
      Chef::Config[:once] = true
      Chef::Config[:daemonize] = false
      Chef::Config[:splay] = 60
      Chef::Config[:interval] = 1800
    end

    it "ignores the splay" do
      @app.reconfigure
      Chef::Config.splay.should be_nil
    end

    it "forces the interval to nil" do
      @app.reconfigure
      Chef::Config.interval.should be_nil
    end

  end

  describe "when the json_attribs configuration option is specified" do

    describe "and the json_attribs matches a HTTP regex" do
      before do
        @json = StringIO.new({:a=>"b"}.to_json)
        @json_tempfile = mock("Tempfile for remote JSON", :open => @json)
        @rest = mock("Chef::REST", :get_rest => @json_tempfile)

        Chef::Config[:json_attribs] = "https://foo.com/foo.json"
        Chef::REST.stub!(:new).with("https://foo.com/foo.json", nil, nil).and_return(@rest)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
      end

      it "should perform a RESTful GET on the supplied URL" do
        @app.reconfigure
        @app.chef_client_json.should == {"a" => "b"}
      end
    end

    describe "and the json_attribs does not match the HTTP regex" do
      before do
        Chef::Config[:json_attribs] = "/etc/chef/dna.json"
        @json = StringIO.new({:a=>"b"}.to_json)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
      end

      it "should parse the json out of the file" do
        @app.reconfigure
        @app.chef_client_json.should == {"a" => "b"}
      end
    end

    describe "when parsing fails" do
      before do
        Chef::Config[:json_attribs] = "/etc/chef/dna.json"
        @json = mock("Tempfile", :read => {:a=>"b"}.to_json)
        @app.stub!(:open).with("/etc/chef/dna.json").and_return(@json)
        Chef::JSONCompat.stub!(:from_json).with(@json.read).and_raise(JSON::ParserError)
        Chef::Application.stub!(:fatal!).and_return(true)
      end

      it "should hard fail the application" do
        Chef::Application.should_receive(:fatal!).with("Could not parse the provided JSON file (/etc/chef/dna.json)!: JSON::ParserError", 2).and_return(true)
        @app.reconfigure
      end
    end
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    @app = Chef::Application::Client.new
    # this is all stuff the reconfigure method needs
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
  end

  it "should change privileges" do
    Chef::Daemon.should_receive(:change_privilege).and_return(true)
    @app.setup_application
  end
  after do
    Chef::Config[:solo] = false
  end
end
