#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2012-2016, Thomas Bishop
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/knife/supermarket_download"
require "knife_spec_helper"

describe Chef::Knife::SupermarketDownload do

  describe "run" do
    before do
      @knife            = Chef::Knife::SupermarketDownload.new
      @knife.name_args  = ["apache2"]
      @noauth_rest      = double("no auth rest")
      @stderr           = StringIO.new
      @cookbook_api_url = "https://supermarket.chef.io/api/v1/cookbooks"
      @version          = "1.0.2"
      @version_us       = @version.tr ".", "_"
      @current_data     = { "deprecated" => false,
                            "latest_version" => "#{@cookbook_api_url}/apache2/versions/#{@version_us}",
                            "replacement" => "other_apache2" }

      allow(@knife.ui).to receive(:stderr).and_return(@stderr)
      allow(@knife).to receive(:noauth_rest).and_return(@noauth_rest)
      expect(@noauth_rest).to receive(:get)
        .with("#{@cookbook_api_url}/apache2")
        .and_return(@current_data)
      @knife.configure_chef
    end

    context "when the cookbook is deprecated and not forced" do
      before do
        @current_data["deprecated"] = true
      end

      it "should warn with info about the replacement" do
        expect(@knife.ui).to receive(:warn)
          .with(/.+deprecated.+replaced by other_apache2.+/i)
        expect(@knife.ui).to receive(:warn)
          .with(/use --force.+download.+/i)
        @knife.run
      end
    end

    context "when" do
      before do
        @cookbook_data = { "version" => @version,
                           "file" => "http://example.com/apache2_#{@version_us}.tgz" }
        @temp_file     = double( path: "/tmp/apache2_#{@version_us}.tgz" )
        @file          = File.join(Dir.pwd, "apache2-#{@version}.tar.gz")
      end

      context "downloading the latest version" do
        before do
          expect(@noauth_rest).to receive(:get)
            .with(@current_data["latest_version"])
            .and_return(@cookbook_data)
          expect(@noauth_rest).to receive(:streaming_request)
            .with(@cookbook_data["file"])
            .and_return(@temp_file)
        end

        context "and it is deprecated and with --force" do
          before do
            @current_data["deprecated"] = true
            @knife.config[:force] = true
          end

          it "should download the latest version" do
            expect(@knife.ui).to receive(:warn)
              .with(/.+deprecated.+replaced by other_apache2.+/i)
            expect(FileUtils).to receive(:cp).with(@temp_file.path, @file)
            @knife.run
            expect(@stderr.string).to match(/downloading apache2.+version.+#{Regexp.escape(@version)}/i)
            expect(@stderr.string).to match(/cookbook save.+#{Regexp.escape(@file)}/i)
          end

        end

        it "should download the latest version" do
          expect(FileUtils).to receive(:cp).with(@temp_file.path, @file)
          @knife.run
          expect(@stderr.string).to match(/downloading apache2.+version.+#{Regexp.escape(@version)}/i)
          expect(@stderr.string).to match(/cookbook save.+#{Regexp.escape(@file)}/i)
        end

        context "with -f or --file" do
          before do
            @file = "/opt/chef/cookbooks/apache2.tar.gz"
            @knife.config[:file] = @file
            expect(FileUtils).to receive(:cp).with(@temp_file.path, @file)
          end

          it "should download the cookbook to the desired file" do
            @knife.run
            expect(@stderr.string).to match(/downloading apache2.+version.+#{Regexp.escape(@version)}/i)
            expect(@stderr.string).to match(/cookbook save.+#{Regexp.escape(@file)}/i)
          end
        end

        it "should provide an accessor to the version" do
          allow(FileUtils).to receive(:cp).and_return(true)
          expect(@knife.version).to eq(@version)
          @knife.run
        end
      end

      context "downloading a cookbook of a specific version" do
        before do
          @version         = "1.0.1"
          @version_us      = @version.tr ".", "_"
          @cookbook_data   = { "version" => @version,
                               "file" => "http://example.com/apache2_#{@version_us}.tgz" }
          @temp_file       = double(path: "/tmp/apache2_#{@version_us}.tgz")
          @file            = File.join(Dir.pwd, "apache2-#{@version}.tar.gz")
          @knife.name_args << @version
        end

        it "should download the desired version" do
          expect(@noauth_rest).to receive(:get)
            .with("#{@cookbook_api_url}/apache2/versions/#{@version_us}")
            .and_return(@cookbook_data)
          expect(@noauth_rest).to receive(:streaming_request)
            .with(@cookbook_data["file"])
            .and_return(@temp_file)
          expect(FileUtils).to receive(:cp).with(@temp_file.path, @file)
          @knife.run
          expect(@stderr.string).to match(/downloading apache2.+version.+#{Regexp.escape(@version)}/i)
          expect(@stderr.string).to match(/cookbook save.+#{Regexp.escape(@file)}/i)
        end
      end

    end

  end

end
