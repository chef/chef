#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2013 Sander Botman.
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

describe Chef::Knife::EnvironmentCompare do
  before(:each) do
    @knife = Chef::Knife::EnvironmentCompare.new
    
    @environments = {
      "cita" => "http://localhost:4000/environments/cita",
      "citm" => "http://localhost:4000/environments/citm"
    }

    @knife.stub(:environment_list).and_return(@environments)

    @constraints = {
      "cita" => { "foo" => "= 1.0.1", "bar" => "= 0.0.4" },
      "citm" => { "foo" => "= 1.0.1", "bar" => "= 0.0.2" }
    }
 
    @knife.stub(:constraint_list).and_return(@constraints)

    @cookbooks = { "foo"=>"= 1.0.1", "bar"=>"= 0.0.1" } 

    @knife.stub(:cookbook_list).and_return(@cookbooks)

    @rest_double = double('rest')
    @knife.stub(:rest).and_return(@rest_double)
    @cookbook_names = ['apache2', 'mysql', 'foo', 'bar', 'dummy', 'chef_handler']
    @base_url = 'https://server.example.com/cookbooks'
    @cookbook_data = {}
    @cookbook_names.each do |item|
      @cookbook_data[item] = {'url' => "#{@base_url}/#{item}",
                              'versions' => [{'version' => '1.0.1',
                                              'url' => "#{@base_url}/#{item}/1.0.1"}]}
    end 

    @rest_double.stub(:get_rest).with("/cookbooks?num_versions=1").and_return(@cookbook_data)

    @stdout = StringIO.new
    @knife.ui.stub(:stdout).and_return(@stdout)
  end

  describe 'run' do
    it 'should display only cookbooks with version constraints' do
      @knife.config[:format] = 'summary'
      @knife.run
      @environments.each do |item, url|
        @stdout.string.should match /#{item}/ and @stdout.string.lines.count.should be 4
      end
    end
 
    it 'should display 4 number of lines' do
      @knife.config[:format] = 'summary'
      @knife.run
      @stdout.string.lines.count.should be 4
    end
  end

  describe 'with -m or --mismatch' do
    it 'should display only cookbooks that have mismatching version constraints' do
      @knife.config[:format] = 'summary'
      @knife.config[:mismatch] = true
      @knife.run
      @constraints.each do |item, ver|
        @stdout.string.should match /#{ver[1]}/
      end
    end

    it 'should display 3 number of lines' do
      @knife.config[:format] = 'summary'
      @knife.config[:mismatch] = true
      @knife.run
      @stdout.string.lines.count.should be 3
    end
  end
 
  describe 'with -a or --all' do
    it 'should display all cookbooks' do
      @knife.config[:format] = 'summary'
      @knife.config[:all] = true
      @knife.run
      @constraints.each do |item, ver|
        @stdout.string.should match /#{ver[1]}/
      end
    end

    it 'should display 8 number of lines' do
      @knife.config[:format] = 'summary'
      @knife.config[:all] = true
      @knife.run
      @stdout.string.lines.count.should be 8
    end
  end

end
