#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Knife::CookbookMetadataFromFile do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @src = File.expand_path(File.join(CHEF_SPEC_DATA, "metadata", "quick_start", "metadata.rb"))
    @tgt = File.expand_path(File.join(CHEF_SPEC_DATA, "metadata", "quick_start", "metadata.json"))
    @knife = Chef::Knife::CookbookMetadataFromFile.new
    @knife.name_args = [ @src ]
    allow(@knife).to receive(:to_json_pretty).and_return(true)
    @md = Chef::Cookbook::Metadata.new
    allow(Chef::Cookbook::Metadata).to receive(:new).and_return(@md)
    allow($stdout).to receive(:write)
  end

  after do
    if File.exist?(@tgt)
      File.unlink(@tgt)
    end
  end

  describe "run" do
    it "should print usage and exit when a FILE is not provided" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal).with(/You must specify the FILE./)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should determine cookbook name from path" do
      expect(@md).to receive(:name).with(no_args)
      expect(@md).to receive(:name).with("quick_start")
      @knife.run
    end

    it "should load the metadata source" do
      expect(@md).to receive(:from_file).with(@src)
      @knife.run
    end

    it "should write out the metadata to the correct location" do
      expect(File).to receive(:open).with(@tgt, "w")
      @knife.run
    end

    it "should generate json from the metadata" do
      expect(Chef::JSONCompat).to receive(:to_json_pretty).with(@md)
      @knife.run
    end

  end
end
