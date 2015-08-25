#
# Copyright:: Copyright (c) 2015 Chef Software, Inc
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

describe Chef::Knife::SubcommandLoader::CustomManifestLoader do
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
  let(:loader) do
    Chef::Knife::SubcommandLoader::CustomManifestLoader.new(File.join(CHEF_SPEC_DATA, 'knife-site-subcommands'),
                                                            manifest_content)
  end

  it "uses paths from the manifest instead of searching gems" do
    expect(Gem::Specification).not_to receive(:latest_specs).and_call_original
    expect(loader.subcommand_files).to include(ec2_server_create_plugin)
  end
end
