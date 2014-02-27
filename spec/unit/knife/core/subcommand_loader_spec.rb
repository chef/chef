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
