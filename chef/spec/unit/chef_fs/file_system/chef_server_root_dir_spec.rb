#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
#

require 'spec_helper'
require 'chef/chef_fs/file_system/chef_server_root_dir'

describe Chef::ChefFS::FileSystem::ChefServerRootDir do
  shared_examples 'a json endpoint dir leaf' do
    it 'parent is endpoint' do
      endpoint_leaf.parent.should == endpoint
    end
    it 'name is correct' do
      endpoint_leaf.name.should == "#{endpoint_leaf_name}.json"
    end
    it 'path is correct' do
      endpoint_leaf.path.should == "/#{endpoint_name}/#{endpoint_leaf_name}.json"
    end
    it 'path_for_printing is correct' do
      endpoint_leaf.path_for_printing.should == "remote/#{endpoint_name}/#{endpoint_leaf_name}.json"
    end
    it 'is not a directory' do
      endpoint_leaf.dir?.should be_false
    end
    it 'exists' do
      should_receive_children
      endpoint_leaf.exists?.should be_true
    end
    it 'read returns content' do
      @rest.should_receive(:get_rest).with("#{endpoint_name}/#{endpoint_leaf_name}").once.and_return(
        {
          'a' => 'b'
        })
      endpoint_leaf.read.should == '{
  "a": "b"
}'
    end
  end

  shared_examples 'a json rest endpoint dir' do
    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has correct name' do
      endpoint.name.should == endpoint_name
    end
    it 'has correct path' do
      endpoint.path.should == "/#{endpoint_name}"
    end
    it 'has correct path_for_printing' do
      endpoint.path_for_printing.should == "remote/#{endpoint_name}"
    end
    it 'is a directory' do
      endpoint.dir?.should be_true
    end
    it 'exists' do
      endpoint.exists?.should be_true
    end
    it 'can have json files as children' do
      endpoint.can_have_child?('blah.json', false).should be_true
    end
    it 'cannot have non-json files as children' do
      endpoint.can_have_child?('blah', false).should be_false
    end
    it 'cannot have directories as children' do
      endpoint.can_have_child?('blah', true).should be_false
      endpoint.can_have_child?('blah.json', true).should be_false
    end
    let(:should_receive_children) {
      @rest.should_receive(:get_rest).with(endpoint_name).once.and_return(
        {
          "achild" => "http://opscode.com/achild",
          "bchild" => "http://opscode.com/bchild"
        })
    }
    it 'has correct children' do
      should_receive_children
      endpoint.children.map { |child| child.name }.should =~ %w(achild.json bchild.json)
    end
    context 'achild in endpoint.children' do
      let(:endpoint_leaf_name) { 'achild' }
      let(:endpoint_leaf) do
        should_receive_children
        endpoint.children.select { |child| child.name == 'achild.json' }.first
      end
      it_behaves_like 'a json endpoint dir leaf'
    end
    context 'endpoint.child(achild)' do
      let(:endpoint_leaf_name) { 'achild' }
      let(:endpoint_leaf) { endpoint.child('achild.json') }
      it_behaves_like 'a json endpoint dir leaf'
    end
    context 'nonexistent child()' do
      let(:nonexistent_child) { endpoint.child('blah.json') }
      it 'has correct parent, name, path and path_for_printing' do
        nonexistent_child.parent.should == endpoint
        nonexistent_child.name.should == "blah.json"
        nonexistent_child.path.should == "#{endpoint.path}/blah.json"
        nonexistent_child.path_for_printing.should == "#{endpoint.path_for_printing}/blah.json"
      end
      it 'does not exist' do
        should_receive_children
        nonexistent_child.exists?.should be_false
      end
      it 'is not a directory' do
        nonexistent_child.dir?.should be_false
      end
      it 'read returns NotFoundError' do
        @rest.should_receive(:get_rest).with("#{endpoint_name}/blah").once.and_raise(Net::HTTPServerException.new(nil,Net::HTTPResponse.new(nil,'404',nil)))
        expect { nonexistent_child.read }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
      end
    end
  end

  let(:root_dir) {
    Chef::ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key'
    }, 'everything')
  }
  before(:each) do
    @rest = double("rest")
    Chef::REST.stub(:new).with('url','username','key') { @rest }
  end
  context 'the root directory' do
    it 'has no parent' do
      root_dir.parent.should == nil
    end
    it 'is a directory' do
      root_dir.dir?.should be_true
    end
    it 'exists' do
      root_dir.exists?.should be_true
    end
    it 'has name ""' do
      root_dir.name.should == ""
    end
    it 'has path /' do
      root_dir.path.should == '/'
    end
    it 'has path_for_printing remote/' do
      root_dir.path_for_printing.should == 'remote/'
    end
    it 'has correct children' do
      root_dir.children.map { |child| child.name }.should =~ %w(clients cookbooks data_bags environments nodes roles users)
    end
    it 'can have children with the known names' do
      %w(clients cookbooks data_bags environments nodes roles users).each { |child| root_dir.can_have_child?(child, true).should be_true }
    end
    it 'cannot have files as children' do
      %w(clients cookbooks data_bags environments nodes roles users).each { |child| root_dir.can_have_child?(child, false).should be_false }
      root_dir.can_have_child?('blah', false).should be_false
    end
    it 'cannot have other child directories than the known names' do
      root_dir.can_have_child?('blah', true).should be_false
    end
    it 'child() responds to children' do
      %w(clients cookbooks data_bags environments nodes roles users).each { |child| root_dir.child(child).exists?.should be_true }
    end
    context 'nonexistent child()' do
      let(:nonexistent_child) { root_dir.child('blah') }
      it 'has correct parent, name, path and path_for_printing' do
        nonexistent_child.parent.should == root_dir
        nonexistent_child.name.should == "blah"
        nonexistent_child.path.should == "/blah"
        nonexistent_child.path_for_printing.should == "remote/blah"
      end
      it 'does not exist' do
        nonexistent_child.exists?.should be_false
      end
      it 'is not a directory' do
        nonexistent_child.dir?.should be_false
      end
      it 'read returns NotFoundError' do
        expect { nonexistent_child.read }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
      end
    end
  end

  context 'clients in children' do
    let(:endpoint_name) { 'clients' }
    let(:endpoint) { root_dir.children.select { |child| child.name == 'clients' }.first }

    it_behaves_like 'a json rest endpoint dir'
  end

  context 'root.child(clients)' do
    let(:endpoint_name) { 'clients' }
    let(:endpoint) { root_dir.child('clients') }

    it_behaves_like 'a json rest endpoint dir'
  end

  context 'root.child(environments)' do
    let(:endpoint_name) { 'environments' }
    let(:endpoint) { root_dir.child('environments') }

    it_behaves_like 'a json rest endpoint dir'
  end

  context 'root.child(nodes)' do
    let(:endpoint_name) { 'nodes' }
    let(:endpoint) { root_dir.child('nodes') }

    it_behaves_like 'a json rest endpoint dir'
  end

  context 'root.child(roles)' do
    let(:endpoint_name) { 'roles' }
    let(:endpoint) { root_dir.child('roles') }

    it_behaves_like 'a json rest endpoint dir'
  end

  context 'root.child(users)' do
    let(:endpoint_name) { 'users' }
    let(:endpoint) { root_dir.child('users') }

    it_behaves_like 'a json rest endpoint dir'
  end
end
