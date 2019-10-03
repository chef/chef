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

describe "knife config list-profiles", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"
  include_context "with a chef repo"

  let(:cmd_args) { [] }
  let(:knife_list_profiles) do
    knife("config", "list-profiles", *cmd_args, instance_filter: proc {
      # Clear the stub set up in KnifeSupport.
      allow(File).to receive(:file?).and_call_original
    })
  end
  subject { knife_list_profiles.stdout }

  around do |ex|
    # Store and reset the value of some env vars.
    old_home = ENV["HOME"]
    old_wd = Dir.pwd
    # Clear these out because they are cached permanently.
    ChefConfig::PathHelper.class_exec { remove_class_variable(:@@home_dir) }
    Chef::Knife::ConfigListProfiles.reset_config_loader!
    begin
      ex.run
    ensure
      ENV["HOME"] = old_home
      Dir.chdir(old_wd)
      ENV[ChefConfig.windows? ? "CD" : "PWD"] = Dir.pwd
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

  # NOTE: The funky formatting with # at the end of the line of some of the
  # output examples are because of how the format strings are built, there is
  # substantial trailing whitespace in most cases which many editors "helpfully" remove.

  context "with no credentials file" do
    subject { knife_list_profiles.stderr }
    it { is_expected.to eq "FATAL: No profiles found, #{path_to(".chef/credentials")} does not exist or is empty\n" }
  end

  context "with an empty credentials file" do
    before { file(".chef/credentials", "") }
    subject { knife_list_profiles.stderr }
    it { is_expected.to eq "FATAL: No profiles found, #{path_to(".chef/credentials")} does not exist or is empty\n" }
  end

  context "with a simple default profile" do
    before { file(".chef/credentials", <<~EOH) }
      [default]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it { is_expected.to eq <<~EOH.delete("#") }
       Profile  Client    Key                  Server                                   #
      ----------------------------------------------------------------------------------#
      *default  testuser  ~/.chef/testkey.pem  https://example.com/organizations/testorg#
    EOH
  end

  context "with multiple profiles" do
    before { file(".chef/credentials", <<~EOH) }
      [default]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/testorg"

      [prod]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/prod"

      [qa]
      client_name = "qauser"
      client_key = "~/src/qauser.pem"
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it { is_expected.to eq <<~EOH.delete("#") }
       Profile  Client    Key                  Server                                   #
      ----------------------------------------------------------------------------------#
      *default  testuser  ~/.chef/testkey.pem  https://example.com/organizations/testorg#
       prod     testuser  ~/.chef/testkey.pem  https://example.com/organizations/prod   #
       qa       qauser    ~/src/qauser.pem     https://example.com/organizations/testorg#
    EOH
  end

  context "with a non-default active profile" do
    let(:cmd_args) { %w{--profile prod} }
    before { file(".chef/credentials", <<~EOH) }
      [default]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/testorg"

      [prod]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/prod"

      [qa]
      client_name = "qauser"
      client_key = "~/src/qauser.pem"
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it { is_expected.to eq <<~EOH.delete("#") }
       Profile  Client    Key                  Server                                   #
      ----------------------------------------------------------------------------------#
       default  testuser  ~/.chef/testkey.pem  https://example.com/organizations/testorg#
      *prod     testuser  ~/.chef/testkey.pem  https://example.com/organizations/prod   #
       qa       qauser    ~/src/qauser.pem     https://example.com/organizations/testorg#
    EOH
  end

  context "with a minimal profile" do
    before { file(".chef/credentials", <<~EOH) }
      [default]
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it { is_expected.to match %r{^*default .*? https://example.com/organizations/testorg$} }
  end

  context "with -i" do
    let(:cmd_args) { %w{-i} }
    before { file(".chef/credentials", <<~EOH) }
      [default]
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it { is_expected.to eq <<~EOH.delete("#") }
       Profile  Client  Key  Server                                   #
      ----------------------------------------------------------------#
      *default               https://example.com/organizations/testorg#
    EOH
  end

  context "with --format=json" do
    let(:cmd_args) { %w{--format=json node_name} }
    before { file(".chef/credentials", <<~EOH) }
      [default]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/testorg"

      [prod]
      client_name = "testuser"
      client_key = "testkey.pem"
      chef_server_url = "https://example.com/organizations/prod"

      [qa]
      client_name = "qauser"
      client_key = "~/src/qauser.pem"
      chef_server_url = "https://example.com/organizations/testorg"
    EOH
    it {
      expect(JSON.parse(subject)).to eq [
      { "profile" => "default", "active" => true, "client_name" => "testuser", "client_key" => path_to(".chef/testkey.pem"), "server_url" => "https://example.com/organizations/testorg" },
      { "profile" => "prod", "active" => false, "client_name" => "testuser", "client_key" => path_to(".chef/testkey.pem"), "server_url" => "https://example.com/organizations/prod" },
      { "profile" => "qa", "active" => false, "client_name" => "qauser", "client_key" => path_to("src/qauser.pem"), "server_url" => "https://example.com/organizations/testorg" },
    ]
    }
  end
end
