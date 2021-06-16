#
# Copyright 2018, Noah Kantrowitz
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "support/shared/context/config"

describe "knife config show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:cmd_args) { [] }

  when_the_repository("has a custom env") do
    subject do
      cmd = knife("config", "show", *cmd_args, instance_filter: lambda { |instance|
        # Clear the stub set up in KnifeSupport.
        allow(File).to receive(:file?).and_call_original
        # Lies, damn lies, and config files. We need to allow normal config loading
        # behavior to be able to test stuff.
        instance.config.delete(:config_file)
        $__KNIFE_INTEGRATION_FAILSAFE_CHECK << " ole"
      })
      cmd.stdout
    end

    around do |ex|
      # Store and reset the value of some env vars.
      old_chef_home = ENV["CHEF_HOME"]
      old_knife_home = ENV["KNIFE_HOME"]
      old_home = ENV["HOME"]
      old_wd = Dir.pwd
      ChefConfig::PathHelper.per_tool_home_environment = "KNIFE_HOME"
      # Clear these out because they are cached permanently.
      ChefConfig::PathHelper.class_exec { remove_class_variable(:@@home_dir) }
      Chef::Knife::ConfigShow.reset_config_loader!
      begin
        ex.run
      ensure
        ENV["CHEF_HOME"] = old_chef_home
        ENV["KNIFE_HOME"] = old_knife_home
        ENV["HOME"] = old_home
        Dir.chdir(old_wd)
        ENV[ChefUtils.windows? ? "CD" : "PWD"] = Dir.pwd
        ChefConfig::PathHelper.per_tool_home_environment = nil
      end
    end

    before do
      # Always run from the temp folder. This can't be in the `around` block above
      # because it has to run after the before set in the "with a chef repo" shared context.
      directory("repo")
      Dir.chdir(path_to("repo"))
      ENV[ChefUtils.windows? ? "CD" : "PWD"] = Dir.pwd
      ENV["HOME"] = path_to(".")
    end

    context "with a global knife.rb" do
      before { file(".chef/knife.rb", "node_name 'one'\n") }

      it { is_expected.to match(%r{^Loading from configuration file .*/#{File.basename(path_to("."))}/.chef/knife.rb$}) }
      it { is_expected.to match(/^node_name:\s+one$/) }
    end

    context "with a repo knife.rb" do
      before { file("repo/.chef/knife.rb", "node_name 'two'\n") }

      it { is_expected.to match(%r{^Loading from configuration file .*/#{File.basename(path_to("."))}/repo/.chef/knife.rb$}) }
      it { is_expected.to match(/^node_name:\s+two$/) }
    end

    context "with both knife.rb" do
      before do
        file(".chef/knife.rb", "node_name 'one'\n")
        file("repo/.chef/knife.rb", "node_name 'two'\n")
      end

      it { is_expected.to match(%r{^Loading from configuration file .*/#{File.basename(path_to("."))}/repo/.chef/knife.rb$}) }
      it { is_expected.to match(/^node_name:\s+two$/) }
    end

    context "with a credentials file" do
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { is_expected.to match(%r{^Loading from credentials file .*/#{File.basename(path_to("."))}/.chef/credentials$}) }
      it { is_expected.to match(/^node_name:\s+three$/) }
    end

    context "with a credentials file and knife.rb" do
      before do
        file(".chef/knife.rb", "node_name 'one'\n")
        file(".chef/credentials", "[default]\nclient_name = \"three\"\n")
      end

      it { is_expected.to match(%r{^Loading from configuration file .*/#{File.basename(path_to("."))}/.chef/knife.rb$}) }
      it { is_expected.to match(%r{^Loading from credentials file .*/#{File.basename(path_to("."))}/.chef/credentials$}) }
      it { is_expected.to match(/^node_name:\s+one$/) }
    end

    context "with a config dot d files" do
      before { file(".chef/config.d/abc.rb", "node_name 'one'\n") }

      it { is_expected.to match(%r{^Loading from .d/ configuration file .*/#{File.basename(path_to("."))}/.chef/config.d/abc.rb$}) }
      it { is_expected.to match(/^node_name:\s+one$/) }
    end

    context "with a credentials file and CHEF_HOME" do
      before do
        file(".chef/credentials", "[default]\nclient_name = \"three\"\n")
        file("foo/.chef/credentials", "[default]\nclient_name = \"four\"\n")
        ENV["CHEF_HOME"] = path_to("foo")
      end

      it { is_expected.to match(%r{^Loading from credentials file .*/#{File.basename(path_to("."))}/foo/.chef/credentials$}) }
      it { is_expected.to match(/^node_name:\s+four$/) }
    end

    context "with a credentials file and KNIFE_HOME" do
      before do
        file(".chef/credentials", "[default]\nclient_name = \"three\"\n")
        file("bar/.chef/credentials", "[default]\nclient_name = \"four\"\n")
        ENV["KNIFE_HOME"] = path_to("bar")
      end

      it { is_expected.to match(%r{^Loading from credentials file .*/#{File.basename(path_to("."))}/bar/.chef/credentials$}) }
      it { is_expected.to match(/^node_name:\s+four$/) }
    end

    context "with single argument" do
      let(:cmd_args) { %w{node_name} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { is_expected.to match(/^node_name:\s+three\Z/) }
    end

    context "with two arguments" do
      let(:cmd_args) { %w{node_name client_key} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\nclient_key = \"three.pem\"") }

      it { is_expected.to match(%r{^client_key:\s+\S*/.chef/three.pem\nnode_name:\s+three\Z}) }
    end

    context "with a dotted argument" do
      let(:cmd_args) { %w{knife.ssh_user} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n[default.knife]\nssh_user = \"foo\"\n") }

      it { is_expected.to match(/^knife.ssh_user:\s+foo\Z/) }
    end

    context "with regex argument" do
      let(:cmd_args) { %w{/name/} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { is_expected.to match(/^node_name:\s+three\Z/) }
    end

    context "with --all" do
      let(:cmd_args) { %w{-a /key_contents/} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { is_expected.to match(/^client_key_contents:\s+\nvalidation_key_contents:\s+\Z/) }
    end

    context "with --raw" do
      let(:cmd_args) { %w{-r node_name} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { is_expected.to eq("three\n") }
    end

    context "with --format=json" do
      let(:cmd_args) { %w{--format=json node_name} }
      before { file(".chef/credentials", "[default]\nclient_name = \"three\"\n") }

      it { expect(JSON.parse(subject)).to eq({ "node_name" => "three" }) }
    end
  end
end
