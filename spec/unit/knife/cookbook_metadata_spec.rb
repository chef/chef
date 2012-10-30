#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2011 Thomas Bishop
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

describe Chef::Knife::CookbookMetadata do
  before(:each) do
    @knife = Chef::Knife::CookbookMetadata.new
    @knife.name_args = ['foobar']
    @cookbook_dir = Dir.mktmpdir
    @json_data = '{ "version": "1.0.0" }'
    @stdout = StringIO.new
    @stderr = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.ui.stub!(:stderr).and_return(@stderr)
  end

  describe 'run' do
    it 'should print an error and exit if a cookbook name was not provided' do
      @knife.name_args = []
      @knife.ui.should_receive(:error).with(/you must specify the cookbook.+use the --all/i)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should print an error and exit if an empty cookbook name was provided' do
      @knife.name_args = ['']
      @knife.ui.should_receive(:error).with(/you must specify the cookbook.+use the --all/i)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should generate the metadata for the cookbook' do
      @knife.should_receive(:generate_metadata).with('foobar')
      @knife.run
    end

    describe 'with -a or --all' do
      before(:each) do
        @knife.config[:all] = true
        @foo = Chef::CookbookVersion.new('foo')
        @foo.version = '1.0.0'
        @bar = Chef::CookbookVersion.new('bar')
        @bar.version = '2.0.0'
        @cookbook_loader = {
          "foo" => @foo,
          "bar" => @bar
        }
        @cookbook_loader.should_receive(:load_cookbooks).and_return(@cookbook_loader)
        @knife.should_receive(:generate_metadata).with('foo')
        @knife.should_receive(:generate_metadata).with('bar')
      end

      it 'should generate the metadata for each cookbook' do
        Chef::Config[:cookbook_path] = @cookbook_dir
        Chef::CookbookLoader.should_receive(:new).with(@cookbook_dir).and_return(@cookbook_loader)
        @knife.run
      end

      describe 'and with -o or --cookbook-path' do
        it 'should look in the provided path and generate cookbook metadata' do
          @knife.config[:cookbook_path] = '/opt/chef/cookbooks'
          Chef::CookbookLoader.should_receive(:new).with('/opt/chef/cookbooks').and_return(@cookbook_loader)
          @knife.run
        end
      end
    end

  end

  describe 'generate_metadata' do
    before(:each) do
      @knife.config[:cookbook_path] = @cookbook_dir
      File.stub!(:expand_path).with("#{@cookbook_dir}/foobar/metadata.rb").
                                    and_return("#{@cookbook_dir}/foobar/metadata.rb")
    end

    it 'should generate the metadata from metadata.rb if it exists' do
      File.should_receive(:exists?).with("#{@cookbook_dir}/foobar/metadata.rb").
                                    and_return(true)
      @knife.should_receive(:generate_metadata_from_file).with('foobar', "#{@cookbook_dir}/foobar/metadata.rb")
      @knife.run
    end

    it 'should validate the metadata json if metadata.rb does not exist' do
      File.should_receive(:exists?).with("#{@cookbook_dir}/foobar/metadata.rb").
                                    and_return(false)
      @knife.should_receive(:validate_metadata_json).with(@cookbook_dir, 'foobar')
      @knife.run
    end
  end

  describe 'generate_metadata_from_file' do
    before(:each) do
      @metadata_mock = mock('metadata')
      @json_file_mock = mock('json_file')
    end

    it 'should generate the metatdata json from metatdata.rb' do
      Chef::Cookbook::Metadata.stub!(:new).and_return(@metadata_mock)
      @metadata_mock.should_receive(:name).with('foobar')
      @metadata_mock.should_receive(:from_file).with("#{@cookbook_dir}/foobar/metadata.rb")
      File.should_receive(:open).with("#{@cookbook_dir}/foobar/metadata.json", 'w').
                                 and_yield(@json_file_mock)
      @json_file_mock.should_receive(:write).with(@json_data)
      Chef::JSONCompat.should_receive(:to_json_pretty).with(@metadata_mock).
                                                       and_return(@json_data)
      @knife.generate_metadata_from_file('foobar', "#{@cookbook_dir}/foobar/metadata.rb")
      @stdout.string.should match /generating metadata for foobar from #{@cookbook_dir}\/foobar\/metadata\.rb/im
    end

    { Chef::Exceptions::ObsoleteDependencySyntax => 'obsolote dependency',
      Chef::Exceptions::InvalidVersionConstraint => 'invalid version constraint'
    }.each_pair do |klass, description|
      it "should print an error and exit when an #{description} syntax exception is encountered" do
        exception = klass.new("#{description} blah")
        Chef::Cookbook::Metadata.stub!(:new).and_raise(exception)
        lambda {
          @knife.generate_metadata_from_file('foobar', "#{@cookbook_dir}/foobar/metadata.rb")
        }.should raise_error(SystemExit)
        @stderr.string.should match /error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im
        @stderr.string.should match /in #{@cookbook_dir}\/foobar\/metadata\.rb/im
        @stderr.string.should match /#{description} blah/im
      end
    end
  end

  describe 'validate_metadata_json' do
    it 'should validate the metadata json' do
      File.should_receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
                                   and_return(true)
      IO.should_receive(:read).with("#{@cookbook_dir}/foobar/metadata.json").
                               and_return(@json_data)
      Chef::Cookbook::Metadata.should_receive(:validate_json).with(@json_data)
      @knife.validate_metadata_json(@cookbook_dir, 'foobar')
    end

    it 'should not try to validate the metadata json if the file does not exist' do
      File.should_receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
                                   and_return(false)
      IO.should_not_receive(:read)
      Chef::Cookbook::Metadata.should_not_receive(:validate_json)
      @knife.validate_metadata_json(@cookbook_dir, 'foobar')
    end

    { Chef::Exceptions::ObsoleteDependencySyntax => 'obsolote dependency',
      Chef::Exceptions::InvalidVersionConstraint => 'invalid version constraint'
    }.each_pair do |klass, description|
      it "should print an error and exit when an #{description} syntax exception is encountered" do
        File.should_receive(:exist?).with("#{@cookbook_dir}/foobar/metadata.json").
                                     and_return(true)
        IO.should_receive(:read).with("#{@cookbook_dir}/foobar/metadata.json").
                                 and_return(@json_data)
        exception = klass.new("#{description} blah")
        Chef::Cookbook::Metadata.stub!(:validate_json).and_raise(exception)
        lambda {
          @knife.validate_metadata_json(@cookbook_dir, 'foobar')
        }.should raise_error(SystemExit)
        @stderr.string.should match /error: the cookbook 'foobar' contains invalid or obsolete metadata syntax/im
        @stderr.string.should match /in #{@cookbook_dir}\/foobar\/metadata\.json/im
        @stderr.string.should match /#{description} blah/im
      end
    end
  end

end
