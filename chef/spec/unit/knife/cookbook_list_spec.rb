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

describe Chef::Knife::CookbookList do
  before do
    @knife = Chef::Knife::CookbookList.new
    @rest_mock = mock('rest')
    @knife.stub!(:rest).and_return(@rest_mock)
    @cookbook_names = ['apache2', 'mysql']
    @base_url = 'https://server.example.com/cookbooks'
    @cookbook_data = {}
    @cookbook_names.each do |item|
      @cookbook_data[item] = {'url' => "#{@base_url}/#{item}",
                              'versions' => [{'version' => '1.0.1',
                                              'url' => "#{@base_url}/#{item}/1.0.1"}]}
    end
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe 'run' do
    it 'should display the latest version of the cookbooks' do
      @rest_mock.should_receive(:get_rest).with('/cookbooks?num_versions=1').
                                           and_return(@cookbook_data)
      @knife.run
      @cookbook_names.each do |item|
        @stdout.string.should match /#{item}\s+1\.0\.1/
      end
    end

    it 'should query cookbooks for the configured environment' do
      @knife.config[:environment] = 'production'
      @rest_mock.should_receive(:get_rest).
                 with('/environments/production/cookbooks?num_versions=1').
                 and_return(@cookbook_data)
      @knife.run
    end

    describe 'with -w or --with-uri' do
      it 'should display the cookbook uris' do
        @knife.config[:with_uri] = true
        @rest_mock.stub(:get_rest).and_return(@cookbook_data)
        @knife.run
        @cookbook_names.each do |item|
          pattern = /#{Regexp.escape(@cookbook_data[item]['versions'].first['url'])}/
          @stdout.string.should match pattern
        end
      end
    end

    describe 'with -a or --all' do
      before do
        @cookbook_names.each do |item|
          @cookbook_data[item]['versions'] << {'version' => '1.0.0',
                                               'url' => "#{@base_url}/#{item}/1.0.0"}
        end
      end

      it 'should display all versions of the cookbooks' do
        @knife.config[:all_versions] = true
        @rest_mock.should_receive(:get_rest).with('/cookbooks?num_versions=all').
                                             and_return(@cookbook_data)
        @knife.run
        @cookbook_names.each do |item|
          @stdout.string.should match /#{item}\s+1\.0\.1\s+1\.0\.0/
        end
      end
    end

  end
end
