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
require 'chef/knife/download'
require 'chef/knife/diff'

describe 'knife download' do
  extend IntegrationSupport
  include KnifeSupport

  context 'without versioned cookbooks' do
    when_the_chef_server "has one of each thing" do
      client 'x', {}
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"' }
      data_bag 'x', { 'y' => {} }
      environment 'x', {}
      node 'x', {}
      role 'x', {}
      user 'x', {}

      when_the_repository 'has only top-level directories' do
        directory 'clients'
        directory 'cookbooks'
        directory 'data_bags'
        directory 'environments'
        directory 'nodes'
        directory 'roles'
        directory 'users'

        it 'knife download downloads everything' do
          knife('download /').should_succeed <<EOM
Created /clients/chef-validator.json
Created /clients/chef-webui.json
Created /clients/x.json
Created /cookbooks/x
Created /cookbooks/x/metadata.rb
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments/_default.json
Created /environments/x.json
Created /nodes/x.json
Created /roles/x.json
Created /users/admin.json
Created /users/x.json
EOM
          knife('diff --name-status /').should_succeed ''
        end
      end

      when_the_repository 'has an identical copy of each thing' do
        file 'clients/chef-validator.json', { 'validator' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/chef-webui.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }
        file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
        file 'data_bags/x/y.json', {}
        file 'environments/_default.json', { "description" => "The default Chef environment" }
        file 'environments/x.json', {}
        file 'nodes/x.json', {}
        file 'roles/x.json', {}
        file 'users/admin.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'users/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }

        it 'knife download makes no changes' do
          knife('download /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        it 'knife download --purge makes no changes' do
          knife('download --purge /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        context 'except the role file' do
          file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "description": "blarghle",
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "x",
  "override_attributes": {
  },
  "run_list": [

  ]
}
EOM
          it 'knife download changes the role' do
            knife('download /').should_succeed "Updated /roles/x.json\n"
            knife('diff --name-status /').should_succeed ''
          end

          it 'knife download --no-diff does not change the role' do
            knife('download --no-diff /').should_succeed ''
            knife('diff --name-status /').should_succeed "M\t/roles/x.json\n"
          end
        end

        context 'except the role file is textually different, but not ACTUALLY different' do
          file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "x",
  "description": "",
  "override_attributes": {
  },
  "run_list": [

  ]
}
EOM
          it 'knife download / does not change anything' do
            knife('download /').should_succeed ''
            knife('diff --name-status /').should_succeed ''
          end
        end

        context 'as well as one extra copy of each thing' do
          file 'clients/y.json', { 'public_key' => ChefZero::PUBLIC_KEY }
          file 'cookbooks/x/blah.rb', ''
          file 'cookbooks/y/metadata.rb', 'version "1.0.0"'
          file 'data_bags/x/z.json', {}
          file 'data_bags/y/zz.json', {}
          file 'environments/y.json', {}
          file 'nodes/y.json', {}
          file 'roles/y.json', {}
          file 'users/y.json', { 'public_key' => ChefZero::PUBLIC_KEY }

          it 'knife download does nothing' do
            knife('download /').should_succeed ''
            knife('diff --name-status /').should_succeed <<EOM
A\t/clients/y.json
A\t/cookbooks/x/blah.rb
A\t/cookbooks/y
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/nodes/y.json
A\t/roles/y.json
A\t/users/y.json
EOM
          end

          it 'knife download --purge deletes the extra files' do
            knife('download --purge /').should_succeed <<EOM
Deleted extra entry /clients/y.json (purge is on)
Deleted extra entry /cookbooks/x/blah.rb (purge is on)
Deleted extra entry /cookbooks/y (purge is on)
Deleted extra entry /data_bags/x/z.json (purge is on)
Deleted extra entry /data_bags/y (purge is on)
Deleted extra entry /environments/y.json (purge is on)
Deleted extra entry /nodes/y.json (purge is on)
Deleted extra entry /roles/y.json (purge is on)
Deleted extra entry /users/y.json (purge is on)
EOM
            knife('diff --name-status /').should_succeed ''
          end
        end
      end

      when_the_repository 'is empty' do
        it 'knife download creates the extra files' do
          knife('download /').should_succeed <<EOM
Created /clients
Created /clients/chef-validator.json
Created /clients/chef-webui.json
Created /clients/x.json
Created /cookbooks
Created /cookbooks/x
Created /cookbooks/x/metadata.rb
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments
Created /environments/_default.json
Created /environments/x.json
Created /nodes
Created /nodes/x.json
Created /roles
Created /roles/x.json
Created /users
Created /users/admin.json
Created /users/x.json
EOM
          knife('diff --name-status /').should_succeed ''
        end

        it 'knife download --no-diff creates the extra files' do
          knife('download --no-diff /').should_succeed <<EOM
Created /clients
Created /clients/chef-validator.json
Created /clients/chef-webui.json
Created /clients/x.json
Created /cookbooks
Created /cookbooks/x
Created /cookbooks/x/metadata.rb
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments
Created /environments/_default.json
Created /environments/x.json
Created /nodes
Created /nodes/x.json
Created /roles
Created /roles/x.json
Created /users
Created /users/admin.json
Created /users/x.json
EOM
          knife('diff --name-status /').should_succeed ''
        end

        context 'when current directory is top level' do
          cwd '.'
          it 'knife download with no parameters reports an error' do
            knife('download').should_fail "FATAL: Must specify at least one argument.  If you want to download everything in this directory, type \"knife download .\"\n", :stdout => /USAGE/
          end
        end
      end
    end

    # Test download of an item when the other end doesn't even have the container
    when_the_repository 'is empty' do
      when_the_chef_server 'has two data bag items' do
        data_bag 'x', { 'y' => {}, 'z' => {} }

        it 'knife download of one data bag item itself succeeds' do
          knife('download /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/z.json
EOM
        end
      end
    end

    when_the_repository 'has three data bag items' do
      file 'data_bags/x/deleted.json', <<EOM
{
  "id": "deleted"
}
EOM
      file 'data_bags/x/modified.json', <<EOM
{
  "id": "modified"
}
EOM
      file 'data_bags/x/unmodified.json', <<EOM
{
  "id": "unmodified"
}
EOM

      when_the_chef_server 'has a modified, unmodified, added and deleted data bag item' do
        data_bag 'x', {
          'added' => {},
          'modified' => { 'foo' => 'bar' },
          'unmodified' => {}
        }

        it 'knife download of the modified file succeeds' do
          knife('download /data_bags/x/modified.json').should_succeed <<EOM
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the unmodified file does nothing' do
          knife('download /data_bags/x/unmodified.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the added file succeeds' do
          knife('download /data_bags/x/added.json').should_succeed <<EOM
Created /data_bags/x/added.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the deleted file does nothing' do
          knife('download /data_bags/x/deleted.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download --purge of the deleted file deletes it' do
          knife('download --purge /data_bags/x/deleted.json').should_succeed <<EOM
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
EOM
        end
        it 'knife download of the entire data bag downloads everything' do
          knife('download /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download --purge of the entire data bag downloads everything' do
          knife('download --purge /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed ''
        end
        context 'when cwd is the /data_bags directory' do
          cwd 'data_bags'
          it 'knife download fails' do
            knife('download').should_fail "FATAL: Must specify at least one argument.  If you want to download everything in this directory, type \"knife download .\"\n", :stdout => /USAGE/
          end
          it 'knife download --purge . downloads everything' do
            knife('download --purge .').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
          it 'knife download --purge * downloads everything' do
            knife('download --purge *').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
        end
      end
    end

    when_the_repository 'has a cookbook' do
      file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x/z.rb', ''

      when_the_chef_server 'has a modified, added and deleted file for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version  "1.0.0"', 'y.rb' => 'hi' }

        it 'knife download of a modified file succeeds' do
          knife('download /cookbooks/x/metadata.rb').should_succeed "Updated /cookbooks/x/metadata.rb\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x/y.rb
A\t/cookbooks/x/z.rb
EOM
        end
        it 'knife download of a deleted file does nothing' do
          knife('download /cookbooks/x/z.rb').should_succeed ''
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/y.rb
A\t/cookbooks/x/z.rb
EOM
        end
        it 'knife download --purge of a deleted file succeeds' do
          knife('download --purge /cookbooks/x/z.rb').should_succeed "Deleted extra entry /cookbooks/x/z.rb (purge is on)\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/y.rb
EOM
        end
        it 'knife download of an added file succeeds' do
          knife('download /cookbooks/x/y.rb').should_succeed "Created /cookbooks/x/y.rb\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
A\t/cookbooks/x/z.rb
EOM
        end
        it 'knife download of the cookbook itself succeeds' do
          knife('download /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/metadata.rb
Created /cookbooks/x/y.rb
EOM
          knife('diff --name-status /cookbooks').should_succeed <<EOM
A\t/cookbooks/x/z.rb
EOM
        end
        it 'knife download --purge of the cookbook itself succeeds' do
          knife('download --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/metadata.rb
Created /cookbooks/x/y.rb
Deleted extra entry /cookbooks/x/z.rb (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_repository 'has a cookbook' do
      file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x/onlyin1.0.0.rb', 'old_text'

      when_the_chef_server 'has a later version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => '' }
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife download /cookbooks/x downloads the latest version' do
          knife('download --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/metadata.rb
Created /cookbooks/x/onlyin1.0.1.rb
Deleted extra entry /cookbooks/x/onlyin1.0.0.rb (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }
        it 'knife download /cookbooks/x downloads the updated file' do
          knife('download --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/onlyin1.0.0.rb
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has a later version for the cookbook, and no current version' do
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife download /cookbooks/x downloads the latest version' do
          knife('download --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/metadata.rb
Created /cookbooks/x/onlyin1.0.1.rb
Deleted extra entry /cookbooks/x/onlyin1.0.0.rb (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

        it 'knife download /cookbooks/x downloads the old version' do
          knife('download --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x/metadata.rb
Created /cookbooks/x/onlyin0.9.9.rb
Deleted extra entry /cookbooks/x/onlyin1.0.0.rb (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_chef_server 'has an environment' do
      environment 'x', {}
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n", :stderr => "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has the same environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has the same environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end
    end
  end # without versioned cookbooks

  with_versioned_cookbooks do
    when_the_chef_server "has one of each thing" do
      client 'x', {}
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"' }
      data_bag 'x', { 'y' => {} }
      environment 'x', {}
      node 'x', {}
      role 'x', {}
      user 'x', {}

      when_the_repository 'has only top-level directories' do
        directory 'clients'
        directory 'cookbooks'
        directory 'data_bags'
        directory 'environments'
        directory 'nodes'
        directory 'roles'
        directory 'users'

        it 'knife download downloads everything' do
          knife('download /').should_succeed <<EOM
Created /clients/chef-validator.json
Created /clients/chef-webui.json
Created /clients/x.json
Created /cookbooks/x-1.0.0
Created /cookbooks/x-1.0.0/metadata.rb
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments/_default.json
Created /environments/x.json
Created /nodes/x.json
Created /roles/x.json
Created /users/admin.json
Created /users/x.json
EOM
          knife('diff --name-status /').should_succeed ''
        end
      end

      when_the_repository 'has an identical copy of each thing' do
        file 'clients/chef-validator.json', { 'validator' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/chef-webui.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }
        file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'
        file 'data_bags/x/y.json', {}
        file 'environments/_default.json', { "description" => "The default Chef environment" }
        file 'environments/x.json', {}
        file 'nodes/x.json', {}
        file 'roles/x.json', {}
        file 'users/admin.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'users/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }

        it 'knife download makes no changes' do
          knife('download /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        it 'knife download --purge makes no changes' do
          knife('download --purge /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        context 'except the role file' do
          file 'roles/x.json', { "description" => "blarghle" }

          it 'knife download changes the role' do
            knife('download /').should_succeed "Updated /roles/x.json\n"
            knife('diff --name-status /').should_succeed ''
          end
        end

        context 'except the role file is textually different, but not ACTUALLY different' do
          file 'roles/x.json', <<EOM
{  
  "chef_type": "role" ,
  "default_attributes": {
  },
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "x",
  "description": "",
  "override_attributes": {
  },
  "run_list": [
     
  ]
}
EOM
          it 'knife download / does not change anything' do
            knife('download /').should_succeed ''
            knife('diff --name-status /').should_succeed ''
          end
        end

        context 'as well as one extra copy of each thing' do
          file 'clients/y.json', { 'public_key' => ChefZero::PUBLIC_KEY }
          file 'cookbooks/x-1.0.0/blah.rb', ''
          file 'cookbooks/x-2.0.0/metadata.rb', 'version "2.0.0"'
          file 'cookbooks/y-1.0.0/metadata.rb', 'version "1.0.0"'
          file 'data_bags/x/z.json', {}
          file 'data_bags/y/zz.json', {}
          file 'environments/y.json', {}
          file 'nodes/y.json', {}
          file 'roles/y.json', {}
          file 'users/y.json', { 'public_key' => ChefZero::PUBLIC_KEY }

          it 'knife download does nothing' do
            knife('download /').should_succeed ''
            knife('diff --name-status /').should_succeed <<EOM
A\t/clients/y.json
A\t/cookbooks/x-1.0.0/blah.rb
A\t/cookbooks/x-2.0.0
A\t/cookbooks/y-1.0.0
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/nodes/y.json
A\t/roles/y.json
A\t/users/y.json
EOM
          end

          it 'knife download --purge deletes the extra files' do
            knife('download --purge /').should_succeed <<EOM
Deleted extra entry /clients/y.json (purge is on)
Deleted extra entry /cookbooks/x-1.0.0/blah.rb (purge is on)
Deleted extra entry /cookbooks/x-2.0.0 (purge is on)
Deleted extra entry /cookbooks/y-1.0.0 (purge is on)
Deleted extra entry /data_bags/x/z.json (purge is on)
Deleted extra entry /data_bags/y (purge is on)
Deleted extra entry /environments/y.json (purge is on)
Deleted extra entry /nodes/y.json (purge is on)
Deleted extra entry /roles/y.json (purge is on)
Deleted extra entry /users/y.json (purge is on)
EOM
            knife('diff --name-status /').should_succeed ''
          end
        end
      end

      when_the_repository 'is empty' do
        it 'knife download creates the extra files' do
          knife('download /').should_succeed <<EOM
Created /clients
Created /clients/chef-validator.json
Created /clients/chef-webui.json
Created /clients/x.json
Created /cookbooks
Created /cookbooks/x-1.0.0
Created /cookbooks/x-1.0.0/metadata.rb
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments
Created /environments/_default.json
Created /environments/x.json
Created /nodes
Created /nodes/x.json
Created /roles
Created /roles/x.json
Created /users
Created /users/admin.json
Created /users/x.json
EOM
          knife('diff --name-status /').should_succeed ''
        end

        context 'when current directory is top level' do
          cwd '.'
          it 'knife download with no parameters reports an error' do
            knife('download').should_fail "FATAL: Must specify at least one argument.  If you want to download everything in this directory, type \"knife download .\"\n", :stdout => /USAGE/
          end
        end
      end
    end

    # Test download of an item when the other end doesn't even have the container
    when_the_repository 'is empty' do
      when_the_chef_server 'has two data bag items' do
        data_bag 'x', { 'y' => {}, 'z' => {} }

        it 'knife download of one data bag item itself succeeds' do
          knife('download /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/z.json
EOM
        end
      end
    end

    when_the_repository 'has three data bag items' do
      file 'data_bags/x/deleted.json', <<EOM
{
  "id": "deleted"
}
EOM
      file 'data_bags/x/modified.json', <<EOM
{
  "id": "modified"
}
EOM
      file 'data_bags/x/unmodified.json', <<EOM
{
  "id": "unmodified"
}
EOM

      when_the_chef_server 'has a modified, unmodified, added and deleted data bag item' do
        data_bag 'x', {
          'added' => {},
          'modified' => { 'foo' => 'bar' },
          'unmodified' => {}
        }

        it 'knife download of the modified file succeeds' do
          knife('download /data_bags/x/modified.json').should_succeed <<EOM
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the unmodified file does nothing' do
          knife('download /data_bags/x/unmodified.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the added file succeeds' do
          knife('download /data_bags/x/added.json').should_succeed <<EOM
Created /data_bags/x/added.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download of the deleted file does nothing' do
          knife('download /data_bags/x/deleted.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download --purge of the deleted file deletes it' do
          knife('download --purge /data_bags/x/deleted.json').should_succeed <<EOM
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/added.json
M\t/data_bags/x/modified.json
EOM
        end
        it 'knife download of the entire data bag downloads everything' do
          knife('download /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
A\t/data_bags/x/deleted.json
EOM
        end
        it 'knife download --purge of the entire data bag downloads everything' do
          knife('download --purge /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed ''
        end
        context 'when cwd is the /data_bags directory' do
          cwd 'data_bags'
          it 'knife download fails' do
            knife('download').should_fail "FATAL: Must specify at least one argument.  If you want to download everything in this directory, type \"knife download .\"\n", :stdout => /USAGE/
          end
          it 'knife download --purge . downloads everything' do
            knife('download --purge .').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
          it 'knife download --purge * downloads everything' do
            knife('download --purge *').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
        end
      end
    end

    when_the_repository 'has a cookbook' do
      file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x-1.0.0/z.rb', ''

      when_the_chef_server 'has a modified, added and deleted file for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version  "1.0.0"', 'y.rb' => 'hi' }

        it 'knife download of a modified file succeeds' do
          knife('download /cookbooks/x-1.0.0/metadata.rb').should_succeed "Updated /cookbooks/x-1.0.0/metadata.rb\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-1.0.0/y.rb
A\t/cookbooks/x-1.0.0/z.rb
EOM
        end
        it 'knife download of a deleted file does nothing' do
          knife('download /cookbooks/x-1.0.0/z.rb').should_succeed ''
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x-1.0.0/metadata.rb
D\t/cookbooks/x-1.0.0/y.rb
A\t/cookbooks/x-1.0.0/z.rb
EOM
        end
        it 'knife download --purge of a deleted file succeeds' do
          knife('download --purge /cookbooks/x-1.0.0/z.rb').should_succeed "Deleted extra entry /cookbooks/x-1.0.0/z.rb (purge is on)\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x-1.0.0/metadata.rb
D\t/cookbooks/x-1.0.0/y.rb
EOM
        end
        it 'knife download of an added file succeeds' do
          knife('download /cookbooks/x-1.0.0/y.rb').should_succeed "Created /cookbooks/x-1.0.0/y.rb\n"
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x-1.0.0/metadata.rb
A\t/cookbooks/x-1.0.0/z.rb
EOM
        end
        it 'knife download of the cookbook itself succeeds' do
          knife('download /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0/metadata.rb
Created /cookbooks/x-1.0.0/y.rb
EOM
          knife('diff --name-status /cookbooks').should_succeed <<EOM
A\t/cookbooks/x-1.0.0/z.rb
EOM
        end
        it 'knife download --purge of the cookbook itself succeeds' do
          knife('download --purge /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0/metadata.rb
Created /cookbooks/x-1.0.0/y.rb
Deleted extra entry /cookbooks/x-1.0.0/z.rb (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_repository 'has a cookbook' do
      file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x-1.0.0/onlyin1.0.0.rb', 'old_text'

      when_the_chef_server 'has a later version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => '' }
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife download /cookbooks/x downloads the latest version' do
          knife('download --purge /cookbooks').should_succeed <<EOM
Updated /cookbooks/x-1.0.0/onlyin1.0.0.rb
Created /cookbooks/x-1.0.1
Created /cookbooks/x-1.0.1/metadata.rb
Created /cookbooks/x-1.0.1/onlyin1.0.1.rb
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }
        it 'knife download /cookbooks downloads the updated file' do
          knife('download --purge /cookbooks').should_succeed <<EOM
Created /cookbooks/x-0.9.9
Created /cookbooks/x-0.9.9/metadata.rb
Created /cookbooks/x-0.9.9/onlyin0.9.9.rb
Updated /cookbooks/x-1.0.0/onlyin1.0.0.rb
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has a later version for the cookbook, and no current version' do
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife download /cookbooks/x downloads the latest version' do
          knife('download --purge /cookbooks').should_succeed <<EOM
Created /cookbooks/x-1.0.1
Created /cookbooks/x-1.0.1/metadata.rb
Created /cookbooks/x-1.0.1/onlyin1.0.1.rb
Deleted extra entry /cookbooks/x-1.0.0 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

        it 'knife download --purge /cookbooks downloads the old version and deletes the new version' do
          knife('download --purge /cookbooks').should_succeed <<EOM
Created /cookbooks/x-0.9.9
Created /cookbooks/x-0.9.9/metadata.rb
Created /cookbooks/x-0.9.9/onlyin0.9.9.rb
Deleted extra entry /cookbooks/x-1.0.0 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_chef_server 'has an environment' do
      environment 'x', {}
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n", :stderr => "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has the same environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has the same environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife download succeeds' do
          knife('download /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end
    end
  end # with versioned cookbooks
end
