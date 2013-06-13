#
# Author:: John Keiser (<jkeiser@opscode.com>)
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

require 'support/shared/integration/integration_helper'
require 'chef/knife/list'
require 'chef/knife/show'

describe 'chef_repo_path tests' do
  extend IntegrationSupport
  include KnifeSupport

  # TODO alternate repo_path / *_path
  context 'alternate *_path' do
    when_the_repository 'has clients and clients2, cookbooks and cookbooks2, etc.' do
      file 'clients/client1.json', {}
      file 'cookbooks/cookbook1/metadata.rb', ''
      file 'data_bags/bag/item.json', {}
      file 'environments/env1.json', {}
      file 'nodes/node1.json', {}
      file 'roles/role1.json', {}
      file 'users/user1.json', {}

      file 'clients2/client2.json', {}
      file 'cookbooks2/cookbook2/metadata.rb', ''
      file 'data_bags2/bag2/item2.json', {}
      file 'environments2/env2.json', {}
      file 'nodes2/node2.json', {}
      file 'roles2/role2.json', {}
      file 'users2/user2.json', {}

      directory 'chef_repo2' do
        file 'clients/client3.json', {}
        file 'cookbooks/cookbook3/metadata.rb', ''
        file 'data_bags/bag3/item3.json', {}
        file 'environments/env3.json', {}
        file 'nodes/node3.json', {}
        file 'roles/role3.json', {}
        file 'users/user3.json', {}
      end

      context 'when all _paths are set to alternates' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client2.json
cookbooks/
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env2.json
nodes/
nodes/node2.json
roles/
roles/role2.json
users/
users/user2.json
EOM
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag2/
bag2/item2.json
EOM
          end
          it 'knife list --local -Rfp ../roles lists roles' do
            knife('list --local -Rfp ../roles').should_succeed "/roles/role2.json\n"
          end
        end
      end

      context 'when all _paths except chef_repo_path are set to alternates' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
          end
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client2.json
cookbooks/
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env2.json
nodes/
nodes/node2.json
roles/
roles/role2.json
users/
users/user2.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag2/
bag2/item2.json
EOM
          end
        end
      end

      context 'when only chef_repo_path is set to its alternate' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client3.json
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env3.json
nodes/
nodes/node3.json
roles/
roles/role3.json
users/
users/user3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when paths are set to point to both versions of each' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = [
              File.join(Chef::Config.chef_repo_path, "#{object_name}s"),
              File.join(Chef::Config.chef_repo_path, "#{object_name}s2")
            ]
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when there is a directory in clients1 and file in clients2 with the same name' do
          directory 'clients/blah.json'
          file 'clients2/blah.json', {}
          it 'knife show /clients/blah.json succeeds' do
            knife('show --local /clients/blah.json').should_succeed <<EOM
/clients/blah.json:
{
}
EOM
          end
        end

        context 'when there is a file in cookbooks1 and directory in cookbooks2 with the same name' do
          file 'cookbooks/blah', ''
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in blah' do
            knife('list --local -Rfp /cookbooks').should_succeed <<EOM
/cookbooks/blah/
/cookbooks/blah/metadata.rb
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is an empty directory in cookbooks1 and a real cookbook in cookbooks2 with the same name' do
          directory 'cookbooks/blah'
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in blah' do
            knife('list --local -Rfp /cookbooks').should_succeed(<<EOM, :stderr => "WARN: Cookbook 'blah' is empty or entirely chefignored at #{Chef::Config.cookbook_path[0]}/blah\n")
/cookbooks/blah/
/cookbooks/blah/metadata.rb
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is a cookbook in cookbooks1 and a cookbook in cookbooks2 with the same name' do
          file 'cookbooks/blah/metadata.json', {}
          file 'cookbooks2/blah/metadata.rb', ''
          it 'knife list -Rfp cookbooks shows files in the first cookbook and not the second' do
            knife('list --local -Rfp /cookbooks').should_succeed(<<EOM, :stderr => "WARN: Child with name 'blah' found in multiple directories: #{Chef::Config.cookbook_path[0]}/blah and #{Chef::Config.cookbook_path[1]}/blah\n")
/cookbooks/blah/
/cookbooks/blah/metadata.json
/cookbooks/cookbook1/
/cookbooks/cookbook1/metadata.rb
/cookbooks/cookbook2/
/cookbooks/cookbook2/metadata.rb
EOM
          end
        end

        context 'when there is a file in data_bags1 and a directory in data_bags2 with the same name' do
          file 'data_bags/blah', ''
          file 'data_bags2/blah/item.json', ''
          it 'knife list -Rfp data_bags shows files in blah' do
            knife('list --local -Rfp /data_bags').should_succeed <<EOM
/data_bags/bag/
/data_bags/bag/item.json
/data_bags/bag2/
/data_bags/bag2/item2.json
/data_bags/blah/
/data_bags/blah/item.json
EOM
          end
        end

        context 'when there is a data bag in data_bags1 and a data bag in data_bags2 with the same name' do
          file 'data_bags/blah/item1.json', ''
          file 'data_bags2/blah/item2.json', ''
          it 'knife list -Rfp data_bags shows only items in data_bags1' do
            knife('list --local -Rfp /data_bags').should_succeed(<<EOM, :stderr => "WARN: Child with name 'blah' found in multiple directories: #{Chef::Config.data_bag_path[0]}/blah and #{Chef::Config.data_bag_path[1]}/blah\n")
/data_bags/bag/
/data_bags/bag/item.json
/data_bags/bag2/
/data_bags/bag2/item2.json
/data_bags/blah/
/data_bags/blah/item1.json
EOM
          end
        end

        context 'when there is a directory in environments1 and file in environments2 with the same name' do
          directory 'environments/blah.json'
          file 'environments2/blah.json', {}
          it 'knife show /environments/blah.json succeeds' do
            knife('show --local /environments/blah.json').should_succeed <<EOM
/environments/blah.json:
{
}
EOM
          end
        end

        context 'when there is a directory in nodes1 and file in nodes2 with the same name' do
          directory 'nodes/blah.json'
          file 'nodes2/blah.json', {}
          it 'knife show /nodes/blah.json succeeds' do
            knife('show --local /nodes/blah.json').should_succeed <<EOM
/nodes/blah.json:
{
}
EOM
          end
        end

        context 'when there is a directory in roles1 and file in roles2 with the same name' do
          directory 'roles/blah.json'
          file 'roles2/blah.json', {}
          it 'knife show /roles/blah.json succeeds' do
            knife('show --local /roles/blah.json').should_succeed <<EOM
/roles/blah.json:
{
}
EOM
          end
        end

        context 'when there is a directory in users1 and file in users2 with the same name' do
          directory 'users/blah.json'
          file 'users2/blah.json', {}
          it 'knife show /users/blah.json succeeds' do
            knife('show --local /users/blah.json').should_succeed <<EOM
/users/blah.json:
{
}
EOM
          end
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag2/
bag2/item2.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client1.json
clients/client2.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook2/
cookbooks/cookbook2/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag2/
data_bags/bag2/item2.json
environments/
environments/env1.json
environments/env2.json
nodes/
nodes/node1.json
nodes/node2.json
roles/
roles/role1.json
roles/role2.json
users/
users/user1.json
users/user2.json
EOM
          end
        end

        context 'when cwd is inside data_bags2' do
          cwd 'data_bags2'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag2/
bag2/item2.json
EOM
          end
        end
      end

      context 'when when chef_repo_path is set to both places and no other _path is set' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.chef_repo_path = [
            Chef::Config.chef_repo_path,
            File.join(Chef::Config.chef_repo_path, 'chef_repo2')
          ]
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client1.json
clients/client3.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
nodes/
nodes/node1.json
nodes/node3.json
roles/
roles/role1.json
roles/role3.json
users/
users/user1.json
users/user3.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client1.json
clients/client3.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
nodes/
nodes/node1.json
nodes/node3.json
roles/
roles/role1.json
roles/role3.json
users/
users/user1.json
users/user3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when cookbook_path is set and nothing else' do
        before :each do
          %w(client data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.cookbook_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2', 'cookbooks')
          Chef::Config.chef_repo_path = nil
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client3.json
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env3.json
nodes/
nodes/node3.json
roles/
roles/role3.json
users/
users/user3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when cookbook_path is set to multiple places and nothing else is set' do
        before :each do
          %w(client data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.cookbook_path = [
            File.join(Chef::Config.chef_repo_path, 'cookbooks'),
            File.join(Chef::Config.chef_repo_path, 'chef_repo2', 'cookbooks')
          ]
          Chef::Config.chef_repo_path = nil
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client1.json
clients/client3.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
nodes/
nodes/node1.json
nodes/node3.json
roles/
roles/role1.json
roles/role3.json
users/
users/user1.json
users/user3.json
EOM
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client1.json
clients/client3.json
cookbooks/
cookbooks/cookbook1/
cookbooks/cookbook1/metadata.rb
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
data_bags/bag3/
data_bags/bag3/item3.json
environments/
environments/env1.json
environments/env3.json
nodes/
nodes/node1.json
nodes/node3.json
roles/
roles/role1.json
roles/role3.json
users/
users/user1.json
users/user3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
bag3/
bag3/item3.json
EOM
          end
        end
      end

      context 'when data_bag_path and chef_repo_path are set, and nothing else' do
        before :each do
          %w(client cookbook  environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.data_bag_path = File.join(Chef::Config.chef_repo_path, 'data_bags')
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'chef_repo2')
        end

        context 'when cwd is at the top level' do
          cwd '.'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp lists data bags' do
            knife('list --local -Rfp').should_succeed <<EOM
bag/
bag/item.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2' do
          cwd 'chef_repo2'
          it 'knife list --local -Rfp lists everything' do
            knife('list --local -Rfp').should_succeed <<EOM
clients/
clients/client3.json
cookbooks/
cookbooks/cookbook3/
cookbooks/cookbook3/metadata.rb
data_bags/
data_bags/bag/
data_bags/bag/item.json
environments/
environments/env3.json
nodes/
nodes/node3.json
roles/
roles/role3.json
users/
users/user3.json
EOM
          end
        end

        context 'when cwd is inside chef_repo2/data_bags' do
          cwd 'chef_repo2/data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Attempt to use relative path '' when current directory is outside the repository path\n")
          end
        end
      end

      context 'when data_bag_path is set and nothing else' do
        before :each do
          %w(client cookbook  environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = nil
          end
          Chef::Config.data_bag_path = File.join(Chef::Config.chef_repo_path, 'data_bags')
          Chef::Config.chef_repo_path = nil
        end

        it 'knife list --local -Rfp / fails' do
          knife('list --local -Rfp /').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
        end

        it 'knife list --local -Rfp /data_bags fails' do
          knife('list --local -Rfp /data_bags').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
        end

        context 'when cwd is inside the data_bags directory' do
          cwd 'data_bags'
          it 'knife list --local -Rfp fails' do
            knife('list --local -Rfp').should_fail("ERROR: Must specify either chef_repo_path or cookbook_path in Chef config file\n")
          end
        end
      end
    end

    when_the_repository 'is empty' do
      context 'when the repository _paths point to places that do not exist' do
        before :each do
          %w(client cookbook data_bag environment node role user).each do |object_name|
            Chef::Config["#{object_name}_path".to_sym] = File.join(Chef::Config.chef_repo_path, 'nowhere', object_name)
          end
          Chef::Config.chef_repo_path = File.join(Chef::Config.chef_repo_path, 'nowhere')
        end

        it 'knife list --local -Rfp / fails' do
          knife('list --local -Rfp /').should_succeed ''
        end

        it 'knife list --local -Rfp /data_bags fails' do
          knife('list --local -Rfp /data_bags').should_fail("ERROR: /data_bags: No such file or directory\n")
        end
      end
    end
  end
end
