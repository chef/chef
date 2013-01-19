require 'support/shared/integration/integration_helper'
require 'chef/knife/diff'

describe 'knife diff' do
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

      it 'knife diff reports everything as deleted' do
        knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks/x
D\t/data_bags/x
D\t/environments/_default.json
D\t/environments/x.json
D\t/roles/x.json
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

      it 'knife diff reports no differences' do
        knife('diff /').should_succeed ''
      end

      it 'knife diff /environments/nonexistent.json reports an error' do
        knife('diff /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory on remote or local\n"
      end

      it 'knife diff /environments/*.txt reports an error' do
        knife('diff /environments/*.txt').should_fail "ERROR: /environments/*.txt: No such file or directory on remote or local\n"
      end

      context 'except the role file' do
        file 'roles/x.json', <<EOM
{
  "foo": "bar"
}
EOM
        it 'knife diff reports the role as different' do
          knife('diff --name-status /').should_succeed <<EOM
M\t/roles/x.json
EOM
        end
      end

      context 'as well as one extra copy of each thing' do
        file 'clients/y.json', {}
        file 'cookbooks/x/blah.rb', ''
        file 'cookbooks/y/metadata.rb', 'version "1.0.0"'
        file 'data_bags/x/z.json', {}
        file 'data_bags/y/zz.json', {}
        file 'environments/y.json', {}
        file 'nodes/y.json', {}
        file 'roles/y.json', {}
        file 'users/y.json', {}

        it 'knife diff reports the new files as added' do
          knife('diff --name-status /').should_succeed <<EOM
A\t/cookbooks/x/blah.rb
A\t/cookbooks/y
A\t/data_bags/x/z.json
A\t/data_bags/y
A\t/environments/y.json
A\t/roles/y.json
EOM
        end

        context 'when cwd is the data_bags directory' do
          cwd 'data_bags'
          it 'knife diff reports different data bags' do
            knife('diff --name-status').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
          end
          it 'knife diff * reports different data bags' do
            knife('diff --name-status *').should_succeed <<EOM
A\tx/z.json
A\ty
EOM
          end
        end
      end
    end

    when_the_repository 'is empty' do
      it 'knife diff reports everything as deleted' do
        knife('diff --name-status /').should_succeed <<EOM
D\t/cookbooks
D\t/data_bags
D\t/environments
D\t/roles
EOM
      end
    end
  end

  when_the_repository 'has a cookbook' do
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'cookbooks/x/onlyin1.0.0.rb', ''

    when_the_chef_server 'has a later version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => ''}
      cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => '' }

      it 'knife diff /cookbooks/x shows differences' do
        knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
      end
    end

    when_the_chef_server 'has an earlier version for the cookbook' do
      cookbook 'x', '1.0.0', { 'metadata.rb' => 'version "1.0.0"', 'onlyin1.0.0.rb' => '' }
      cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => '' }
      it 'knife diff /cookbooks/x shows no differences' do
        knife('diff --name-status /cookbooks/x').should_succeed ''
      end
    end

    when_the_chef_server 'has a later version for the cookbook, and no current version' do
      cookbook 'x', '1.0.1', { 'metadata.rb' => 'version "1.0.1"', 'onlyin1.0.1.rb' => '' }

      it 'knife diff /cookbooks/x shows the differences' do
        knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin1.0.1.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
      end
    end

    when_the_chef_server 'has an earlier version for the cookbook, and no current version' do
      cookbook 'x', '0.9.9', { 'metadata.rb' => 'version "0.9.9"', 'onlyin0.9.9.rb' => '' }

      it 'knife diff /cookbooks/x shows the differences' do
        knife('diff --name-status /cookbooks/x').should_succeed <<EOM
M\t/cookbooks/x/metadata.rb
D\t/cookbooks/x/onlyin0.9.9.rb
A\t/cookbooks/x/onlyin1.0.0.rb
EOM
      end
    end
  end
end
