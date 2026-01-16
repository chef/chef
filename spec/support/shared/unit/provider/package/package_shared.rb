#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

shared_examples_for "given a response file" do
  let(:cookbook_repo) { File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) }
  let(:cookbook_loader) do
    Chef::Cookbook::FileVendor.fetch_from_disk(cookbook_repo)
    Chef::CookbookLoader.new(cookbook_repo)
  end
  let(:cookbook_collection) do
    cookbook_loader.load_cookbooks
    Chef::CookbookCollection.new(cookbook_loader)
  end
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }

  describe "creating the cookbook file resource to fetch the response file" do
    before do
      expect(Chef::FileCache).to receive(:create_cache_path).with(path).and_return(tmp_path)
    end

    it "sets the preseed resource's runcontext to its own run context" do
      cookbook_collection
      allow(Chef::FileCache).to receive(:create_cache_path).and_return(tmp_path)
      expect(@provider.preseed_resource(package_name, package_version).run_context).not_to be_nil
      expect(@provider.preseed_resource(package_name, package_version).run_context).to equal(@provider.run_context)
    end

    it "should set the cookbook name of the remote file to the new resources cookbook name" do
      expect(@provider.preseed_resource(package_name, package_version).cookbook_name).to eq(package_name)
    end

    it "should set remote files source to the new resources response file" do
      expect(@provider.preseed_resource(package_name, package_version).source).to eq(response)
    end

    it "should never back up the cached response file" do
      expect(@provider.preseed_resource(package_name, package_version).backup).to be_falsey
    end

    it "sets the install path of the resource to $file_cache/$cookbook/$pkg_name-$pkg_version.seed" do
      expect(@provider.preseed_resource(package_name, package_version).path).to eq(tmp_preseed_path)
    end
  end

  describe "when installing the preseed file to the cache location" do
    let(:response_file_destination) { Dir.tmpdir + preseed_path }
    let(:response_file_resource) do
      response_file_resource = Chef::Resource::CookbookFile.new(response_file_destination, run_context)
      response_file_resource.cookbook_name = package_name
      response_file_resource.backup(false)
      response_file_resource.source(response)
      response_file_resource
    end

    before do
      expect(@provider).to receive(:preseed_resource).with(package_name, package_version).and_return(response_file_resource)
    end

    after do
      FileUtils.rm(response_file_destination) if ::File.exist?(response_file_destination)
    end

    it "creates the preseed file in the cache" do
      expect(response_file_resource).to receive(:run_action).with(:create)
      @provider.get_preseed_file(package_name, package_version)
    end

    it "returns the path to the response file if the response file was updated" do
      expect(@provider.get_preseed_file(package_name, package_version)).to eq(response_file_destination)
    end

    it "should return false if the response file has not been updated" do
      response_file_resource.updated_by_last_action(false)
      expect(response_file_resource).not_to be_updated_by_last_action
      # don't let the response_file_resource set updated to true
      expect(response_file_resource).to receive(:run_action).with(:create)
      expect(@provider.get_preseed_file(package_name, package_version)).to be(false)
    end
  end
end
