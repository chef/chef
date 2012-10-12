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
  let(:cookbooks_dir) { root_dir.child('cookbooks') }
  let(:should_list_cookbooks) do
    @rest.should_receive(:get_rest).with('cookbooks').once.and_return(
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
  it 'can have directories as children' do
    cookbooks_dir.can_have_child?('blah', true).should be_true
  end
  it 'cannot have files as children' do
    cookbooks_dir.can_have_child?('blah', false).should be_false
  end

  #
  # Cookbook dir (/cookbooks/<blah>)
  #
  shared_examples_for 'a segment directory' do
    it 'has cookbook as parent' do
      segment_dir.parent.should == cookbook_dir
    end
    it 'exists' do
      segment_dir.exists?.should be_true
    end
    it 'is a directory' do
      segment_dir.dir?.should be_true
    end
    it 'name is correct' do
      segment_dir.name.should == segment_dir_name
    end
    it 'path is correct' do
      segment_dir.path.should == "/cookbooks/#{cookbook_dir_name}/#{segment_dir_name}"
    end
    it 'path_for_printing is correct' do
      segment_dir.path_for_printing.should == "remote/cookbooks/#{cookbook_dir_name}/#{segment_dir_name}"
    end
    it 'has the right children' do
      segment_dir.children =~ %w(a.rb b.txt subdir)
    end
    it 'children are identical to child()' do
      segment_dir.child('a.rb').should == segment_dir.children.select { |child| child.name == 'a.rb' }.first
      segment_dir.child('b.txt').should == segment_dir.children.select { |child| child.name == 'b.txt' }.first
      segment_dir.child('subdir').should == segment_dir.children.select { |child| child.name == 'subdir' }.first
    end
    context 'subdirectory' do
      it 'has segment as a parent' do
        segment_dir.child('subdir').parent.should == segment_dir
      end
      it 'exists' do
        segment_dir.child('subdir').exists?.should be_true
      end
      it 'is a directory' do
        segment_dir.child('subdir').dir?.should be_true
      end
      it 'name is subdir' do
        segment_dir.child('subdir').name.should == 'subdir'
      end
      it 'path is correct' do
        segment_dir.child('subdir').path.should == "/cookbooks/#{cookbook_dir_name}/#{segment_dir_name}/subdir"
      end
      it 'path_for_printing is correct' do
        segment_dir.child('subdir').path_for_printing.should == "remote/cookbooks/#{cookbook_dir_name}/#{segment_dir_name}/subdir"
      end
      it 'has the right children' do
        segment_dir.child('subdir').children =~ %w(a.rb b.txt)
      end
      it 'children are identical to child()' do
        segment_dir.child('subdir').child('a.rb').should == segment_dir.child('subdir').children.select { |child| child.name == 'a.rb' }.first
        segment_dir.child('subdir').child('b.txt').should == segment_dir.child('subdir').children.select { |child| child.name == 'b.txt' }.first
      end
    end
  end

  shared_examples_for 'a cookbook' do
    it 'has cookbooks as parent' do
      cookbook_dir.parent == cookbooks_dir
    end
    it 'is a directory' do
      should_list_cookbooks
      cookbook_dir.dir?.should be_true
    end
    it 'exists' do
      should_list_cookbooks
      cookbook_dir.exists?.should be_true
    end
    it 'has name <cookbook name>' do
      cookbook_dir.name.should == cookbook_dir_name
    end
    it 'has path /cookbooks/<cookbook name>' do
      cookbook_dir.path.should == "/cookbooks/#{cookbook_dir_name}"
    end
    it 'has path_for_printing remote/cookbooks/<cookbook name>' do
      cookbook_dir.path_for_printing.should == "remote/cookbooks/#{cookbook_dir_name}"
    end
    it 'can have segment directories as children' do
      cookbook_dir.can_have_child?('attributes', true).should be_true
      cookbook_dir.can_have_child?('definitions', true).should be_true
      cookbook_dir.can_have_child?('recipes', true).should be_true
      cookbook_dir.can_have_child?('libraries', true).should be_true
      cookbook_dir.can_have_child?('templates', true).should be_true
      cookbook_dir.can_have_child?('files', true).should be_true
      cookbook_dir.can_have_child?('resources', true).should be_true
      cookbook_dir.can_have_child?('providers', true).should be_true
    end
    it 'cannot have arbitrary directories as children' do
      cookbook_dir.can_have_child?('blah', true).should be_false
      cookbook_dir.can_have_child?('root_files', true).should be_false
    end
    it 'can have files as children' do
      cookbook_dir.can_have_child?('blah', false).should be_true
      cookbook_dir.can_have_child?('root_files', false).should be_true
      cookbook_dir.can_have_child?('attributes', false).should be_true
      cookbook_dir.can_have_child?('definitions', false).should be_true
      cookbook_dir.can_have_child?('recipes', false).should be_true
      cookbook_dir.can_have_child?('libraries', false).should be_true
      cookbook_dir.can_have_child?('templates', false).should be_true
      cookbook_dir.can_have_child?('files', false).should be_true
      cookbook_dir.can_have_child?('resources', false).should be_true
      cookbook_dir.can_have_child?('providers', false).should be_true
    end
    # TODO test empty parts, cross-contamination (root_files named templates/x.txt, libraries named recipes/blah.txt)
    context 'with a full directory structure' do
      def json_file(path, checksum)
        filename = Chef::ChefFS::PathUtils.split(path)[-1]
        {
          :name => filename,
          :url => "cookbook_file:#{path}",
          :checksum => checksum,
          :path => path,
          :specificity => "default"
        }
      end
      def json_files(cookbook_dir)
        result = []
        files.each do |filename|
          if filename =~ /^#{cookbook_dir}\//
            result << json_file(filename, file_checksums[filename])
          end
        end
        result
      end
      let(:files) {
        result = []
        %w(attributes definitions files libraries providers recipes resources templates).each do |segment|
          result << "#{segment}/a.rb"
          result << "#{segment}/b.txt"
          result << "#{segment}/subdir/a.rb"
          result << "#{segment}/subdir/b.txt"
        end
        result << 'a.rb'
        result << 'b.txt'
        result << 'subdir/a.rb'
        result << 'subdir/b.txt'
        result << 'root_files'
        result
      }
      let(:file_checksums) {
        result = {}
        files.each_with_index do |file, i|
          result[file] = i.to_s(16)
        end
        result
      }
      let(:should_get_cookbook) do
        cookbook = double('cookbook')
        cookbook.should_receive(:manifest).and_return({
          :attributes => json_files('attributes'),
          :definitions => json_files('definitions'),
          :files => json_files('files'),
          :libraries => json_files('libraries'),
          :providers => json_files('providers'),
          :recipes => json_files('recipes'),
          :resources => json_files('resources'),
          :templates => json_files('templates'),
          :root_files => [
            json_file('a.rb', file_checksums['a.rb']),
            json_file('b.txt', file_checksums['b.txt']),
            json_file('subdir/a.rb', file_checksums['subdir/a.rb']),
            json_file('subdir/b.txt', file_checksums['subdir/b.txt']),
            json_file('root_files', file_checksums['root_files'])
          ]
        })
        @rest.should_receive(:get_rest).with("cookbooks/#{cookbook_dir_name}/_latest").once.and_return(cookbook)
      end

      it 'has correct children' do
        should_get_cookbook
        cookbook_dir.children.map { |child| child.name }.should =~ %w(attributes definitions files libraries providers recipes resources templates a.rb b.txt subdir root_files)
      end
      it 'children and child() yield the exact same objects' do
        should_get_cookbook
        cookbook_dir.children.each { |child| child.should == cookbook_dir.child(child.name) }
      end
      it 'all files exist (recursive) and have correct parent, path, path_for_printing, checksum and type' do
        should_get_cookbook
        file_checksums.each do |path, checksum|
          file = Chef::ChefFS::FileSystem.resolve_path(cookbook_dir, path)
          file_parts = path.split('/')
          if file_parts.length == 3
            file.parent.parent.parent.should == cookbook_dir
          elsif file_parts.length == 2
            file.parent.parent.should == cookbook_dir
          else
            file.parent.should == cookbook_dir
          end
          file.exists?.should be_true
          file.dir?.should be_false
          file.name.should == file_parts[-1]
          file.path.should == "/cookbooks/#{cookbook_dir_name}/#{path}"
          file.path_for_printing.should == "remote/cookbooks/#{cookbook_dir_name}/#{path}"
          file.checksum.should == checksum
        end
      end
      it 'all files can be read' do
        should_get_cookbook
        files.each do |path|
          @rest.should_receive(:get_rest).with("cookbook_file:#{path}").once.and_return("This is #{path}'s content")
          @rest.should_receive(:sign_on_redirect).with(no_args()).once.and_return(true)
          @rest.should_receive(:sign_on_redirect=).with(false).once
          @rest.should_receive(:sign_on_redirect=).with(true).once
          file = Chef::ChefFS::FileSystem.resolve_path(cookbook_dir, path)
          file.read.should == "This is #{path}'s content"
        end
      end

      context 'the attributes segment' do
        let(:segment_dir) { cookbook_dir.child('attributes') }
        let(:segment_dir_name) { 'attributes' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          should_get_cookbook
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          should_get_cookbook
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'cannot have subdirectories' do
          should_get_cookbook
          segment_dir.can_have_child?('blah', true).should be_false
        end
      end

      context 'the definitions segment' do
        let(:segment_dir) { cookbook_dir.child('definitions') }
        let(:segment_dir_name) { 'definitions' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'cannot have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_false
        end
      end

      context 'the files segment' do
        let(:segment_dir) { cookbook_dir.child('files') }
        let(:segment_dir_name) { 'files' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'can have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_true
          segment_dir.can_have_child?('.blah.txt', false).should be_true
        end
        it 'can have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_true
        end
        it 'subdirectories can have ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.rb', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.rb', false).should be_true
        end
        it 'subdirectories can have non-ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.txt', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.txt', false).should be_true
        end
        it 'subdirectories can have subdirectories' do
          segment_dir.child('subdir').can_have_child?('blah', true).should be_true
        end
      end

      context 'the libraries segment' do
        let(:segment_dir) { cookbook_dir.child('libraries') }
        let(:segment_dir_name) { 'libraries' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'cannot have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_false
        end
      end

      context 'the providers segment' do
        let(:segment_dir) { cookbook_dir.child('providers') }
        let(:segment_dir_name) { 'providers' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'can have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_true
        end
        it 'subdirectories can have ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.rb', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.rb', false).should be_true
        end
        it 'subdirectories cannot have non-ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.txt', false).should be_false
          segment_dir.child('subdir').can_have_child?('.blah.txt', false).should be_false
        end
        it 'subdirectories can have subdirectories' do
          segment_dir.child('subdir').can_have_child?('blah', true).should be_true
        end
      end

      context 'the recipes segment' do
        let(:segment_dir) { cookbook_dir.child('recipes') }
        let(:segment_dir_name) { 'recipes' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'cannot have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_false
        end
      end

      context 'the resources segment' do
        let(:segment_dir) { cookbook_dir.child('resources') }
        let(:segment_dir_name) { 'resources' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'cannot have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_false
          segment_dir.can_have_child?('.blah.txt', false).should be_false
        end
        it 'can have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_true
        end
        it 'subdirectories can have ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.rb', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.rb', false).should be_true
        end
        it 'subdirectories cannot have non-ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.txt', false).should be_false
          segment_dir.child('subdir').can_have_child?('.blah.txt', false).should be_false
        end
        it 'subdirectories can have subdirectories' do
          segment_dir.child('subdir').can_have_child?('blah', true).should be_true
        end
      end

      context 'the templates segment' do
        let(:segment_dir) { cookbook_dir.child('templates') }
        let(:segment_dir_name) { 'templates' }
        it_behaves_like 'a segment directory'

        before(:each) do
          should_get_cookbook
        end

        it 'can have ruby files' do
          segment_dir.can_have_child?('blah.rb', false).should be_true
          segment_dir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'can have non-ruby files' do
          segment_dir.can_have_child?('blah.txt', false).should be_true
          segment_dir.can_have_child?('.blah.txt', false).should be_true
        end
        it 'can have subdirectories' do
          segment_dir.can_have_child?('blah', true).should be_true
        end
        it 'subdirectories can have ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.rb', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.rb', false).should be_true
        end
        it 'subdirectories can have non-ruby files' do
          segment_dir.child('subdir').can_have_child?('blah.txt', false).should be_true
          segment_dir.child('subdir').can_have_child?('.blah.txt', false).should be_true
        end
        it 'subdirectories can have subdirectories' do
          segment_dir.child('subdir').can_have_child?('blah', true).should be_true
        end
      end

      context 'root subdirectories' do
        let(:root_subdir) { cookbook_dir.child('subdir') }

        before(:each) do
          should_get_cookbook
        end

        # Really, since these shouldn't exist in the first place,
        # it doesn't matter; but these REALLY shouldn't be able to
        # have any files in them at all.
        it 'can have ruby files' do
          root_subdir.can_have_child?('blah.rb', false).should be_true
          root_subdir.can_have_child?('.blah.rb', false).should be_true
        end
        it 'can have non-ruby files' do
          root_subdir.can_have_child?('blah.txt', false).should be_true
          root_subdir.can_have_child?('.blah.txt', false).should be_true
        end
        it 'cannot have subdirectories' do
          root_subdir.can_have_child?('blah', true).should be_false
        end
      end
    end
  end

  context 'achild from cookbooks_dir.children' do
    let(:cookbook_dir_name) { 'achild' }
    let(:cookbook_dir) do
      should_list_cookbooks
      cookbooks_dir.children.select { |child| child.name == 'achild' }.first
    end
    it_behaves_like 'a cookbook'
  end
  context 'cookbooks_dir.child(achild)' do
    let(:cookbook_dir_name) { 'achild' }
    let(:cookbook_dir) { cookbooks_dir.child('achild') }
    it_behaves_like 'a cookbook'
  end
  context 'nonexistent cookbooks_dir.child()' do
    let(:nonexistent_child) { cookbooks_dir.child('blah') }
    it 'has correct parent, name, path and path_for_printing' do
      nonexistent_child.parent.should == cookbooks_dir
      nonexistent_child.name.should == "blah"
      nonexistent_child.path.should == "/cookbooks/blah"
      nonexistent_child.path_for_printing.should == "remote/cookbooks/blah"
    end
    it 'does not exist' do
      should_list_cookbooks
      nonexistent_child.exists?.should be_false
    end
    it 'is a directory' do
      should_list_cookbooks
      nonexistent_child.dir?.should be_false
    end
    it 'read returns NotFoundError' do
      expect { nonexistent_child.read }.to raise_error(Chef::ChefFS::FileSystem::NotFoundError)
    end
  end

end
