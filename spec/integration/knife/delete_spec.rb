require 'support/shared/integration/integration_helper'
require 'chef/knife/delete'
require 'chef/knife/list'
require 'chef/knife/raw'

describe 'knife delete' do
  extend IntegrationSupport
  include KnifeSupport

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

  let :server_nothing do
    <<EOM
/cookbooks
/data_bags
/environments
/environments/_default.json
/roles
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

  when_the_chef_server "has one of each thing" do
    client 'x', '{}'
    cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"' }
    data_bag 'x', { 'y' => '{}' }
    environment 'x', '{}'
    node 'x', '{}'
    role 'x', '{}'
    user 'x', '{}'

    when_the_repository 'also has one of each thing' do
      file 'clients/x.json', {}
      file 'cookbooks/x/metadata.rb', ''
      file 'data_bags/x/y.json', {}
      file 'environments/_default.json', {}
      file 'environments/x.json', {}
      file 'nodes/x.json', {}
      file 'roles/x.json', {}
      file 'users/x.json', {}

      it 'knife delete /cookbooks/x fails' do
        knife('delete /cookbooks/x').should_fail <<EOM
ERROR: /cookbooks/x (remote) must be deleted recursively!  Pass -r to knife delete.
ERROR: /cookbooks/x (local) must be deleted recursively!  Pass -r to knife delete.
EOM
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed everything
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
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete -r --local-only /cookbooks/x deletes x locally but not remotely' do
        knife('delete -r --local-only /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete -r --remote-only /cookbooks/x deletes x remotely but not locally' do
        knife('delete -r --remote-only /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
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
        knife('list -Rf --local /').should_succeed everything
      end

      # TODO delete empty data bag (particularly different on local side)
      context 'with an empty data bag on both' do
        data_bag 'empty', {}
        directory 'data_bags/empty'
        it 'knife delete /data_bags/empty fails but deletes local version' do
          knife('delete /data_bags/empty').should_fail <<EOM
ERROR: /data_bags/empty (remote) must be deleted recursively!  Pass -r to knife delete.
ERROR: /data_bags/empty (local) must be deleted recursively!  Pass -r to knife delete.
EOM
          knife('list -Rf /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/empty
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/environments/x.json
/roles
/roles/x.json
EOM
          knife('list -Rf --local /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/empty
/data_bags/x
/data_bags/x/y.json
/environments
/environments/_default.json
/environments/x.json
/roles
/roles/x.json
EOM
        end
      end

      it 'knife delete /data_bags/x fails' do
        knife('delete /data_bags/x').should_fail <<EOM
ERROR: /data_bags/x (remote) must be deleted recursively!  Pass -r to knife delete.
ERROR: /data_bags/x (local) must be deleted recursively!  Pass -r to knife delete.
EOM
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed everything
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
        knife('list -Rf --local /').should_succeed <<EOM
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
        knife('list -Rf --local /').should_succeed <<EOM
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
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete /environments/_default.json fails but still deletes the local copy' do
        knife('delete /environments/_default.json').should_fail :stderr => "ERROR: /environments/_default.json (remote) cannot be deleted (default environment cannot be modified).\n", :stdout => "Deleted /environments/_default.json\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/x.json
/roles
/roles/x.json
EOM
      end

      it 'knife delete /environments/nonexistent.json fails' do
        knife('delete /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed everything
      end

      it 'knife delete / fails' do
        knife('delete /').should_fail <<EOM
ERROR: / (remote) cannot be deleted.
ERROR: / (local) cannot be deleted.
EOM
        knife('list -Rf /').should_succeed everything
        knife('list -Rf --local /').should_succeed everything
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
        knife('list -Rf --local /').should_succeed everything
      end
    end

    when_the_repository 'has only top-level directories' do
      directory 'clients'
      directory 'cookbooks'
      directory 'data_bags'
      directory 'environments'
      directory 'nodes'
      directory 'roles'
      directory 'users'

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

      it 'knife delete /environments/nonexistent.json fails' do
        knife('delete /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
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

  when_the_chef_server 'is empty' do
    when_the_repository 'has one of each thing' do
      file 'clients/x.json', {}
      file 'cookbooks/x/metadata.rb', ''
      file 'data_bags/x/y.json', {}
      file 'environments/_default.json', {}
      file 'environments/x.json', {}
      file 'nodes/x.json', {}
      file 'roles/x.json', {}
      file 'users/x.json', {}

      it 'knife delete /cookbooks/x fails' do
        knife('delete /cookbooks/x').should_fail "ERROR: /cookbooks/x (local) must be deleted recursively!  Pass -r to knife delete.\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed everything
      end

      it 'knife delete -r /cookbooks/x deletes x' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete /data_bags/x fails' do
        knife('delete /data_bags/x').should_fail "ERROR: /data_bags/x (local) must be deleted recursively!  Pass -r to knife delete.\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed everything
      end

      it 'knife delete -r /data_bags/x deletes x' do
        knife('delete -r /data_bags/x').should_succeed "Deleted /data_bags/x\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete /environments/x.json deletes x' do
        knife('delete /environments/x.json').should_succeed "Deleted /environments/x.json\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete /roles/x.json deletes x' do
        knife('delete /roles/x.json').should_succeed "Deleted /roles/x.json\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed <<EOM
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
      end

      it 'knife delete /environments/_default.json fails but still deletes the local copy' do
        knife('delete /environments/_default.json').should_fail :stderr => "ERROR: /environments/_default.json (remote) cannot be deleted (default environment cannot be modified).\n", :stdout => "Deleted /environments/_default.json\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed <<EOM
/cookbooks
/cookbooks/x
/cookbooks/x/metadata.rb
/data_bags
/data_bags/x
/data_bags/x/y.json
/environments
/environments/x.json
/roles
/roles/x.json
EOM
      end

      it 'knife delete / fails' do
        knife('delete /').should_fail "ERROR: / (remote) cannot be deleted.\nERROR: / (local) cannot be deleted.\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed everything
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
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed everything
      end

      it 'knife delete /environments/nonexistent.json fails' do
        knife('delete /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
        knife('list -Rf /').should_succeed server_nothing
        knife('list -Rf --local /').should_succeed everything
      end

      context 'and cwd is at the top level' do
        cwd '.'
        it 'knife delete fails' do
          knife('delete').should_fail "FATAL: Must specify at least one argument.  If you want to delete everything in this directory, type \"knife delete --recurse .\"\n", :stdout => /USAGE/
          knife('list -Rf /').should_succeed <<EOM
cookbooks
data_bags
environments
environments/_default.json
roles
EOM
          knife('list -Rf --local /').should_succeed <<EOM
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
        end
      end
    end
  end

  when_the_repository 'has a cookbook' do
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'cookbooks/x/onlyin1.0.0.rb', 'old_text'

    when_the_chef_server 'has a later version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => '' }
      cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

      # TODO this seems wrong
      it 'knife delete /cookbooks/x deletes the latest version on the server and the local version' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('raw /cookbooks/x').should_succeed(/1.0.0/)
        knife('list --local /cookbooks').should_succeed ''
      end
    end

    when_the_chef_server 'has an earlier version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
      cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

      it 'knife delete /cookbooks/x deletes the latest version on the server and the local version' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('raw /cookbooks/x').should_succeed(/0.9.9/)
        knife('list --local /cookbooks').should_succeed ''
      end
    end

    when_the_chef_server 'has a later version for the cookbook, and no current version' do
      cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => 'hi' }

      it 'knife delete /cookbooks/x deletes the server and client version of the cookbook' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('raw /cookbooks/x').should_fail(/404/)
        knife('list --local /cookbooks').should_succeed ''
      end
    end

    when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
      cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => 'hi' }

      it 'knife delete /cookbooks/x deletes the server and client version of the cookbook' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('raw /cookbooks/x').should_fail(/404/)
        knife('list --local /cookbooks').should_succeed ''
      end
    end
  end

  when_the_repository 'is empty' do
    when_the_chef_server 'has two versions of a cookbook' do
      cookbook 'x', '2.0.11', { 'metadata.rb' => 'version "2.0.11"' }
      cookbook 'x', '11.0.0', { 'metadata.rb' => 'version "11.0.0"' }
      it 'knife delete deletes the latest version' do
        knife('delete -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('raw /cookbooks/x').should_succeed /2.0.11/
      end
    end
  end
end
