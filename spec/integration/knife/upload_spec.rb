require 'support/shared/integration/integration_helper'
require 'chef/knife/upload'
require 'chef/knife/diff'

describe 'knife upload' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server "has one of each thing" do
    client 'x', '{}'
    cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"' }
    data_bag 'x', { 'y' => '{}' }
    environment 'x', '{}'
    node 'x', '{}'
    role 'x', '{}'
    user 'x', '{}'

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
D\t/cookbooks/x
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/roles/x.json
EOM
      end

      it 'knife upload --purge deletes everything' do
        knife('upload --purge /').should_succeed(<<EOM, :stderr => "WARNING: /environments/_default.json cannot be deleted (default environment cannot be modified).\n")
Deleted extra entry /cookbooks/x (purge is on)
Deleted extra entry /data_bags/x (purge is on)
Deleted extra entry /environments/x.json (purge is on)
Deleted extra entry /roles/x.json (purge is on)
EOM
        knife('diff --name-status /').should_succeed <<EOM
D\t/environments/_default.json
EOM
      end
    end

    when_the_repository 'has an identical copy of each thing' do
      file 'clients/x.json', <<EOM
{}
EOM
      file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
      file 'data_bags/x/y.json', <<EOM
{
  "id": "y"
}
EOM
      file 'environments/_default.json', <<EOM
{
  "name": "_default",
  "description": "The default Chef environment",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
  },
  "override_attributes": {
  }
}
EOM
      file 'environments/x.json', <<EOM
{
  "chef_type": "environment",
  "cookbook_versions": {
  },
  "default_attributes": {
  },
  "description": "",
  "json_class": "Chef::Environment",
  "name": "x",
  "override_attributes": {
  }
}
EOM
      file 'nodes/x.json', <<EOM
{}
EOM
      file 'roles/x.json', <<EOM
{
  "chef_type": "role",
  "default_attributes": {
  },
  "description": "",
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
      file 'users/x.json', <<EOM
{}
EOM

      it 'knife upload makes no changes' do
        knife('upload /').should_succeed ''
        knife('diff --name-status /').should_succeed ''
      end

      it 'knife upload --purge makes no changes' do
        knife('upload --purge /').should_succeed ''
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
        it 'knife upload changes the role' do
          knife('upload /').should_succeed "Updated /roles/x.json\n"
          knife('diff --name-status /').should_succeed ''
        end
      end

      context 'as well as one extra copy of each thing' do
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

        it 'knife upload adds the new files' do
          knife('upload /').should_succeed <<EOM
Updated /cookbooks/x
Created /cookbooks/y
Created /data_bags/x/z.json
Created /data_bags/y
Created /data_bags/y/zz.json
Created /environments/y.json
Created /roles/y.json
EOM
          knife('diff --name-status /').should_succeed ''
        end
      end
    end

    when_the_repository 'is empty' do
      it 'knife upload does nothing' do
        knife('upload /').should_succeed ''
        knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/roles
EOM
      end

      it 'knife upload --purge deletes nothing' do
        knife('upload --purge /').should_fail <<EOM
ERROR: /cookbooks cannot be deleted.
ERROR: /data_bags cannot be deleted.
ERROR: /environments cannot be deleted.
ERROR: /roles cannot be deleted.
EOM
        knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/roles
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
      file 'data_bags/x/y.json', <<EOM
{
  "id": "y"
}
EOM
      file 'data_bags/x/z.json', <<EOM
{
  "id": "z"
}
EOM
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
      file 'data_bags/x/added.json', <<EOM
{
  "id": "added"
}
EOM
      file 'data_bags/x/modified.json', <<EOM
{
  "id": "modified",
  "foo": "bar"
}
EOM
      file 'data_bags/x/unmodified.json', <<EOM
{
  "id": "unmodified"
}
EOM
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
  end

  # Upload from a cwd
  # Upload with *'s
  # Upload with JSON that isn't *really* modified
  # Multiple cookbook versions!!!!
end
