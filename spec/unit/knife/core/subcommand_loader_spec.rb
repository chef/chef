#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

describe Chef::Knife::SubcommandLoader do
  before do

    @home = File.join(CHEF_SPEC_DATA, 'knife-home')
    @env = {'HOME' => @home}
    @loader = Chef::Knife::SubcommandLoader.new(File.join(CHEF_SPEC_DATA, 'knife-site-subcommands'), @env)
  end

  it "builds a list of the core subcommand file require paths" do
    @loader.subcommand_files.should_not be_empty
    @loader.subcommand_files.each do |require_path|
      require_path.should match(/chef\/knife\/.*|plugins\/knife\/.*/)
    end
  end

  it "finds files installed via rubygems" do
    @loader.find_subcommands_via_rubygems.should include('chef/knife/node_create')
    @loader.find_subcommands_via_rubygems.each {|rel_path, abs_path| abs_path.should match(%r[chef/knife/.+])}
  end

  it "finds files from latest version of installed gems" do
    gems = [ double('knife-ec2-0.5.12') ]
    gem_files = [
      '/usr/lib/ruby/gems/knife-ec2-0.5.12/lib/chef/knife/ec2_base.rb',
      '/usr/lib/ruby/gems/knife-ec2-0.5.12/lib/chef/knife/ec2_otherstuff.rb'
    ]
    $LOAD_PATH.should_receive(:map).and_return([])
    if Gem::Specification.respond_to? :latest_specs
      Gem::Specification.should_receive(:latest_specs).with(true).and_return(gems)
      gems[0].should_receive(:matches_for_glob).with(/chef\/knife\/\*\.rb\{(.*),\.rb,(.*)\}/).and_return(gem_files)
    else
      Gem.source_index.should_receive(:latest_specs).with(true).and_return(gems)
      gems[0].should_receive(:require_paths).twice.and_return(['lib'])
      gems[0].should_receive(:full_gem_path).and_return('/usr/lib/ruby/gems/knife-ec2-0.5.12')
      Dir.should_receive(:[]).with('/usr/lib/ruby/gems/knife-ec2-0.5.12/lib/chef/knife/*.rb').and_return(gem_files)
    end
    @loader.should_receive(:find_subcommands_via_dirglob).and_return({})
    @loader.find_subcommands_via_rubygems.values.select { |file| file =~ /knife-ec2/ }.sort.should == gem_files
  end

  it "finds files using a dirglob when rubygems is not available" do
    @loader.find_subcommands_via_dirglob.should include('chef/knife/node_create')
    @loader.find_subcommands_via_dirglob.each {|rel_path, abs_path| abs_path.should match(%r[chef/knife/.+])}
  end

  it "finds user-specific subcommands in the user's ~/.chef directory" do
    expected_command = File.join(@home, '.chef', 'plugins', 'knife', 'example_home_subcommand.rb')
    @loader.site_subcommands.should include(expected_command)
  end

  it "finds repo specific subcommands by searching for a .chef directory" do
    expected_command = File.join(CHEF_SPEC_DATA, 'knife-site-subcommands', 'plugins', 'knife', 'example_subcommand.rb')
    @loader.site_subcommands.should include(expected_command)
  end

  # https://github.com/opscode/chef-dk/issues/227
  #
  # `knife` in ChefDK isn't from a gem install, it's directly run from a clone
  # of the source, but there can be one or more versions of chef also installed
  # as a gem. If the gem install contains a command that doesn't exist in the
  # source tree of the "primary" chef install, it can be loaded and cause an
  # error. We also want to ensure that we only load builtin commands from the
  # "primary" chef install.
  context "when a different version of chef is also installed as a gem" do

    let(:all_found_commands) do
      [
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/bootstrap.rb",
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/client_bulk_delete.rb",
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/client_create.rb",
        # We use the fake version 1.0.0 because that version doesn't exist,
        # which ensures it won't ever equal "chef-#{Chef::VERSION}"
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-1.0.0/lib/chef/knife/bootstrap.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-1.0.0/lib/chef/knife/client_bulk_delete.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-1.0.0/lib/chef/knife/client_create.rb",
        # This command is "extra" compared to what's in the embedded/apps/chef install:
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-1.0.0/lib/chef/knife/data_bag_secret_options.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-vault-2.2.4/lib/chef/knife/decrypt.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/knife-spork-1.4.1/lib/chef/knife/spork-bump.rb",
        # These are fake commands that have names designed to test that the
        # regex is strict enough
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-foo-#{Chef::VERSION}/lib/chef/knife/chef-foo.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/foo-chef-#{Chef::VERSION}/lib/chef/knife/foo-chef.rb",
        # In a real scenario, we'd use rubygems APIs to only select the most
        # recent gem, but for this test we want to check that we're doing the
        # right thing both when the plugin version matches and does not match
        # the current chef version. Looking at
        # `SubcommandLoader::MATCHES_THIS_CHEF_GEM` and
        # `SubcommandLoader::MATCHES_CHEF_GEM` should make it clear why we want
        # to test these two cases.
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-bar-1.0.0/lib/chef/knife/chef-bar.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/bar-chef-1.0.0/lib/chef/knife/bar-chef.rb"
      ]
    end

    let(:expected_valid_commands) do
      [
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/bootstrap.rb",
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/client_bulk_delete.rb",
        "/opt/chefdk/embedded/apps/chef/lib/chef/knife/client_create.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-vault-2.2.4/lib/chef/knife/decrypt.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/knife-spork-1.4.1/lib/chef/knife/spork-bump.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-foo-#{Chef::VERSION}/lib/chef/knife/chef-foo.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/foo-chef-#{Chef::VERSION}/lib/chef/knife/foo-chef.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/chef-bar-1.0.0/lib/chef/knife/chef-bar.rb",
        "/opt/chefdk/embedded/lib/ruby/gems/2.1.0/gems/bar-chef-1.0.0/lib/chef/knife/bar-chef.rb"
      ]
    end

    before do
      expect(@loader).to receive(:find_files_latest_gems).with("chef/knife/*.rb").and_return(all_found_commands)
      expect(@loader).to receive(:find_subcommands_via_dirglob).and_return({})
    end

    it "ignores commands from the non-matching gem install" do
      expect(@loader.find_subcommands_via_rubygems.values).to eq(expected_valid_commands)
    end

  end

  describe "finding 3rd party plugins" do
    let(:env_home) { "/home/alice" }
    let(:manifest_path) { env_home + "/.chef/plugin_manifest.json" }

    before do
      env_dup = ENV.to_hash
      ENV.stub(:[]).and_return { |key| env_dup[key] }
      ENV.stub(:[]).with("HOME").and_return(env_home)
    end

    context "when there is not a ~/.chef/plugin_manifest.json file" do
      before do
        File.stub(:exist?).with(manifest_path).and_return(false)
      end

      it "searches rubygems for plugins" do
        if Gem::Specification.respond_to?(:latest_specs)
          Gem::Specification.should_receive(:latest_specs).and_call_original
        else
          Gem.source_index.should_receive(:latest_specs).and_call_original
        end
        @loader.subcommand_files.each do |require_path|
          require_path.should match(/chef\/knife\/.*|plugins\/knife\/.*/)
        end
      end

      context "and HOME environment variable is not set" do
        before do
          ENV.stub(:[]).with("HOME").and_return(nil)
        end

        it "searches rubygems for plugins" do
          if Gem::Specification.respond_to?(:latest_specs)
            Gem::Specification.should_receive(:latest_specs).and_call_original
          else
            Gem.source_index.should_receive(:latest_specs).and_call_original
          end
          @loader.subcommand_files.each do |require_path|
            require_path.should match(/chef\/knife\/.*|plugins\/knife\/.*/)
          end
        end
      end

    end

    context "when there is a ~/.chef/plugin_manifest.json file" do
      let(:ec2_server_create_plugin) { "/usr/lib/ruby/gems/knife-ec2-0.5.12/lib/chef/knife/ec2_server_create.rb" }

      let(:manifest_content) do
        { "plugins" => {
            "knife-ec2" => {
              "paths" => [
                ec2_server_create_plugin
              ]
            }
          }
        }
      end

      let(:manifest_json) { Chef::JSONCompat.to_json(manifest_content) }

      before do
        File.stub(:exist?).with(manifest_path).and_return(true)
        File.stub(:read).with(manifest_path).and_return(manifest_json)
      end

      it "uses paths from the manifest instead of searching gems" do
        Gem::Specification.should_not_receive(:latest_specs).and_call_original
        @loader.subcommand_files.should include(ec2_server_create_plugin)
      end

    end
  end

end
