#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com.com>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookList do
  before(:each) do
    @knife = Chef::Knife::CookbookList.new
    @rest_mock = mock('rest')
    @knife.stub!(:rest).and_return(@rest_mock)
    @cookbooks = ['foo', 'bar']
  end

  describe 'run' do
    before(:each) do
      @knife.should_receive(:format_cookbook_list_for_display).with(@cookbooks).
                                                               and_return(@cookbooks)
      @cookbooks.each do |cookbook|
        @knife.ui.should_receive(:msg).with(cookbook)
      end
    end

    it 'should display the latest version of the cookbooks' do
      @rest_mock.should_receive(:get_rest).with('/cookbooks?num_versions=1').
                                           and_return(@cookbooks)
      @knife.run
    end

    it 'should display the cookbooks for the configured environment' do
      @knife.config[:environment] = 'production'
      @rest_mock.should_receive(:get_rest).with('/environments/production/cookbooks?num_versions=1').
                                           and_return(@cookbooks)
      @knife.run
    end

    describe 'with -a or --all' do
      it 'should display all versions of the cookbooks' do
        @knife.config[:all_versions] = true
        @rest_mock.should_receive(:get_rest).with('/cookbooks?num_versions=all').
                                             and_return(@cookbooks)
        @knife.run
      end
    end

  end
end
