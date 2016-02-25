#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require "spec_helper"

describe Chef::Application::Solo do

  let(:app) { Chef::Application::Solo.new }

  before do
    allow(Kernel).to receive(:trap).and_return(:ok)
    allow(app).to receive(:configure_opt_parser).and_return(true)
    allow(app).to receive(:configure_chef).and_return(true)
    allow(app).to receive(:configure_logging).and_return(true)
    allow(app).to receive(:trap)

    Chef::Config[:json_attribs] = false
    Chef::Config[:solo] = true

    # protect the unit tests against accidental --delete-entire-chef-repo from firing
    # for real during tests.  DO NOT delete this line.
    expect(FileUtils).not_to receive(:rm_rf)
  end

  describe "configuring the application" do
    it "should call set_specific_recipes" do
      expect(app).to receive(:set_specific_recipes)
      app.reconfigure
    end

    it "should set solo mode to true" do
      app.reconfigure
      expect(Chef::Config[:solo]).to be_truthy
    end

    it "should set audit-mode to :disabled" do
      app.reconfigure
      expect(Chef::Config[:audit_mode]).to be :disabled
    end

    describe "when configured to not fork the client process" do
      before do
        Chef::Config[:client_fork] = false
        Chef::Config[:daemonize] = false
        Chef::Config[:interval] = nil
        Chef::Config[:splay] = nil
      end

      context "when interval is given" do
        before do
          Chef::Config[:interval] = 600
        end

        it "should terminate with message" do
          expect(Chef::Application).to receive(:fatal!).with(
"Unforked chef-client interval runs are disabled in Chef 12.
Configuration settings:
  interval  = 600 seconds
Enable chef-client interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
          )
          app.reconfigure
        end
      end
    end

    describe "when in daemonized mode and no interval has been set" do
      before do
        Chef::Config[:daemonize] = true
      end

      it "should set the interval to 1800" do
        Chef::Config[:interval] = nil
        app.reconfigure
        expect(Chef::Config[:interval]).to eq(1800)
      end
    end

    describe "when the json_attribs configuration option is specified" do
      let(:json_attribs) { { "a" => "b" } }
      let(:config_fetcher) { double(Chef::ConfigFetcher, :fetch_json => json_attribs) }
      let(:json_source) { "https://foo.com/foo.json" }

      before do
        Chef::Config[:json_attribs] = json_source
        expect(Chef::ConfigFetcher).to receive(:new).with(json_source).
          and_return(config_fetcher)
      end

      it "reads the JSON attributes from the specified source" do
        app.reconfigure
        expect(app.chef_client_json).to eq(json_attribs)
      end
    end

    it "downloads a tarball when the recipe_url configuration option is specified" do
      Chef::Config[:cookbook_path] = "#{Dir.tmpdir}/chef-solo/cookbooks"
      Chef::Config[:recipe_url] = "http://junglist.gen.nz/recipes.tgz"

      expect(FileUtils).to receive(:mkdir_p).with("#{Dir.tmpdir}/chef-solo").and_return(true)

      tarfile = StringIO.new("remote_tarball_content")
      target_file = StringIO.new

      expect(app).to receive(:open).with("http://junglist.gen.nz/recipes.tgz").and_yield(tarfile)
      expect(File).to receive(:open).with("#{Dir.tmpdir}/chef-solo/recipes.tgz", "wb").and_yield(target_file)

      shellout = instance_double("Mixlib::ShellOut", run_command: nil, error!: nil, stdout: "")

      expect(app).to receive(:shell_out!).with("tar zxvf #{Dir.tmpdir}/chef-solo/recipes.tgz -C #{Dir.tmpdir}/chef-solo").and_return(shellout)
      app.reconfigure
      expect(target_file.string).to eq("remote_tarball_content")
    end

    it "fetches the recipe_url first when both json_attribs and recipe_url are specified" do
      json_attribs = { "a" => "b" }
      config_fetcher = instance_double("Chef::ConfigFetcher", :fetch_json => json_attribs)

      Chef::Config[:json_attribs] = "https://foo.com/foo.json"
      Chef::Config[:recipe_url] = "http://icanhas.cheezburger.com/lolcats"
      Chef::Config[:cookbook_path] = "#{Dir.tmpdir}/chef-solo/cookbooks"
      expect(FileUtils).to receive(:mkdir_p).with("#{Dir.tmpdir}/chef-solo").and_return(true)

      allow(Chef::Mixin::Command).to receive(:run_command).and_return(true)

      shellout = instance_double("Mixlib::ShellOut", run_command: nil, error!: nil, stdout: "")

      expect(app).to receive(:shell_out!).with("tar zxvf #{Dir.tmpdir}/chef-solo/recipes.tgz -C #{Dir.tmpdir}/chef-solo").and_return(shellout)
      expect(app).to receive(:fetch_recipe_tarball).ordered
      expect(Chef::ConfigFetcher).to receive(:new).ordered.and_return(config_fetcher)
      app.reconfigure
    end
  end

  describe "after the application has been configured" do
    before do
      Chef::Config[:solo] = true

      allow(Chef::Daemon).to receive(:change_privilege)
      chef_client = double("Chef::Client")
      allow(Chef::Client).to receive(:new).and_return(chef_client)
      # this is all stuff the reconfigure method needs
      allow(app).to receive(:configure_opt_parser).and_return(true)
      allow(app).to receive(:configure_chef).and_return(true)
      allow(app).to receive(:configure_logging).and_return(true)
    end

    it "should change privileges" do
      expect(Chef::Daemon).to receive(:change_privilege).and_return(true)
      app.setup_application
    end
  end

  it_behaves_like "an application that loads a dot d" do
    let(:dot_d_config_name) { :solo_d_dir }
  end
end
