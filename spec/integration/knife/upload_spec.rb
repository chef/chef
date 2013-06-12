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
require 'chef/knife/upload'
require 'chef/knife/diff'
require 'chef/knife/raw'

describe 'knife upload' do
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

        it 'knife upload does nothing' do
          knife('upload /').should_succeed ''
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients/chef-validator.json
D\t/clients/chef-webui.json
D\t/clients/x.json
D\t/cookbooks/x
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/nodes/x.json
D\t/roles/x.json
D\t/users/admin.json
D\t/users/x.json
EOM
      end

      it 'knife upload --purge deletes everything' do
        knife('upload --purge /').should_succeed(<<EOM, :stderr => "WARNING: /environments/_default.json cannot be deleted (default environment cannot be modified).\n")
Deleted extra entry /clients/chef-validator.json (purge is on)
Deleted extra entry /clients/chef-webui.json (purge is on)
Deleted extra entry /clients/x.json (purge is on)
Deleted extra entry /cookbooks/x (purge is on)
Deleted extra entry /data_bags/x (purge is on)
Deleted extra entry /environments/x.json (purge is on)
Deleted extra entry /nodes/x.json (purge is on)
Deleted extra entry /roles/x.json (purge is on)
Deleted extra entry /users/admin.json (purge is on)
Deleted extra entry /users/x.json (purge is on)
EOM
        knife('diff --name-status /').should_succeed <<EOM
D\t/environments/_default.json
EOM
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

        it 'knife upload makes no changes' do
          knife('upload /cookbooks/x').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        it 'knife upload --purge makes no changes' do
          knife('upload --purge /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        context 'except the role file' do
          file 'roles/x.json', { 'description' => 'blarghle' }
          it 'knife upload changes the role' do
            knife('upload /').should_succeed "Updated /roles/x.json\n"
            knife('diff --name-status /').should_succeed ''
          end
          it 'knife upload --no-diff does not change the role' do
            knife('upload --no-diff /').should_succeed ''
            knife('diff --name-status /').should_succeed "M\t/roles/x.json\n"
          end
        end

        context 'except the role file is textually different, but not ACTUALLY different' do
          file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes":  {
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
          it 'knife upload / does not change anything' do
            knife('upload /').should_succeed ''
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

          it 'knife upload adds the new files' do
            knife('upload /').should_succeed <<EOM
Created /clients/y.json
Updated /cookbooks/x
Created /cookbooks/y
Created /data_bags/x/z.json
Created /data_bags/y
Created /data_bags/y/zz.json
Created /environments/y.json
Created /nodes/y.json
Created /roles/y.json
Created /users/y.json
EOM
            knife('diff --name-status /').should_succeed ''
          end

          it 'knife upload --no-diff adds the new files' do
            knife('upload --no-diff /').should_succeed <<EOM
Created /clients/y.json
Updated /cookbooks/x
Created /cookbooks/y
Created /data_bags/x/z.json
Created /data_bags/y
Created /data_bags/y/zz.json
Created /environments/y.json
Created /nodes/y.json
Created /roles/y.json
Created /users/y.json
EOM
            knife('diff --name-status /').should_succeed ''
          end
        end
      end

      when_the_repository 'is empty' do
        it 'knife upload does nothing' do
          knife('upload /').should_succeed ''
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/nodes
D\t/roles
D\t/users
EOM
        end

        it 'knife upload --purge deletes nothing' do
          knife('upload --purge /').should_fail <<EOM
ERROR: /clients cannot be deleted.
ERROR: /cookbooks cannot be deleted.
ERROR: /data_bags cannot be deleted.
ERROR: /environments cannot be deleted.
ERROR: /nodes cannot be deleted.
ERROR: /roles cannot be deleted.
ERROR: /users cannot be deleted.
EOM
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/nodes
D\t/roles
D\t/users
EOM
        end

        context 'when current directory is top level' do
          cwd '.'
          it 'knife upload with no parameters reports an error' do
            knife('upload').should_fail "FATAL: Must specify at least one argument.  If you want to upload everything in this directory, type \"knife upload .\"\n", :stdout => /USAGE/
          end
        end
      end
    end

    when_the_chef_server 'is empty' do
      when_the_repository 'has a data bag item' do
        file 'data_bags/x/y.json', { 'foo' => 'bar' }
        it 'knife upload of the data bag uploads only the values in the data bag item and no other' do
          knife('upload /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
EOM
          JSON.parse(knife('raw /data/x/y').stdout, :create_additions => false).keys.sort.should == [ 'foo', 'id' ]
        end
      end

      when_the_repository 'has a data bag item with keys chef_type and data_bag' do
        file 'data_bags/x/y.json', { 'chef_type' => 'aaa', 'data_bag' => 'bbb' }
        it 'upload preserves chef_type and data_bag' do
          knife('upload /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed ''
          result = JSON.parse(knife('raw /data/x/y').stdout, :create_additions => false)
          result.keys.sort.should == [ 'chef_type', 'data_bag', 'id' ]
          result['chef_type'].should == 'aaa'
          result['data_bag'].should == 'bbb'
        end
      end

      # Test upload of an item when the other end doesn't even have the container
      when_the_repository 'has two data bag items' do
        file 'data_bags/x/y.json', {}
        file 'data_bags/x/z.json', {}
        it 'knife upload of one data bag item itself succeeds' do
          knife('upload /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
A\t/data_bags/x/z.json
EOM
        end
      end
    end

    when_the_chef_server 'has three data bag items' do
      data_bag 'x', { 'deleted' => {}, 'modified' => {}, 'unmodified' => {} }

      when_the_repository 'has a modified, unmodified, added and deleted data bag item' do
        file 'data_bags/x/added.json', {}
        file 'data_bags/x/modified.json', { 'foo' => 'bar' }
        file 'data_bags/x/unmodified.json', {}

        it 'knife upload of the modified file succeeds' do
          knife('upload /data_bags/x/modified.json').should_succeed <<EOM
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the unmodified file does nothing' do
          knife('upload /data_bags/x/unmodified.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the added file succeeds' do
          knife('upload /data_bags/x/added.json').should_succeed <<EOM
Created /data_bags/x/added.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
EOM
        end
        it 'knife upload of the deleted file does nothing' do
          knife('upload /data_bags/x/deleted.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload --purge of the deleted file deletes it' do
          knife('upload --purge /data_bags/x/deleted.json').should_succeed <<EOM
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the entire data bag uploads everything' do
          knife('upload /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
EOM
        end
        it 'knife upload --purge of the entire data bag uploads everything' do
          knife('upload --purge /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed ''
        end
        context 'when cwd is the /data_bags directory' do
          cwd 'data_bags'
          it 'knife upload fails' do
            knife('upload').should_fail "FATAL: Must specify at least one argument.  If you want to upload everything in this directory, type \"knife upload .\"\n", :stdout => /USAGE/
          end
          it 'knife upload --purge . uploads everything' do
            knife('upload --purge .').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
          it 'knife upload --purge * uploads everything' do
            knife('upload --purge *').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
        end
      end
    end

    # Cookbook upload is a funny thing ... direct cookbook upload works, but
    # upload of a file is designed not to work at present.  Make sure that is the
    # case.
    when_the_chef_server 'has a cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'z.rb' => '' }
      when_the_repository 'has a modified, extra and missing file for the cookbook' do
        file 'cookbooks/x/metadata.rb', 'version  "1.0.0"'
        file 'cookbooks/x/y.rb', 'hi'
        it 'knife upload of any individual file fails' do
          knife('upload /cookbooks/x/metadata.rb').should_fail "ERROR: /cookbooks/x/metadata.rb cannot be updated.\n"
          knife('upload /cookbooks/x/y.rb').should_fail "ERROR: /cookbooks/x cannot have a child created under it.\n"
          knife('upload --purge /cookbooks/x/z.rb').should_fail "ERROR: /cookbooks/x/z.rb cannot be deleted.\n"
        end
        # TODO this is a bit of an inconsistency: if we didn't specify --purge,
        # technically we shouldn't have deleted missing files.  But ... cookbooks
        # are a special case.
        it 'knife upload of the cookbook itself succeeds' do
          knife('upload /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
        it 'knife upload --purge of the cookbook itself succeeds' do
          knife('upload /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
      when_the_repository 'has a missing file for the cookbook' do
        file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
        it 'knife upload of the cookbook succeeds' do
          knife('upload /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
      when_the_repository 'has an extra file for the cookbook' do
        file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
        file 'cookbooks/x/z.rb', ''
        file 'cookbooks/x/blah.rb', ''
        it 'knife upload of the cookbook succeeds' do
          knife('upload /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_repository 'has a different file in the cookbook' do
        file 'cookbooks/x/metadata.rb', 'version  "1.0.0"'

        it 'knife upload --freeze freezes the cookbook' do
          knife('upload --freeze /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          # Modify a file and attempt to upload
          file 'cookbooks/x/metadata.rb', 'version "1.0.0" # This is different'
          knife('upload /cookbooks/x').should_fail "ERROR: /cookbooks failed to write: Cookbook x is frozen\n"
        end
      end
    end

    when_the_chef_server 'has a frozen cookbook' do
      cookbook 'frozencook', '1.0.0', {
        'metadata.rb' => 'version "1.0.0"'
      }, :frozen => true

      when_the_repository 'has an update to said cookbook' do
        file 'cookbooks/frozencook/metadata.rb', 'version "1.0.0" # This is different'

        it 'knife upload fails to upload the frozen cookbook' do
          knife('upload /cookbooks/frozencook').should_fail "ERROR: /cookbooks failed to write: Cookbook frozencook is frozen\n"
        end
        it 'knife upload --force uploads the frozen cookbook' do
          knife('upload --force /cookbooks/frozencook').should_succeed <<EOM
Updated /cookbooks/frozencook
EOM
        end
      end
    end

    when_the_repository 'has a cookbook' do
      file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
      file 'cookbooks/x/onlyin1.0.0.rb', 'old_text'

      when_the_chef_server 'has a later version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => '' }
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife upload /cookbooks/x uploads the local version' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
          knife('upload --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }
        it 'knife upload /cookbooks/x uploads the local version' do
          knife('upload --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has a later version for the cookbook, and no current version' do
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife upload /cookbooks/x uploads the local version' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
          knife('upload --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

        it 'knife upload /cookbooks/x uploads the new version' do
          knife('upload --purge /cookbooks/x').should_succeed <<EOM
Updated /cookbooks/x
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_chef_server 'has an environment' do
      environment 'x', {}
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife upload tries and fails' do
          knife('upload /environments/x.json').should_fail "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\nERROR: /environments/x.json failed to write: Parse error reading JSON: A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed "M\t/environments/x.json\n", :stderr => "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\n"
        end
      end

      when_the_repository 'has the same environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife upload fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments/x.json failed to write: Name must be 'x' (is 'y')\n"
          knife('diff --name-status /environments/x.json').should_succeed "M\t/environments/x.json\n"
        end
      end

      when_the_repository 'has the same environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife upload succeeds' do
          knife('upload /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end
    end

    when_the_chef_server 'is empty' do
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife upload tries and fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments failed to create_child: Parse error reading JSON creating child 'x.json': A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed "A\t/environments/x.json\n"
        end
      end

      when_the_repository 'has an environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife upload fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments failed to create_child: Error creating 'x.json': Name must be 'x' (is 'y')\n"
          knife('diff --name-status /environments/x.json').should_succeed "A\t/environments/x.json\n"
        end
      end

      when_the_repository 'has an environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife upload succeeds' do
          knife('upload /environments/x.json').should_succeed "Created /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has a data bag with no id in the file' do
        file 'data_bags/bag/x.json', { 'foo' => 'bar' }
        it 'knife upload succeeds' do
          knife('upload /data_bags/bag/x.json').should_succeed "Created /data_bags/bag\nCreated /data_bags/bag/x.json\n"
          knife('diff --name-status /data_bags/bag/x.json').should_succeed ''
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

        it 'knife upload does nothing' do
          knife('upload /').should_succeed ''
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients/chef-validator.json
D\t/clients/chef-webui.json
D\t/clients/x.json
D\t/cookbooks/x-1.0.0
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/nodes/x.json
D\t/roles/x.json
D\t/users/admin.json
D\t/users/x.json
EOM
        end

        it 'knife upload --purge deletes everything' do
          knife('upload --purge /').should_succeed(<<EOM, :stderr => "WARNING: /environments/_default.json cannot be deleted (default environment cannot be modified).\n")
Deleted extra entry /clients/chef-validator.json (purge is on)
Deleted extra entry /clients/chef-webui.json (purge is on)
Deleted extra entry /clients/x.json (purge is on)
Deleted extra entry /cookbooks/x-1.0.0 (purge is on)
Deleted extra entry /data_bags/x (purge is on)
Deleted extra entry /environments/x.json (purge is on)
Deleted extra entry /nodes/x.json (purge is on)
Deleted extra entry /roles/x.json (purge is on)
Deleted extra entry /users/admin.json (purge is on)
Deleted extra entry /users/x.json (purge is on)
EOM
          knife('diff --name-status /').should_succeed <<EOM
D\t/environments/_default.json
EOM
        end
      end

      when_the_repository 'has an identical copy of each thing' do
        file 'clients/chef-validator.json', { 'validator' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/chef-webui.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'clients/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }
        file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'
        file 'data_bags/x/y.json', {}
        file 'environments/_default.json', { 'description' => 'The default Chef environment' }
        file 'environments/x.json', {}
        file 'nodes/x.json', {}
        file 'roles/x.json', {}
        file 'users/admin.json', { 'admin' => true, 'public_key' => ChefZero::PUBLIC_KEY }
        file 'users/x.json', { 'public_key' => ChefZero::PUBLIC_KEY }

        it 'knife upload makes no changes' do
          knife('upload /cookbooks/x-1.0.0').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        it 'knife upload --purge makes no changes' do
          knife('upload --purge /').should_succeed ''
          knife('diff --name-status /').should_succeed ''
        end

        context 'except the role file' do
          file 'roles/x.json', { 'description' => 'blarghle' }

          it 'knife upload changes the role' do
            knife('upload /').should_succeed "Updated /roles/x.json\n"
            knife('diff --name-status /').should_succeed ''
          end
        end

        context 'except the role file is textually different, but not ACTUALLY different' do
          file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes":  {
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
          it 'knife upload / does not change anything' do
            knife('upload /').should_succeed ''
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

          it 'knife upload adds the new files' do
            knife('upload /').should_succeed <<EOM
Created /clients/y.json
Updated /cookbooks/x-1.0.0
Created /cookbooks/x-2.0.0
Created /cookbooks/y-1.0.0
Created /data_bags/x/z.json
Created /data_bags/y
Created /data_bags/y/zz.json
Created /environments/y.json
Created /nodes/y.json
Created /roles/y.json
Created /users/y.json
EOM
            knife('diff --name-status /').should_succeed ''
          end
        end
      end

      when_the_repository 'is empty' do
        it 'knife upload does nothing' do
          knife('upload /').should_succeed ''
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/nodes
D\t/roles
D\t/users
EOM
        end

        it 'knife upload --purge deletes nothing' do
          knife('upload --purge /').should_fail <<EOM
ERROR: /clients cannot be deleted.
ERROR: /cookbooks cannot be deleted.
ERROR: /data_bags cannot be deleted.
ERROR: /environments cannot be deleted.
ERROR: /nodes cannot be deleted.
ERROR: /roles cannot be deleted.
ERROR: /users cannot be deleted.
EOM
          knife('diff --name-status /').should_succeed <<EOM
D\t/clients
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/nodes
D\t/roles
D\t/users
EOM
        end

        context 'when current directory is top level' do
          cwd '.'
          it 'knife upload with no parameters reports an error' do
            knife('upload').should_fail "FATAL: Must specify at least one argument.  If you want to upload everything in this directory, type \"knife upload .\"\n", :stdout => /USAGE/
          end
        end
      end
    end

    # Test upload of an item when the other end doesn't even have the container
    when_the_chef_server 'is empty' do
      when_the_repository 'has two data bag items' do
        file 'data_bags/x/y.json', {}
        file 'data_bags/x/z.json', {}

        it 'knife upload of one data bag item itself succeeds' do
          knife('upload /data_bags/x/y.json').should_succeed <<EOM
Created /data_bags/x
Created /data_bags/x/y.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
A\t/data_bags/x/z.json
EOM
        end
      end
    end

    when_the_chef_server 'has three data bag items' do
      data_bag 'x', { 'deleted' => {}, 'modified' => {}, 'unmodified' => {} }
      when_the_repository 'has a modified, unmodified, added and deleted data bag item' do
        file 'data_bags/x/added.json', {}
        file 'data_bags/x/modified.json', { 'foo' => 'bar' }
        file 'data_bags/x/unmodified.json', {}

        it 'knife upload of the modified file succeeds' do
          knife('upload /data_bags/x/modified.json').should_succeed <<EOM
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the unmodified file does nothing' do
          knife('upload /data_bags/x/unmodified.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the added file succeeds' do
          knife('upload /data_bags/x/added.json').should_succeed <<EOM
Created /data_bags/x/added.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
EOM
        end
        it 'knife upload of the deleted file does nothing' do
          knife('upload /data_bags/x/deleted.json').should_succeed ''
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload --purge of the deleted file deletes it' do
          knife('upload --purge /data_bags/x/deleted.json').should_succeed <<EOM
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
M\t/data_bags/x/modified.json
A\t/data_bags/x/added.json
EOM
        end
        it 'knife upload of the entire data bag uploads everything' do
          knife('upload /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
EOM
          knife('diff --name-status /data_bags').should_succeed <<EOM
D\t/data_bags/x/deleted.json
EOM
        end
        it 'knife upload --purge of the entire data bag uploads everything' do
          knife('upload --purge /data_bags/x').should_succeed <<EOM
Created /data_bags/x/added.json
Updated /data_bags/x/modified.json
Deleted extra entry /data_bags/x/deleted.json (purge is on)
EOM
          knife('diff --name-status /data_bags').should_succeed ''
        end
        context 'when cwd is the /data_bags directory' do
          cwd 'data_bags'
          it 'knife upload fails' do
            knife('upload').should_fail "FATAL: Must specify at least one argument.  If you want to upload everything in this directory, type \"knife upload .\"\n", :stdout => /USAGE/
          end
          it 'knife upload --purge . uploads everything' do
            knife('upload --purge .').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
          it 'knife upload --purge * uploads everything' do
            knife('upload --purge *').should_succeed <<EOM
Created x/added.json
Updated x/modified.json
Deleted extra entry x/deleted.json (purge is on)
EOM
            knife('diff --name-status /data_bags').should_succeed ''
          end
        end
      end
    end

    # Cookbook upload is a funny thing ... direct cookbook upload works, but
    # upload of a file is designed not to work at present.  Make sure that is the
    # case.
    when_the_chef_server 'has a cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'z.rb' => '' }

      when_the_repository 'has a modified, extra and missing file for the cookbook' do
        file 'cookbooks/x-1.0.0/metadata.rb', 'version  "1.0.0"'
        file 'cookbooks/x-1.0.0/y.rb', 'hi'

        it 'knife upload of any individual file fails' do
          knife('upload /cookbooks/x-1.0.0/metadata.rb').should_fail "ERROR: /cookbooks/x-1.0.0/metadata.rb cannot be updated.\n"
          knife('upload /cookbooks/x-1.0.0/y.rb').should_fail "ERROR: /cookbooks/x-1.0.0 cannot have a child created under it.\n"
          knife('upload --purge /cookbooks/x-1.0.0/z.rb').should_fail "ERROR: /cookbooks/x-1.0.0/z.rb cannot be deleted.\n"
        end

        # TODO this is a bit of an inconsistency: if we didn't specify --purge,
        # technically we shouldn't have deleted missing files.  But ... cookbooks
        # are a special case.
        it 'knife upload of the cookbook itself succeeds' do
          knife('upload /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end

        it 'knife upload --purge of the cookbook itself succeeds' do
          knife('upload /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_repository 'has a missing file for the cookbook' do
        file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'

        it 'knife upload of the cookbook succeeds' do
          knife('upload /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_repository 'has an extra file for the cookbook' do
        file 'cookbooks/x-1.0.0/metadata.rb', 'version "1.0.0"'
        file 'cookbooks/x-1.0.0/z.rb', ''
        file 'cookbooks/x-1.0.0/blah.rb', ''

        it 'knife upload of the cookbook succeeds' do
          knife('upload /cookbooks/x-1.0.0').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
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

        it 'knife upload /cookbooks uploads the local version' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
M\t/cookbooks/x-1.0.0/onlyin1.0.0.rb
D\t/cookbooks/x-1.0.1
EOM
          knife('upload --purge /cookbooks').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
Deleted extra entry /cookbooks/x-1.0.1 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook' do
        cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }
        it 'knife upload /cookbooks uploads the local version' do
          knife('upload --purge /cookbooks').should_succeed <<EOM
Updated /cookbooks/x-1.0.0
Deleted extra entry /cookbooks/x-0.9.9 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has a later version for the cookbook, and no current version' do
        cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

        it 'knife upload /cookbooks/x uploads the local version' do
          knife('diff --name-status /cookbooks').should_succeed <<EOM
D\t/cookbooks/x-1.0.1
A\t/cookbooks/x-1.0.0
EOM
          knife('upload --purge /cookbooks').should_succeed <<EOM
Created /cookbooks/x-1.0.0
Deleted extra entry /cookbooks/x-1.0.1 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end

      when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
        cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

        it 'knife upload /cookbooks/x uploads the new version' do
          knife('upload --purge /cookbooks').should_succeed <<EOM
Created /cookbooks/x-1.0.0
Deleted extra entry /cookbooks/x-0.9.9 (purge is on)
EOM
          knife('diff --name-status /cookbooks').should_succeed ''
        end
      end
    end

    when_the_chef_server 'has an environment' do
      environment 'x', {}
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife upload tries and fails' do
          knife('upload /environments/x.json').should_fail "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\nERROR: /environments/x.json failed to write: Parse error reading JSON: A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed "M\t/environments/x.json\n", :stderr => "WARN: Parse error reading #{path_to('environments/x.json')} as JSON: A JSON text must at least contain two octets!\n"
        end
      end

      when_the_repository 'has the same environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife upload fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments/x.json failed to write: Name must be 'x' (is 'y')\n"
          knife('diff --name-status /environments/x.json').should_succeed "M\t/environments/x.json\n"
        end
      end

      when_the_repository 'has the same environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife upload succeeds' do
          knife('upload /environments/x.json').should_succeed "Updated /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end
    end

    when_the_chef_server 'is empty' do
      when_the_repository 'has an environment with bad JSON' do
        file 'environments/x.json', '{'
        it 'knife upload tries and fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments failed to create_child: Parse error reading JSON creating child 'x.json': A JSON text must at least contain two octets!\n"
          knife('diff --name-status /environments/x.json').should_succeed "A\t/environments/x.json\n"
        end
      end

      when_the_repository 'has an environment with the wrong name in the file' do
        file 'environments/x.json', { 'name' => 'y' }
        it 'knife upload fails' do
          knife('upload /environments/x.json').should_fail "ERROR: /environments failed to create_child: Error creating 'x.json': Name must be 'x' (is 'y')\n"
          knife('diff --name-status /environments/x.json').should_succeed "A\t/environments/x.json\n"
        end
      end

      when_the_repository 'has an environment with no name in the file' do
        file 'environments/x.json', { 'description' => 'hi' }
        it 'knife upload succeeds' do
          knife('upload /environments/x.json').should_succeed "Created /environments/x.json\n"
          knife('diff --name-status /environments/x.json').should_succeed ''
        end
      end

      when_the_repository 'has a data bag with no id in the file' do
        file 'data_bags/bag/x.json', { 'foo' => 'bar' }
        it 'knife upload succeeds' do
          knife('upload /data_bags/bag/x.json').should_succeed "Created /data_bags/bag\nCreated /data_bags/bag/x.json\n"
          knife('diff --name-status /data_bags/bag/x.json').should_succeed ''
        end
      end
    end
  end # with versioned cookbooks

end
