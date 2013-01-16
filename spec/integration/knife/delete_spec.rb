require 'support/shared/integration/integration_helper'
require 'chef/knife/delete'
require 'chef/knife/list'

describe 'knife delete' do
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

    let :everything do
      <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/environments/x.json
/roles
/roles/x.json
EOM
    end

    let :nothing do
      <<EOM
/cookbooks
/data_bags
/environments
/roles
EOM
    end

    when_the_repository 'has only top-level directories' do
      directory 'clients'
      directory 'cookbooks'
      directory 'data_bags'
      directory 'environments'
      directory 'nodes'
      directory 'roles'
      directory 'users'

      it 'knife delete / fails' do
        knife('delete /').should_fail "ERROR: / (remote) cannot be deleted.\nERROR: / (local) cannot be deleted.\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete -r /* fails' do
        knife('delete -r /*').should_fail <<EOM
ERROR: / (remote) cannot be deleted.
ERROR: / (local) cannot be deleted.
ERROR: /cookbooks (remote) cannot be deleted.
ERROR: /cookbooks (local) cannot be deleted.
ERROR: /data_bags (remote) cannot be deleted.
ERROR: /data_bags (local) cannot be deleted.
ERROR: /environments (remote) cannot be deleted.
ERROR: /environments (local) cannot be deleted.
ERROR: /roles (remote) cannot be deleted.
ERROR: /roles (local) cannot be deleted.
EOM
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete /cookbooks/x fails' do
        knife('delete /cookbooks/x').should_fail "ERROR: /cookbooks/x (remote) must be deleted recursively!  Pass -r to knife delete.\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete -r /cookbooks/x deletes x' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('list -Rf /').should_succeed <<EOM
/cookbooks
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/environments/x.json
/roles
/roles/x.json
EOM
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete /data_bags/x fails' do
        knife('delete /data_bags/x').should_fail "ERROR: /data_bags/x (remote) must be deleted recursively!  Pass -r to knife delete.\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete -r /data_bags/x deletes x' do
        knife('delete -r /data_bags/x').should_succeed "Deleted /data_bags/x\n"
        knife('list -Rf /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/environments
/environments/_default.json
/environments/x.json
/roles
/roles/x.json
EOM
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete /environments/x.json deletes x' do
        knife('delete /environments/x.json').should_succeed "Deleted /environments/x.json\n"
        knife('list -Rf /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/roles
/roles/x.json
EOM
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete /roles/x.json deletes x' do
        knife('delete /roles/x.json').should_succeed "Deleted /roles/x.json\n"
        knife('list -Rf /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/environments/x.json
/roles
EOM
        knife('list -Rf --local /').should_succeed nothing
      end

      it 'knife delete /environments/_default.json fails' do
        knife('delete /environments/_default.json').should_fail "", :stderr => "ERROR: /environments/_default.json (remote) cannot be deleted (default environment cannot be modified).\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed nothing
      end

      context 'and cwd is at the top level' do
        cwd '.'
        it 'knife delete fails' do
          knife('delete').should_fail "FATAL: Must specify at least one argument.  If you want to delete everything in this directory, type \"knife delete --recurse .\"\n", :stdout => /USAGE/
          knife('list -Rf /').should_succeed <<EOM
cookbooks
cookbooks/x
cookbooks/x/metadata.rb
data_bags
data_bags/x
data_bags/x/y.json
environments
environments/_default.json
environments/x.json
roles
roles/x.json
EOM
          knife('list -Rf --local /').should_succeed <<EOM
cookbooks
data_bags
environments
roles
EOM
        end
      end
    end
  end
end
