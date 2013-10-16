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

describe Chef::Application::Solo do
  before do
    @app = Chef::Application::Solo.new
    @app.stub!(:configure_opt_parser).and_return(true)
    @app.stub!(:configure_chef).and_return(true)
    @app.stub!(:configure_logging).and_return(true)
    Chef::Config[:recipe_url] = false
    Chef::Config[:json_attribs] = false
    Chef::Config[:solo] = true
  end

  describe "configuring the application" do
    it "should set solo mode to true" do
      @app.reconfigure
      Chef::Config[:solo].should be_true
    end

    describe "when in daemonized mode and no interval has been set" do
      before do
        Chef::Config[:daemonize] = true
      end

      it "should set the interval to 1800" do
        Chef::Config[:interval] = nil
        @app.reconfigure
        Chef::Config[:interval].should == 1800
      end
    end

    describe "when the json_attribs configuration option is specified" do

      let(:json_attribs) { {"a" => "b"} }
      let(:config_fetcher) { double(Chef::ConfigFetcher, :fetch_json => json_attribs) }
      let(:json_source) { "https://foo.com/foo.json" }

      before do
        Chef::Config[:json_attribs] = json_source
        Chef::ConfigFetcher.should_receive(:new).with(json_source).
          and_return(config_fetcher)
      end

      it "reads the JSON attributes from the specified source" do
        @app.reconfigure
        @app.chef_solo_json.should == json_attribs
      end
    end



    describe "when the recipe_url configuration option is specified" do
      before do
        Chef::Config[:cookbook_path] = "#{Dir.tmpdir}/chef-solo/cookbooks"
        Chef::Config[:recipe_url] = "http://junglist.gen.nz/recipes.tgz"
        FileUtils.stub!(:mkdir_p).and_return(true)
        @tarfile = StringIO.new("remote_tarball_content")
        @app.stub!(:open).with("http://junglist.gen.nz/recipes.tgz").and_yield(@tarfile)

        @target_file = StringIO.new
        File.stub!(:open).with("#{Dir.tmpdir}/chef-solo/recipes.tgz", "wb").and_yield(@target_file)

        Chef::Mixin::Command.stub!(:run_command).and_return(true)
      end

      it "should create the recipes path based on the parent of the cookbook path" do
        FileUtils.should_receive(:mkdir_p).with("#{Dir.tmpdir}/chef-solo").and_return(true)
        @app.reconfigure
      end

      it "should download the recipes" do
        @app.should_receive(:open).with("http://junglist.gen.nz/recipes.tgz").and_yield(@tarfile)
        @app.reconfigure
      end

      it "should write the recipes to the target path" do
        @app.reconfigure
        @target_file.string.should == "remote_tarball_content"
      end

      it "should untar the target file to the parent of the cookbook path" do
        Chef::Mixin::Command.should_receive(:run_command).with({:command => "tar zxvf #{Dir.tmpdir}/chef-solo/recipes.tgz -C #{Dir.tmpdir}/chef-solo"}).and_return(true)
        @app.reconfigure
      end
    end
  end


  describe "after the application has been configured" do
    before do
      Chef::Config[:solo] = true

      Chef::Daemon.stub!(:change_privilege)
      @chef_client = mock("Chef::Client")
      Chef::Client.stub!(:new).and_return(@chef_client)
      @app = Chef::Application::Solo.new
      # this is all stuff the reconfigure method needs
      @app.stub!(:configure_opt_parser).and_return(true)
      @app.stub!(:configure_chef).and_return(true)
      @app.stub!(:configure_logging).and_return(true)
    end

    it "should change privileges" do
      Chef::Daemon.should_receive(:change_privilege).and_return(true)
      @app.setup_application
    end
  end

end

