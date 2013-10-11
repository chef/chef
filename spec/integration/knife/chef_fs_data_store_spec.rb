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
require 'chef/knife/list'
require 'chef/knife/delete'
require 'chef/knife/show'
require 'chef/knife/raw'
require 'chef/knife/cookbook_upload'

describe 'knife raw -z' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_repository "has one of each thing" do
    file 'clients/x.json', {}
    file 'cookbooks/x/metadata.rb', 'version "1.0.0"'
    file 'data_bags/x/y.json', {}
    file 'environments/x.json', {}
    file 'nodes/x.json', {}
    file 'roles/x.json', {}
    file 'users/x.json', {}

    context 'GET /TYPE' do
      it 'knife list -z -R returns everything' do
        knife('list -z -Rfp /').should_succeed <<EOM
/clients/
/clients/x.json
/cookbooks/
/cookbooks/x/
/cookbooks/x/metadata.rb
/data_bags/
/data_bags/x/
/data_bags/x/y.json
/environments/
/environments/x.json
/nodes/
/nodes/x.json
/roles/
/roles/x.json
/users/
/users/x.json
EOM
      end
    end

    context 'DELETE /TYPE/NAME' do
      it 'knife delete -z /clients/x.json works' do
        knife('delete -z /clients/x.json').should_succeed "Deleted /clients/x.json\n"
        knife('list -z -Rfp /clients').should_succeed ''
      end

      it 'knife delete -z -r /cookbooks/x works' do
        knife('delete -z -r /cookbooks/x').should_succeed "Deleted /cookbooks/x\n"
        knife('list -z -Rfp /cookbooks').should_succeed ''
      end

      it 'knife delete -z -r /data_bags/x works' do
        knife('delete -z -r /data_bags/x').should_succeed "Deleted /data_bags/x\n"
        knife('list -z -Rfp /data_bags').should_succeed ''
      end

      it 'knife delete -z /data_bags/x/y.json works' do
        knife('delete -z /data_bags/x/y.json').should_succeed "Deleted /data_bags/x/y.json\n"
        knife('list -z -Rfp /data_bags').should_succeed "/data_bags/x/\n"
      end

      it 'knife delete -z /environments/x.json works' do
        knife('delete -z /environments/x.json').should_succeed "Deleted /environments/x.json\n"
        knife('list -z -Rfp /environments').should_succeed ''
      end

      it 'knife delete -z /nodes/x.json works' do
        knife('delete -z /nodes/x.json').should_succeed "Deleted /nodes/x.json\n"
        knife('list -z -Rfp /nodes').should_succeed ''
      end

      it 'knife delete -z /roles/x.json works' do
        knife('delete -z /roles/x.json').should_succeed "Deleted /roles/x.json\n"
        knife('list -z -Rfp /roles').should_succeed ''
      end

      it 'knife delete -z /users/x.json works' do
        knife('delete -z /users/x.json').should_succeed "Deleted /users/x.json\n"
        knife('list -z -Rfp /users').should_succeed ''
      end
    end

    context 'GET /TYPE/NAME' do
      it 'knife show -z /clients/x.json works' do
        knife('show -z /clients/x.json').should_succeed /"x"/
      end

      it 'knife show -z /cookbooks/x/metadata.rb works' do
        knife('show -z /cookbooks/x/metadata.rb').should_succeed "/cookbooks/x/metadata.rb:\nversion \"1.0.0\"\n"
      end

      it 'knife show -z /data_bags/x/y.json works' do
        knife('show -z /data_bags/x/y.json').should_succeed /"y"/
      end

      it 'knife show -z /environments/x.json works' do
        knife('show -z /environments/x.json').should_succeed /"x"/
      end

      it 'knife show -z /nodes/x.json works' do
        knife('show -z /nodes/x.json').should_succeed /"x"/
      end

      it 'knife show -z /roles/x.json works' do
        knife('show -z /roles/x.json').should_succeed /"x"/
      end

      it 'knife show -z /users/x.json works' do
        knife('show -z /users/x.json').should_succeed /"x"/
      end
    end

    context 'PUT /TYPE/NAME' do
      file 'empty.json', {}
      file 'cookbooks_to_upload/x/metadata.rb', "version '1.0.0'\n\n"

      it 'knife raw -z -i empty.json -m PUT /clients/x' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /clients/x").should_succeed /"x"/
        knife('list --local /clients').should_succeed "/clients/x.json\n"
      end

      it 'knife cookbook upload works' do
        knife("cookbook upload -z --cookbook-path #{path_to('cookbooks_to_upload')} x").should_succeed <<EOM
Uploading x              [1.0.0]
Uploaded 1 cookbook.
EOM
        knife('list --local -Rfp /cookbooks').should_succeed "/cookbooks/x/\n/cookbooks/x/metadata.rb\n"
      end

      it 'knife raw -z -i empty.json -m PUT /data/x/y' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /data/x/y").should_succeed /"y"/
        knife('list --local -Rfp /data_bags').should_succeed "/data_bags/x/\n/data_bags/x/y.json\n"
      end

      it 'knife raw -z -i empty.json -m PUT /environments/x' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /environments/x").should_succeed /"x"/
        knife('list --local /environments').should_succeed "/environments/x.json\n"
      end

      it 'knife raw -z -i empty.json -m PUT /nodes/x' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /nodes/x").should_succeed /"x"/
        knife('list --local /nodes').should_succeed "/nodes/x.json\n"
      end

      it 'knife raw -z -i empty.json -m PUT /roles/x' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /roles/x").should_succeed /"x"/
        knife('list --local /roles').should_succeed "/roles/x.json\n"
      end

      it 'knife raw -z -i empty.json -m PUT /users/x' do
        knife("raw -z -i #{path_to('empty.json')} -m PUT /users/x").should_succeed /"x"/
        knife('list --local /users').should_succeed "/users/x.json\n"
      end
    end
  end

  when_the_repository 'is empty' do
    context 'POST /TYPE/NAME' do
      file 'empty.json', { 'name' => 'z' }
      file 'empty_id.json', { 'id' => 'z' }
      file 'cookbooks_to_upload/z/metadata.rb', "version '1.0.0'"

      it 'knife raw -z -i empty.json -m POST /clients' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /clients").should_succeed /uri/
        knife('list --local /clients').should_succeed "/clients/z.json\n"
      end

      it 'knife cookbook upload works' do
        knife("cookbook upload -z --cookbook-path #{path_to('cookbooks_to_upload')} z").should_succeed <<EOM
Uploading z            [1.0.0]
Uploaded 1 cookbook.
EOM
        knife('list --local -Rfp /cookbooks').should_succeed "/cookbooks/z/\n/cookbooks/z/metadata.rb\n"
      end

      it 'knife raw -z -i empty.json -m POST /data' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /data").should_succeed /uri/
        knife('list --local -Rfp /data_bags').should_succeed "/data_bags/z/\n"
      end

      it 'knife raw -z -i empty.json -m POST /data/x' do
        knife("raw -z -i #{path_to('empty_id.json')} -m POST /data/x").should_succeed /"z"/
        knife('list --local -Rfp /data_bags').should_succeed "/data_bags/x/\n/data_bags/x/z.json\n"
      end

      it 'knife raw -z -i empty.json -m POST /environments' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /environments").should_succeed /uri/
        knife('list --local /environments').should_succeed "/environments/z.json\n"
      end

      it 'knife raw -z -i empty.json -m POST /nodes' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /nodes").should_succeed /uri/
        knife('list --local /nodes').should_succeed "/nodes/z.json\n"
      end

      it 'knife raw -z -i empty.json -m POST /roles' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /roles").should_succeed /uri/
        knife('list --local /roles').should_succeed "/roles/z.json\n"
      end

      it 'knife raw -z -i empty.json -m POST /users' do
        knife("raw -z -i #{path_to('empty.json')} -m POST /users").should_succeed /uri/
        knife('list --local /users').should_succeed "/users/z.json\n"
      end
    end
  end
end
