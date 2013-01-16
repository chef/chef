require 'support/shared/integration/integration_helper'
require 'chef/knife/raw'

describe 'knife raw' do
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

    it 'knife raw /nodes/x returns the node' do
      knife('raw /nodes/x').should_succeed <<EOM
{
  "name": "x",
  "json_class": "Chef::Node",
  "chef_type": "node",
  "chef_environment": "_default",
  "override": {
  },
  "normal": {
  },
  "default": {
  },
  "automatic": {
  },
  "run_list": [

  ]
}
EOM
    end

    it 'knife raw /blarghle returns 404' do
      knife('raw /blarghle').should_fail(/ERROR: Server responded with error 404 "Not Found"/)
    end
  end
end
