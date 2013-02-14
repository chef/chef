require 'support/shared/integration/integration_helper'
require 'chef/knife/download'
require 'chef/knife/diff'

describe 'knife download' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "has one of each thing" do
    one_of_each_resource_in_chef_server

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
Created /cookbooks/x
Created /cookbooks/x/metadata.rb
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments/_default.json
Created /environments/x.json
Created /roles/x.json
EOM
        knife('diff --name-status /').should_succeed ''
      end
    end # when the repository has only top-level directories

    when_the_repository 'has an identical copy of each resource' do
      one_of_each_resource_in_repository

      it 'knife download makes no changes' do
        knife('download /').should_succeed ''
        knife('diff --name-status /').should_succeed ''
      end

      it 'knife download --purge makes no changes' do
        knife('download --purge /').should_succeed ''
        knife('diff --name-status /').should_succeed ''
      end
    end # when the repository has an identical copy of each resource

    when_the_repository 'has a different role file' do
      one_of_each_resource_in_repository
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
    end # when the repository has a different role file

    when_the_repository 'has a semantically equivalent role file' do
      one_of_each_resource_in_repository
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

    when_the_repository 'has resources not present in the server' do
      one_of_each_resource_in_repository
      file 'clients/y.json', { 'name' => 'y' }
      file 'cookbooks/x/blah.rb', ''
      file 'cookbooks/y/metadata.rb', 'version "1.0.0"'
      file 'data_bags/x/z.json', <<EOM
{
  "id": "z"
}
EOM
        file 'data_bags/y/zz.json', <<EOM
{
  "id": "zz"
}
EOM
        file 'environments/y.json', <<EOM
{
  "chef_type": "environment",
  "cookbook_versions": {
  },
  "default_attributes": {
  },
  "description": "",
  "json_class": "Chef::Environment",
  "name": "y",
  "override_attributes": {
  }
}
EOM
        file 'nodes/y.json', { 'name' => 'y' }
        file 'roles/y.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "description": "",
  "env_run_lists": {
  },
  "json_class": "Chef::Role",
  "name": "y",
  "override_attributes": {
  },
  "run_list": [

  ]
}
EOM
        file 'users/y.json', { 'name' => 'y' }

        it 'knife download does nothing' do
          knife('download /').should_succeed ''
          knife('diff --name-status /').should_succeed <<EOM
A\t/cookbooks/x/blah.rb
A\t/cookbooks/y
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/roles/y.json
EOM
        end

        it 'knife download --purge deletes the extra files' do
          knife('download --purge /').should_succeed <<EOM
Deleted extra entry /cookbooks/x/blah.rb (purge is on)
Deleted extra entry /cookbooks/y (purge is on)
Deleted extra entry /data_bags/x/z.json (purge is on)
Deleted extra entry /data_bags/y (purge is on)
Deleted extra entry /environments/y.json (purge is on)
Deleted extra entry /roles/y.json (purge is on)
EOM
          knife('diff --name-status /').should_succeed ''
        end
    end # when the repository has resources not present in the server

    when_the_repository 'is empty' do
      it 'knife download creates the extra files' do
        knife('download /').should_succeed <<EOM
Created /cookbooks
Created /cookbooks/x
Created /cookbooks/x/metadata.rb
Created /data_bags
Created /data_bags/x
Created /data_bags/x/y.json
Created /environments
Created /environments/_default.json
Created /environments/x.json
Created /roles
Created /roles/x.json
EOM
        knife('diff --name-status /').should_succeed ''
      end

      context 'when current directory is top level' do
        cwd '.'
        it 'knife download with no parameters reports an error' do
          knife('download').should_fail "FATAL: Must specify at least one argument.  If you want to download everything in this directory, type \"knife download .\"\n", :stdout => /USAGE/
        end
      end
    end # when the repository is empty
  end # when the chef server has one of each resource

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
end
