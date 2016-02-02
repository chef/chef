#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"

describe "lib-backcompat" do
  it "require 'chef/chef_fs/file_system/chef_server_root_dir' yields the proper class" do
    require "chef/chef_fs/file_system/chef_server_root_dir"
    expect(Chef::ChefFS::FileSystem::ChefServerRootDir).to eq(Chef::ChefFS::FileSystem::ChefServer::ChefServerRootDir)
  end
  it "require 'chef/chef_fs/file_system/chef_repository_file_system_root_dir' yields the proper class" do
    require "chef/chef_fs/file_system/chef_repository_file_system_root_dir"
    expect(Chef::ChefFS::FileSystem::ChefRepositoryFileSystemRootDir).to eq(Chef::ChefFS::FileSystem::Repository::ChefRepositoryFileSystemRootDir)
  end
  it "require 'chef/chef_fs/file_system/acl_entry' yields the proper class" do
    require "chef/chef_fs/file_system/acl_entry"
    expect(Chef::ChefFS::FileSystem::AclEntry).to eq(Chef::ChefFS::FileSystem::ChefServer::AclEntry)
  end
end
