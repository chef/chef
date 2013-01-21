require 'support/shared/integration/integration_helper'
require 'chef/knife/show'

describe 'knife show' do
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

    when_the_repository 'also has one of each thing' do
      file 'clients/x.json', { 'foo' => 'bar' }
      file 'cookbooks/x/metadata.rb', 'version "1.0.1"'
      file 'data_bags/x/y.json', { 'foo' => 'bar' }
      file 'environments/_default.json', { 'foo' => 'bar' }
      file 'environments/x.json', { 'foo' => 'bar' }
      file 'nodes/x.json', { 'foo' => 'bar' }
      file 'roles/x.json', { 'foo' => 'bar' }
      file 'users/x.json', { 'foo' => 'bar' }

      it 'knife show /cookbooks/x/metadata.rb shows the remote version' do
        knife('show /cookbooks/x/metadata.rb').should_succeed <<EOM
/cookbooks/x/metadata.rb:
version "1.0.0"
EOM
      end
      it 'knife show --local /cookbooks/x/metadata.rb shows the local version' do
        knife('show --local /cookbooks/x/metadata.rb').should_succeed <<EOM
/cookbooks/x/metadata.rb:
version "1.0.1"
EOM
      end
      it 'knife show /data_bags/x/y.json shows the remote version' do
        knife('show /data_bags/x/y.json').should_succeed <<EOM
/data_bags/x/y.json:
{
  "id": "y"
}
EOM
      end
      it 'knife show --local /data_bags/x/y.json shows the local version' do
        knife('show --local /data_bags/x/y.json').should_succeed <<EOM
/data_bags/x/y.json:
{
  "foo": "bar"
}
EOM
      end
      it 'knife show /environments/x.json shows the remote version', :pending => (RUBY_VERSION < "1.9") do
        knife('show /environments/x.json').should_succeed <<EOM
/environments/x.json:
{
  "name": "x",
  "description": "",
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
      end
      it 'knife show --local /environments/x.json shows the local version' do
        knife('show --local /environments/x.json').should_succeed <<EOM
/environments/x.json:
{
  "foo": "bar"
}
EOM
      end
      it 'knife show /roles/x.json shows the remote version', :pending => (RUBY_VERSION < "1.9") do
        knife('show /roles/x.json').should_succeed <<EOM
/roles/x.json:
{
  "name": "x",
  "description": "",
  "json_class": "Chef::Role",
  "default_attributes": {
  },
  "override_attributes": {
  },
  "chef_type": "role",
  "run_list": [

  ],
  "env_run_lists": {
  }
}
EOM
      end
      it 'knife show --local /roles/x.json shows the local version' do
        knife('show --local /roles/x.json').should_succeed <<EOM
/roles/x.json:
{
  "foo": "bar"
}
EOM
      end
      # show directory
      it 'knife show /data_bags/x fails' do
        knife('show /data_bags/x').should_fail "ERROR: /data_bags/x: is a directory\n"
      end
      it 'knife show --local /data_bags/x fails' do
        knife('show --local /data_bags/x').should_fail "ERROR: /data_bags/x: is a directory\n"
      end
      # show nonexistent file
      it 'knife show /environments/nonexistent.json fails' do
        knife('show /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
      end
      it 'knife show --local /environments/nonexistent.json fails' do
        knife('show --local /environments/nonexistent.json').should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
      end
    end
  end
end
