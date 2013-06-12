#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

describe Chef::FileContentManagement::Deploy::Cp do

  let(:content_deployer) { described_class.new }
  let(:target_file_path) { "/etc/my_app.conf" }

  describe "creating the file" do

    it "touches the file to create it" do
      FileUtils.should_receive(:touch).with(target_file_path)
      content_deployer.create(target_file_path)
    end
  end

  describe "updating the file" do

    let(:staging_file_path) { "/tmp/random-dir/staging-file.tmp" }

    it "copies the staging file's content" do
      FileUtils.should_receive(:cp).with(staging_file_path, target_file_path)
      content_deployer.deploy(staging_file_path, target_file_path)
    end

  end
end


