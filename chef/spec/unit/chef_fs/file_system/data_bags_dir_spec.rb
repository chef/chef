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

describe Chef::ChefFS::FileSystem::DataBagsDir do
  let(:root_dir) {
    Chef::ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key'
    }, 'everything')
  }
  let(:data_bags_dir) { root_dir.child('data_bags') }
  let(:should_list_data_bags) do
    @rest.should_receive(:get_rest).with('data').once.and_return(
      {
        "achild" => "http://opscode.com/achild",
        "bchild" => "http://opscode.com/bchild"
      })
  end
  before(:each) do
    @rest = double("rest")
    Chef::REST.stub(:new).with('url','username','key') { @rest }
  end

  it 'has / as parent' do
    data_bags_dir.parent.should == root_dir
  end
  it 'is a directory' do
    data_bags_dir.dir?.should be_true
  end
  it 'exists' do
    data_bags_dir.exists?.should be_true
  end
  it 'has name data_bags' do
    data_bags_dir.name.should == 'data_bags'
  end
  it 'has path /data_bags' do
    data_bags_dir.path.should == '/data_bags'
  end
  it 'has path_for_printing remote/data_bags' do
    data_bags_dir.path_for_printing.should == 'remote/data_bags'
  end
  it 'has correct children' do
    should_list_data_bags
    data_bags_dir.children.map { |child| child.name }.should =~ %w(achild bchild)
  end
  it 'can have directories as children' do
    data_bags_dir.can_have_child?('blah', true).should be_true
  end
  it 'cannot have files as children' do
    data_bags_dir.can_have_child?('blah', false).should be_false
  end

  shared_examples_for 'a data bag item' do
    it 'has data bag as parent' do
      data_bag_item.parent.should == data_bag_dir
    end
    it 'is not a directory' do
      data_bag_item.dir?.should be_false
    end
    it 'exists' do
      should_list_data_bag_items
      data_bag_item.exists?.should be_true
    end
    it 'has correct name' do
      data_bag_item.name.should == data_bag_item_name
    end
    it 'has correct path' do
      data_bag_item.path.should == "/data_bags/#{data_bag_dir_name}/#{data_bag_item_name}"
    end
    it 'has correct path_for_printing' do
      data_bag_item.path_for_printing.should == "remote/data_bags/#{data_bag_dir_name}/#{data_bag_item_name}"
    end
    it 'reads correctly' do
      @rest.should_receive(:get_rest).with("data/#{data_bag_dir_name}/#{data_bag_item_short_name}").once.and_return({
        'a' => 'b'
      })
      data_bag_item.read.should == '{
  "a": "b"
}'
    end
  end

  shared_examples_for 'a data bag' do
    let(:should_list_data_bag_items) do
      @rest.should_receive(:get_rest).with("data/#{data_bag_dir_name}").once.and_return(
      {
        "aitem" => "http://opscode.com/achild",
        "bitem" => "http://opscode.com/bchild"
      })
    end
    it 'has /data as a parent' do
      data_bag_dir.parent.should == data_bags_dir
    end
    it 'is a directory' do
      should_list_data_bags
      data_bag_dir.dir?.should be_true
    end
    it 'exists' do
      should_list_data_bags
      data_bag_dir.exists?.should be_true
    end
    it 'has correct name' do
      data_bag_dir.name.should == data_bag_dir_name
    end
    it 'has correct path' do
      data_bag_dir.path.should == "/data_bags/#{data_bag_dir_name}"
    end
    it 'has correct path_for_printing' do
      data_bag_dir.path_for_printing.should == "remote/data_bags/#{data_bag_dir_name}"
    end
    it 'has correct children' do
      should_list_data_bag_items
      data_bag_dir.children.map { |child| child.name }.should =~ %w(aitem.json bitem.json)
    end
    it 'can have json files as children' do
      data_bag_dir.can_have_child?('blah.json', false).should be_true
    end
    it 'cannot have non-json files as children' do
      data_bag_dir.can_have_child?('blah', false).should be_false
    end
    it 'cannot have directories as children' do
      data_bag_dir.can_have_child?('blah', true).should be_false
      data_bag_dir.can_have_child?('blah.json', true).should be_false
    end
    context 'aitem from data_bag.children' do
      let(:data_bag_item) do
        should_list_data_bag_items
        data_bag_dir.children.select { |child| child.name == 'aitem.json' }.first
      end
      let(:data_bag_item_short_name) { 'aitem' }
      let(:data_bag_item_name) { 'aitem.json' }
      it_behaves_like 'a data bag item'
    end
    context 'data_bag.child(aitem)' do
      let(:data_bag_item) { data_bag_dir.child('aitem.json') }
      let(:data_bag_item_short_name) { 'aitem' }
      let(:data_bag_item_name) { 'aitem.json' }
      it_behaves_like 'a data bag item'
    end
    context 'nonexistent child()' do
      let(:nonexistent_child) { data_bag_dir.child('blah.json') }
      it 'has correct parent, name, path and path_for_printing' do
        nonexistent_child.parent.should == data_bag_dir
        nonexistent_child.name.should == "blah.json"
        nonexistent_child.path.should == "/data_bags/#{data_bag_dir_name}/blah.json"
        nonexistent_child.path_for_printing.should == "remote/data_bags/#{data_bag_dir_name}/blah.json"
      end
      it 'does not exist' do
        should_list_data_bag_items
        nonexistent_child.exists?.should be_false
      end
      it 'is not a directory' do
        nonexistent_child.dir?.should be_false
      end
      it 'read returns NotFoundError' do
        @rest.should_receive(:get_rest).with("data/#{data_bag_dir_name}/blah").once.and_raise(Net::HTTPServerException.new(nil,Net::HTTPResponse.new(nil,'404',nil)))
        expect { nonexistent_child.read }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
      end
    end
  end

  context 'achild from data_bags.children' do
    let(:data_bag_dir) do
      should_list_data_bags
      data_bags_dir.children.select { |child| child.name == 'achild' }.first
    end
    let(:data_bag_dir_name) { 'achild' }
    it_behaves_like 'a data bag'
  end

  context 'data_bags.child(achild)' do
    let(:data_bag_dir) do
      data_bags_dir.child('achild')
    end
    let(:data_bag_dir_name) { 'achild' }
    it_behaves_like 'a data bag'
  end

  context 'nonexistent child()' do
    let(:nonexistent_child) { data_bags_dir.child('blah') }
    it 'has correct parent, name, path and path_for_printing' do
      nonexistent_child.parent.should == data_bags_dir
      nonexistent_child.name.should == "blah"
      nonexistent_child.path.should == "/data_bags/blah"
      nonexistent_child.path_for_printing.should == "remote/data_bags/blah"
    end
    it 'does not exist' do
      should_list_data_bags
      nonexistent_child.exists?.should be_false
    end
    it 'is not a directory' do
      should_list_data_bags
      nonexistent_child.dir?.should be_false
    end
    it 'read returns NotFoundError' do
      expect { nonexistent_child.read }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
    end
  end

end
