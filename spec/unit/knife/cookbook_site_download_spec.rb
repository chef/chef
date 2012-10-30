#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2012 Thomas Bishop
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Chef::Knife::CookbookSiteDownload do

  describe 'run' do
    before do
      @knife            = Chef::Knife::CookbookSiteDownload.new
      @knife.name_args  = ['apache2']
      @noauth_rest      = mock 'no auth rest'
      @stdout           = StringIO.new
      @cookbook_api_url = 'http://cookbooks.opscode.com/api/v1/cookbooks'
      @version          = '1.0.2'
      @version_us       = @version.gsub '.', '_'
      @current_data     = { 'deprecated'       => false,
                            'latest_version'   => "#{@cookbook_api_url}/apache2/versions/#{@version_us}",
                            'replacement' => 'other_apache2' }

      @knife.ui.stub(:stdout).and_return(@stdout)
      @knife.stub(:noauth_rest).and_return(@noauth_rest)
      @noauth_rest.should_receive(:get_rest).
                   with("#{@cookbook_api_url}/apache2").
                   and_return(@current_data)
    end

    context 'when the cookbook is deprecated and not forced' do
      before do
        @current_data['deprecated'] = true
      end

      it 'should warn with info about the replacement' do
        @knife.ui.should_receive(:warn).
                  with(/.+deprecated.+replaced by other_apache2.+/i)
        @knife.ui.should_receive(:warn).
                  with(/use --force.+download.+/i)
        @knife.run
      end
    end

    context 'when' do
      before do
        @cookbook_data = { 'version' => @version,
                           'file'    => "http://example.com/apache2_#{@version_us}.tgz" }
        @temp_file     =  stub :path => "/tmp/apache2_#{@version_us}.tgz"
        @file          = File.join(Dir.pwd, "apache2-#{@version}.tar.gz")

        @noauth_rest.should_receive(:sign_on_redirect=).with(false)
      end

      context 'downloading the latest version' do
        before do
          @noauth_rest.should_receive(:get_rest).
                       with(@current_data['latest_version']).
                       and_return(@cookbook_data)
          @noauth_rest.should_receive(:get_rest).
                       with(@cookbook_data['file'], true).
                       and_return(@temp_file)
        end

        context 'and it is deprecated and with --force' do
          before do
            @current_data['deprecated'] = true
            @knife.config[:force] = true
          end

          it 'should download the latest version' do
            @knife.ui.should_receive(:warn).
                      with(/.+deprecated.+replaced by other_apache2.+/i)
            FileUtils.should_receive(:cp).with(@temp_file.path, @file)
            @knife.run
            @stdout.string.should match /downloading apache2.+version.+#{Regexp.escape(@version)}/i
            @stdout.string.should match /cookbook save.+#{Regexp.escape(@file)}/i
          end

        end

        it 'should download the latest version' do
          FileUtils.should_receive(:cp).with(@temp_file.path, @file)
          @knife.run
          @stdout.string.should match /downloading apache2.+version.+#{Regexp.escape(@version)}/i
          @stdout.string.should match /cookbook save.+#{Regexp.escape(@file)}/i
        end

        context 'with -f or --file' do
          before do
            @file = '/opt/chef/cookbooks/apache2.tar.gz'
            @knife.config[:file] = @file
            FileUtils.should_receive(:cp).with(@temp_file.path, @file)
          end

          it 'should download the cookbook to the desired file' do
            @knife.run
            @stdout.string.should match /downloading apache2.+version.+#{Regexp.escape(@version)}/i
            @stdout.string.should match /cookbook save.+#{Regexp.escape(@file)}/i
          end
        end

        it 'should provide an accessor to the version' do
          FileUtils.stub(:cp).and_return(true)
          @knife.version.should == @version
          @knife.run
        end
      end

      context 'downloading a cookbook of a specific version' do
        before do
          @version         = '1.0.1'
          @version_us      = @version.gsub '.', '_'
          @cookbook_data   = { 'version' => @version,
                               'file'    => "http://example.com/apache2_#{@version_us}.tgz" }
          @temp_file       = stub :path => "/tmp/apache2_#{@version_us}.tgz"
          @file            = File.join(Dir.pwd, "apache2-#{@version}.tar.gz")
          @knife.name_args << @version
        end

        it 'should download the desired version' do
          @noauth_rest.should_receive(:get_rest).
                       with("#{@cookbook_api_url}/apache2/versions/#{@version_us}").
                       and_return(@cookbook_data)
          @noauth_rest.should_receive(:get_rest).
                       with(@cookbook_data['file'], true).
                       and_return(@temp_file)
          FileUtils.should_receive(:cp).with(@temp_file.path, @file)
          @knife.run
          @stdout.string.should match /downloading apache2.+version.+#{Regexp.escape(@version)}/i
          @stdout.string.should match /cookbook save.+#{Regexp.escape(@file)}/i
        end
      end

    end

  end

end
