#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"

require "chef/knife/rehash"
require "chef/knife/core/subcommand_loader"

describe "knife rehash" do
  before do
    allow(Chef::Knife::SubcommandLoader).to receive(:load_commands)
  end

  after do
    # We need to clean up the generated manifest or else is messes with later tests
    FileUtils.rm_f(Chef::Knife::SubcommandLoader.plugin_manifest_path)
  end

  it "writes the loaded plugins to disc" do
    knife_rehash = Chef::Knife::Rehash.new
    knife_rehash.run
    expect(File.read(Chef::Knife::SubcommandLoader.plugin_manifest_path)).to match(/node_list.rb/)
  end
end
