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

describe Chef::Knife::CookbookDownload do
  before(:each) do
    @knife = Chef::Knife::CookbookDownload.new
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do
    it 'should print usage and exit when a cookbook name is not provided' do
      @knife.name_args = []
      @knife.should_receive(:show_usage)
      @knife.ui.should_receive(:fatal).with(/must specify a cookbook name/)
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    it 'should exit with a fatal error when there is no cookbook on the server' do
      @knife.name_args = ['foobar', nil]
      @knife.should_receive(:determine_version).and_return(nil)
      @knife.ui.should_receive(:fatal).with('No such cookbook found')
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe 'with a cookbook name' do
      before(:each) do
        @knife.name_args = ['foobar']
        @knife.config[:download_directory] = '/var/tmp/chef'
        @rest_mock = mock('rest')
        @knife.stub(:rest).and_return(@rest_mock)

        @manifest_data = {
          :recipes => [
            {'path' => 'recipes/foo.rb',
             'url' => 'http://example.org/files/foo.rb'},
            {'path' => 'recipes/bar.rb',
             'url' => 'http://example.org/files/bar.rb'}
          ],
          :templates => [
            {'path' => 'templates/default/foo.erb',
             'url' => 'http://example.org/files/foo.erb'},
            {'path' => 'templates/default/bar.erb',
             'url' => 'http://example.org/files/bar.erb'}
          ],
          :attributes => [
            {'path' => 'attributes/default.rb',
             'url' => 'http://example.org/files/default.rb'}
          ]
        }

        @cookbook_mock = mock('cookbook')
        @cookbook_mock.stub!(:version).and_return('1.0.0')
        @cookbook_mock.stub!(:manifest).and_return(@manifest_data)
        @rest_mock.should_receive(:get_rest).with('cookbooks/foobar/1.0.0').
                                             and_return(@cookbook_mock)
      end

      it 'should determine which version if one was not explicitly specified'do
        @cookbook_mock.stub!(:manifest).and_return({})
        @knife.should_receive(:determine_version).and_return('1.0.0')
        File.should_receive(:exists?).with('/var/tmp/chef/foobar-1.0.0').and_return(false)
        Chef::CookbookVersion.stub!(:COOKBOOK_SEGEMENTS).and_return([])
        @knife.run
      end

      describe 'and a version' do
        before(:each) do
          @knife.name_args << '1.0.0'
          @files = @manifest_data.values.map { |v| v.map { |i| i['path'] } }.flatten.uniq
          @files_mocks = {}
          @files.map { |f| File.basename(f) }.flatten.uniq.each do |f|
            @files_mocks[f] = mock("#{f}_mock")
            @files_mocks[f].stub!(:path).and_return("/var/tmp/#{f}")
          end
        end

        it 'should print an error and exit if the cookbook download directory already exists' do
          File.should_receive(:exists?).with('/var/tmp/chef/foobar-1.0.0').and_return(true)
          @knife.ui.should_receive(:fatal).with(/\/var\/tmp\/chef\/foobar-1\.0\.0 exists/i)
          lambda { @knife.run }.should raise_error(SystemExit)
        end

        describe 'when downloading the cookbook' do
          before(:each) do
            @files.map { |f| File.dirname(f) }.flatten.uniq.each do |dir|
              FileUtils.should_receive(:mkdir_p).with("/var/tmp/chef/foobar-1.0.0/#{dir}").
              at_least(:once)
            end

            @files_mocks.each_pair do |file, mock|
              @rest_mock.should_receive(:get_rest).with("http://example.org/files/#{file}", true).
              and_return(mock)
            end

            @rest_mock.should_receive(:sign_on_redirect=).with(false).at_least(:once)
            @files.each do |f|
              FileUtils.should_receive(:mv).
                        with("/var/tmp/#{File.basename(f)}", "/var/tmp/chef/foobar-1.0.0/#{f}")
            end
          end

          it "should download the cookbook when the cookbook download directory doesn't exist" do
            File.should_receive(:exists?).with('/var/tmp/chef/foobar-1.0.0').and_return(false)
            @knife.run
            ['attributes', 'recipes', 'templates'].each do |segment|
              @stdout.string.should match /downloading #{segment}/im
            end
            @stdout.string.should match /downloading foobar cookbook version 1\.0\.0/im
            @stdout.string.should match /cookbook downloaded to \/var\/tmp\/chef\/foobar-1\.0\.0/im
          end

          describe 'with -f or --force' do
            it 'should remove the existing the cookbook download directory if it exists' do
              @knife.config[:force] = true
              File.should_receive(:exists?).with('/var/tmp/chef/foobar-1.0.0').and_return(true)
              FileUtils.should_receive(:rm_rf).with('/var/tmp/chef/foobar-1.0.0')
              @knife.run
            end
          end
        end

      end
    end

  end

  describe 'determine_version' do

    it 'should return nil if there are no versions' do
      @knife.should_receive(:available_versions).and_return(nil)
      @knife.determine_version.should == nil
      @knife.version.should == nil
    end

    it 'should return and set the version if there is only one version' do
      @knife.should_receive(:available_versions).at_least(:once).and_return(['1.0.0'])
      @knife.determine_version.should == '1.0.0'
      @knife.version.should == '1.0.0'
    end

    it 'should ask which version to download and return it if there is more than one' do
      @knife.should_receive(:available_versions).at_least(:once).and_return(['1.0.0', '2.0.0'])
      @knife.should_receive(:ask_which_version).and_return('1.0.0')
      @knife.determine_version.should == '1.0.0'
    end

    describe 'with -N or --latest' do
      it 'should return and set the version to the latest version' do
        @knife.config[:latest] = true
        @knife.should_receive(:available_versions).at_least(:once).
                                                   and_return(['1.0.0', '1.1.0', '2.0.0'])
        @knife.determine_version
        @knife.version.to_s.should == '2.0.0'
      end
    end
  end

  describe 'available_versions' do
    before(:each) do
      @knife.cookbook_name = 'foobar'
    end

    it 'should return nil if there are no versions' do
      Chef::CookbookVersion.should_receive(:available_versions).
                            with('foobar').
                            and_return(nil)
      @knife.available_versions.should == nil
    end

    it 'should return the available versions' do
      Chef::CookbookVersion.should_receive(:available_versions).
                            with('foobar').
                            and_return(['1.1.0', '2.0.0', '1.0.0'])
      @knife.available_versions.should == [Chef::Version.new('1.0.0'),
                                           Chef::Version.new('1.1.0'),
                                           Chef::Version.new('2.0.0')]
    end

    it 'should avoid multiple API calls to the server' do
      Chef::CookbookVersion.should_receive(:available_versions).
                            once.
                            with('foobar').
                            and_return(['1.1.0', '2.0.0', '1.0.0'])
      @knife.available_versions
      @knife.available_versions
    end
  end

  describe 'ask_which_version' do
    before(:each) do
      @knife.cookbook_name = 'foobar'
      @knife.stub!(:available_versions).and_return(['1.0.0', '1.1.0', '2.0.0'])
    end

    it 'should prompt the user to select a version' do
      prompt = /Which version do you want to download\?.+1\. foobar 1\.0\.0.+2\. foobar 1\.1\.0.+3\. foobar 2\.0\.0.+/m
      @knife.should_receive(:ask_question).with(prompt).and_return('1')
      @knife.ask_which_version
    end

    it "should set the version to the user's selection" do
      @knife.should_receive(:ask_question).and_return('1')
      @knife.ask_which_version
      @knife.version.should == '1.0.0'
    end

    it "should print an error and exit if a version wasn't specified" do
      @knife.should_receive(:ask_question).and_return('')
      @knife.ui.should_receive(:error).with(/is not a valid value/i)
      lambda { @knife.ask_which_version }.should raise_error(SystemExit)
    end

    it 'should print an error if an invalid choice was selected' do
      @knife.should_receive(:ask_question).and_return('100')
      @knife.ui.should_receive(:error).with(/'100' is not a valid value/i)
      lambda { @knife.ask_which_version }.should raise_error(SystemExit)
    end
  end

end
