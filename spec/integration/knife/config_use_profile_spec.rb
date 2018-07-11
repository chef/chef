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

require "support/shared/integration/integration_helper"
require "support/shared/context/config"

describe "knife config use-profile", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"
  include_context "with a chef repo"

  let(:cmd_args) { [] }

  let(:knife_use_profile) do
    knife("config", "use-profile", *cmd_args, instance_filter: lambda { |instance|
      # Fake the failsafe check because this command doesn't actually process knife.rb.
      $__KNIFE_INTEGRATION_FAILSAFE_CHECK << " ole"
    })
  end

  subject { knife_use_profile.stdout }

  around do |ex|
    # Store and reset the value of some env vars.
    old_chef_home = ENV["CHEF_HOME"]
    old_knife_home = ENV["KNIFE_HOME"]
    old_home = ENV["HOME"]
    old_wd = Dir.pwd
    ChefConfig::PathHelper.per_tool_home_environment = "KNIFE_HOME"
    # Clear these out because they are cached permanently.
    ChefConfig::PathHelper.class_exec { remove_class_variable(:@@home_dir) }
    Chef::Knife::ConfigUseProfile.reset_config_loader!
    begin
      ex.run
    ensure
      ENV["CHEF_HOME"] = old_chef_home
      ENV["KNIFE_HOME"] = old_knife_home
      ENV["HOME"] = old_home
      Dir.chdir(old_wd)
      ENV[ChefConfig.windows? ? "CD" : "PWD"] = Dir.pwd
      ChefConfig::PathHelper.per_tool_home_environment = nil
    end
  end

  before do
    # Always run from the temp folder. This can't be in the `around` block above
    # because it has to run after the before set in the "with a chef repo" shared context.
    directory("repo")
    Dir.chdir(path_to("repo"))
    ENV[ChefConfig.windows? ? "CD" : "PWD"] = Dir.pwd
    ENV["HOME"] = path_to(".")
  end

  context "with no argument" do
    subject { knife_use_profile.stderr }
    it { is_expected.to eq "FATAL: You must specify a profile\n" }
  end

  context "with an argument" do
    let(:cmd_args) { %w{production} }
    it do
      is_expected.to eq "Set default profile to production\n"
      expect(File.read(path_to(".chef/context"))).to eq "production\n"
    end
  end

  context "with $CHEF_HOME" do
    let(:cmd_args) { %w{staging} }
    before { ENV["CHEF_HOME"] = path_to("chefhome"); file("chefhome/tmp", "") }
    it do
      is_expected.to eq "Set default profile to staging\n"
      expect(File.read(path_to("chefhome/.chef/context"))).to eq "staging\n"
      expect(File.exist?(path_to(".chef/context"))).to be_falsey
    end
  end

  context "with $KNIFE_HOME" do
    let(:cmd_args) { %w{development} }
    before { ENV["KNIFE_HOME"] = path_to("knifehome"); file("knifehome/tmp", "") }
    it do
      is_expected.to eq "Set default profile to development\n"
      expect(File.read(path_to("knifehome/.chef/context"))).to eq "development\n"
      expect(File.exist?(path_to(".chef/context"))).to be_falsey
    end
  end
end
