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
require 'chef/chef_fs/file_system'

describe Chef::ChefFS::FileSystem::CookbooksDir do
  let(:root_dir) {
    Chef::ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key'
    },
    'everything')
  }

  let(:cookbook_response) do
      {
        "achild" => {
          "url" => "http://example.com/cookbooks/achild",
          'versions' => [
            { "version" => '2.0.0', 'url' => 'http://example.com/cookbooks/achild/2.0.0' },
            { "version" => '1.0.0', 'url' => 'http://example.com/cookbooks/achild/2.0.0' }, ] },
        "bchild" => {
          "url" => "http://example.com/cookbokks/bchild",
          'versions' => [ { "version" => '1.0.0', 'url' => 'http://example.com/cookbooks/achild/2.0.0' }, ] },

      }
  end

  let(:cookbooks_dir) { root_dir.child('cookbooks') }
  let(:api_url) { 'cookbooks' }
  let(:should_list_cookbooks) { rest.should_receive(:get_rest).with(api_url).once.and_return(cookbook_response) }

  let(:rest)  { double 'rest' }
  before(:each) { Chef::REST.stub(:new).with('url','username','key') { rest } }

  it 'has / as parent' do
    cookbooks_dir.parent.should == root_dir
  end

  it 'is a directory' do
    cookbooks_dir.dir?.should be_true
  end

  it 'exists' do
    cookbooks_dir.exists?.should be_true
  end

  it 'has name cookbooks' do
    cookbooks_dir.name.should == 'cookbooks'
  end

  it 'has path /cookbooks' do
    cookbooks_dir.path.should == '/cookbooks'
  end

  it 'has path_for_printing remote/cookbooks' do
    cookbooks_dir.path_for_printing.should == 'remote/cookbooks'
  end

  it 'has correct children' do
    should_list_cookbooks
    cookbooks_dir.children.map { |child| child.name }.should =~ %w(achild bchild)
  end

  describe '#can_have_child?' do
    it 'can have directories as children' do
      cookbooks_dir.can_have_child?('blah', true).should be_true
    end
    it 'cannot have files as children' do
      cookbooks_dir.can_have_child?('blah', false).should be_false
    end
  end

  describe '#children' do
    subject { cookbooks_dir.children }
    before(:each) { should_list_cookbooks }

    let(:entity_names)   { subject.map(&:name) }
    let(:cookbook_names) { subject.map(&:cookbook_name) }
    let(:versions)       { subject.map(&:version) }

    context 'with versioned cookbooks' do
      before(:each) { Chef::Config[:versioned_cookbooks] = true }
      after(:each)  { Chef::Config[:versioned_cookbooks] = false }

      let(:api_url) { 'cookbooks/?num_versions=all' }

      it 'should return all versions of cookbooks in <cookbook_name>-<version> format' do
        entity_names.should include('achild-2.0.0')
        entity_names.should include('achild-1.0.0')
        entity_names.should include('bchild-1.0.0')
      end

      it 'should return cookbooks with server canonical cookbook name' do
        cookbook_names.should include('achild')
        cookbook_names.should include('bchild')
      end

      it 'should return cookbooks with version numbers' do
        versions.should include('2.0.0')
        versions.should include('1.0.0')
        versions.uniq.size.should eql 2
      end
    end

    context 'without versioned cookbooks' do
      it 'should return a single version for each cookbook' do
        entity_names.should include('achild')
        entity_names.should include('bchild')
      end

      it "should return cookbooks '_latest' for version numbers" do
        versions.should include('_latest')
        versions.uniq.size.should eql 1
      end
    end
  end

end
