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
        knife('upload --purge /').should_succeed(<<EOM, :stderr => "WARN: The default environment (_default.json) cannot be deleted.  Skipping.\n")
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
ERROR: remote/cookbooks cannot be deleted.
ERROR: remote/data_bags cannot be deleted.
ERROR: remote/environments cannot be deleted.
ERROR: remote/roles cannot be deleted.
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
end
