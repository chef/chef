#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright 2011-2016, Thomas Bishop
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

require "knife_spec_helper"

describe Chef::Knife::CookbookDownload do
  before(:each) do
    @knife = Chef::Knife::CookbookDownload.new
    @stderr = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@stderr)
  end

  describe "run" do
    it "should print usage and exit when a cookbook name is not provided" do
      @knife.name_args = []
      expect(@knife).to receive(:show_usage)
      expect(@knife.ui).to receive(:fatal).with(/must specify a cookbook name/)
      expect { @knife.run }.to raise_error(SystemExit)
    end

    it "should exit with a fatal error when there is no cookbook on the server" do
      @knife.name_args = ["foobar", nil]
      expect(@knife).to receive(:determine_version).and_return(nil)
      expect(@knife.ui).to receive(:fatal).with("No such cookbook found")
      expect { @knife.run }.to raise_error(SystemExit)
    end

    describe "with a cookbook name" do
      before(:each) do
        @knife.name_args = ["foobar"]
        @knife.config[:download_directory] = "/var/tmp/chef"
        @rest_mock = double("rest")
        allow(@knife).to receive(:rest).and_return(@rest_mock)

        expect(Chef::CookbookVersion).to receive(:load).with("foobar", "1.0.0")
          .and_return(cookbook)
      end

      let(:manifest_data) do
        {
          all_files: [
            {
              "path" => "recipes/foo.rb",
              "name" => "recipes/foo.rb",
              "url" => "http://example.org/files/foo.rb",
            },
            {
              "path" => "recipes/bar.rb",
              "name" => "recipes/bar.rb",
              "url" => "http://example.org/files/bar.rb",
            },
            {
              "path" => "templates/default/foo.erb",
              "name" => "templates/foo.erb",
              "url" => "http://example.org/files/foo.erb",
            },
            {
              "path" => "templates/default/bar.erb",
              "name" => "templates/bar.erb",
              "url" => "http://example.org/files/bar.erb",
            },
            {
              "path" => "attributes/default.rb",
              "name" => "attributes/default.rb",
              "url" => "http://example.org/files/default.rb",
            },
          ],
        }
      end

      let(:cookbook) do
        cb = Chef::CookbookVersion.new("foobar")
        cb.version = "1.0.0"
        cb.manifest = manifest_data
        cb
      end

      describe "and no version" do
        let(:manifest_data) { { all_files: [] } }
        it "should determine which version to download" do
          expect(@knife).to receive(:determine_version).and_return("1.0.0")
          expect(File).to receive(:exist?).with("/var/tmp/chef/foobar-1.0.0").and_return(false)
          @knife.run
        end
      end

      describe "and a version" do
        before(:each) do
          @knife.name_args << "1.0.0"
          @files = manifest_data.values.map { |v| v.map { |i| i["path"] } }.flatten.uniq
          @files_mocks = {}
          @files.map { |f| File.basename(f) }.flatten.uniq.each do |f|
            @files_mocks[f] = double("#{f}_mock")
            allow(@files_mocks[f]).to receive(:path).and_return("/var/tmp/#{f}")
          end
        end

        it "should print an error and exit if the cookbook download directory already exists" do
          expect(File).to receive(:exist?).with("/var/tmp/chef/foobar-1.0.0").and_return(true)
          expect(@knife.ui).to receive(:fatal).with(%r{/var/tmp/chef/foobar-1\.0\.0 exists}i)
          expect { @knife.run }.to raise_error(SystemExit)
        end

        describe "when downloading the cookbook" do
          before(:each) do
            @files.map { |f| File.dirname(f) }.flatten.uniq.each do |dir|
              expect(FileUtils).to receive(:mkdir_p).with("/var/tmp/chef/foobar-1.0.0/#{dir}")
                .at_least(:once)
            end

            @files_mocks.each_pair do |file, mock|
              expect(@rest_mock).to receive(:streaming_request).with("http://example.org/files/#{file}")
                .and_return(mock)
            end

            @files.each do |f|
              expect(FileUtils).to receive(:mv)
                .with("/var/tmp/#{File.basename(f)}", "/var/tmp/chef/foobar-1.0.0/#{f}")
            end
          end

          it "should download the cookbook when the cookbook download directory doesn't exist" do
            expect(File).to receive(:exist?).with("/var/tmp/chef/foobar-1.0.0").and_return(false)
            @knife.run
            %w{attributes recipes templates}.each do |segment|
              expect(@stderr.string).to match(/downloading #{segment}/im)
            end
            expect(@stderr.string).to match(/downloading foobar cookbook version 1\.0\.0/im)
            expect(@stderr.string).to match %r{cookbook downloaded to /var/tmp/chef/foobar-1\.0\.0}im
          end

          describe "with -f or --force" do
            it "should remove the existing the cookbook download directory if it exists" do
              @knife.config[:force] = true
              expect(File).to receive(:exist?).with("/var/tmp/chef/foobar-1.0.0").and_return(true)
              expect(FileUtils).to receive(:rm_rf).with("/var/tmp/chef/foobar-1.0.0")
              @knife.run
            end
          end
        end

      end
    end

  end

  describe "determine_version" do

    it "should return nil if there are no versions" do
      expect(@knife).to receive(:available_versions).and_return(nil)
      expect(@knife.determine_version).to eq(nil)
      expect(@knife.version).to eq(nil)
    end

    it "should return and set the version if there is only one version" do
      expect(@knife).to receive(:available_versions).at_least(:once).and_return(["1.0.0"])
      expect(@knife.determine_version).to eq("1.0.0")
      expect(@knife.version).to eq("1.0.0")
    end

    it "should ask which version to download and return it if there is more than one" do
      expect(@knife).to receive(:available_versions).at_least(:once).and_return(["1.0.0", "2.0.0"])
      expect(@knife).to receive(:ask_which_version).and_return("1.0.0")
      expect(@knife.determine_version).to eq("1.0.0")
    end

    describe "with -N or --latest" do
      it "should return and set the version to the latest version" do
        @knife.config[:latest] = true
        expect(@knife).to receive(:available_versions).at_least(:once)
          .and_return(["1.0.0", "1.1.0", "2.0.0"])
        @knife.determine_version
        expect(@knife.version.to_s).to eq("2.0.0")
      end
    end
  end

  describe "available_versions" do
    before(:each) do
      @knife.cookbook_name = "foobar"
    end

    it "should return nil if there are no versions" do
      expect(Chef::CookbookVersion).to receive(:available_versions)
        .with("foobar")
        .and_return(nil)
      expect(@knife.available_versions).to eq(nil)
    end

    it "should return the available versions" do
      expect(Chef::CookbookVersion).to receive(:available_versions)
        .with("foobar")
        .and_return(["1.1.0", "2.0.0", "1.0.0"])
      expect(@knife.available_versions).to eq([Chef::Version.new("1.0.0"),
                                           Chef::Version.new("1.1.0"),
                                           Chef::Version.new("2.0.0")])
    end

    it "should avoid multiple API calls to the server" do
      expect(Chef::CookbookVersion).to receive(:available_versions)
        .once
        .with("foobar")
        .and_return(["1.1.0", "2.0.0", "1.0.0"])
      @knife.available_versions
      @knife.available_versions
    end
  end

  describe "ask_which_version" do
    before(:each) do
      @knife.cookbook_name = "foobar"
      allow(@knife).to receive(:available_versions).and_return(["1.0.0", "1.1.0", "2.0.0"])
    end

    it "should prompt the user to select a version" do
      prompt = /Which version do you want to download\?.+1\. foobar 1\.0\.0.+2\. foobar 1\.1\.0.+3\. foobar 2\.0\.0.+/m
      expect(@knife).to receive(:ask_question).with(prompt).and_return("1")
      @knife.ask_which_version
    end

    it "should set the version to the user's selection" do
      expect(@knife).to receive(:ask_question).and_return("1")
      @knife.ask_which_version
      expect(@knife.version).to eq("1.0.0")
    end

    it "should print an error and exit if a version wasn't specified" do
      expect(@knife).to receive(:ask_question).and_return("")
      expect(@knife.ui).to receive(:error).with(/is not a valid value/i)
      expect { @knife.ask_which_version }.to raise_error(SystemExit)
    end

    it "should print an error if an invalid choice was selected" do
      expect(@knife).to receive(:ask_question).and_return("100")
      expect(@knife.ui).to receive(:error).with(/'100' is not a valid value/i)
      expect { @knife.ask_which_version }.to raise_error(SystemExit)
    end
  end

end
