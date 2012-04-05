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
end
