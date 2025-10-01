#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, version 2.0
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

describe Chef::Knife::CookbookShow do
  before do
    Chef::Config[:node_name] = "webmonkey.example.com"
    allow(knife).to receive(:rest).and_return(rest)
    allow(knife).to receive(:pretty_print).and_return(true)
    allow(knife).to receive(:output).and_return(true)
    allow(Chef::CookbookVersion).to receive(:load).and_return(cb)
  end

  let(:knife) do
    knife = Chef::Knife::CookbookShow.new
    knife.config = {}
    knife.name_args = [ "cookbook_name" ]
    knife
  end

  let(:cb) do
    cb = Chef::CookbookVersion.new("cookbook_name")
    cb.manifest = manifest
    cb
  end

  let(:rest) { double(Chef::ServerAPI) }

  let(:content) { "Example recipe text" }

  let(:manifest) do
    {
      "all_files" => [
        {
          name: "recipes/default.rb",
          path: "recipes/default.rb",
          checksum: "1234",
          url: "http://example.org/files/default.rb",
        },
      ],
    }
  end

  describe "run" do
    describe "with 0 arguments: help" do
      it "should should print usage and exit when given no arguments" do
        knife.name_args = []
        expect(knife).to receive(:show_usage)
        expect(knife.ui).to receive(:fatal)
        expect { knife.run }.to raise_error(SystemExit)
      end
    end

    describe "with 1 argument: versions" do
      let(:response) do
        {
          "cookbook_name" => {
            "url" => "http://url/cookbooks/cookbook_name",
            "versions" => [
              { "version" => "0.10.0", "url" => "http://url/cookbooks/cookbook_name/0.10.0" },
              { "version" => "0.9.0", "url" => "http://url/cookbookx/cookbook_name/0.9.0" },
              { "version" => "0.8.0", "url" => "http://url/cookbooks/cookbook_name/0.8.0" },
            ],
          },
        }
      end

      it "should show the raw cookbook data" do
        expect(rest).to receive(:get).with("cookbooks/cookbook_name").and_return(response)
        expect(knife).to receive(:format_cookbook_list_for_display).with(response)
        knife.run
      end

      it "should respect the user-supplied environment" do
        knife.config[:environment] = "foo"
        expect(rest).to receive(:get).with("environments/foo/cookbooks/cookbook_name").and_return(response)
        expect(knife).to receive(:format_cookbook_list_for_display).with(response)
        knife.run
      end
    end

    describe "with 2 arguments: name and version" do
      before do
        knife.name_args << "0.1.0"
      end

      let(:output) do
        { "cookbook_name" => "cookbook_name",
          "name" => "cookbook_name-0.0.0",
          "frozen?" => false,
          "version" => "0.0.0",
          "metadata" => {
            "name" => nil,
            "description" => "",
            "eager_load_libraries" => true,
            "long_description" => "",
            "maintainer" => "",
            "maintainer_email" => "",
            "license" => "All rights reserved",
            "platforms" => {},
            "dependencies" => {},
            "providing" => {},
            "recipes" => {},
            "version" => "0.0.0",
            "source_url" => "",
            "issues_url" => "",
            "privacy" => false,
            "chef_versions" => [],
            "ohai_versions" => [],
            "gems" => [],
          },
          "recipes" =>
          [{ "name" => "recipes/default.rb",
             "path" => "recipes/default.rb",
             "checksum" => "1234",
             "url" => "http://example.org/files/default.rb" }],
        }
      end

      it "should show the specific part of a cookbook" do
        expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
        expect(knife).to receive(:output).with(output)
        knife.run
      end
    end

    describe "with 3 arguments: name, version, and segment" do
      before(:each) do
        knife.name_args = [ "cookbook_name", "0.1.0", "recipes" ]
      end

      it "should print the json of the part" do
        expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
        expect(knife).to receive(:output).with(cb.files_for("recipes"))
        knife.run
      end
    end

    describe "with 4 arguments: name, version, segment and filename" do
      before(:each) do
        knife.name_args = [ "cookbook_name", "0.1.0", "recipes", "default.rb" ]
      end

      it "should print the raw result of the request (likely a file!)" do
        expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
        expect(rest).to receive(:streaming_request).with("http://example.org/files/default.rb").and_return(StringIO.new(content))
        expect(knife).to receive(:pretty_print).with(content)
        knife.run
      end
    end

    describe "with 4 arguments: name, version, segment and filename -- with specificity" do
      before(:each) do
        knife.name_args = [ "cookbook_name", "0.1.0", "files", "afile.rb" ]
        cb.manifest = {
          "all_files" => [
            {
              name: "files/afile.rb",
              path: "files/host-examplehost.example.org/afile.rb",
              checksum: "1111",
              specificity: "host-examplehost.example.org",
              url: "http://example.org/files/1111",
            },
            {
              name: "files/afile.rb",
              path: "files/ubuntu-9.10/afile.rb",
              checksum: "2222",
              specificity: "ubuntu-9.10",
              url: "http://example.org/files/2222",
            },
            {
              name: "files/afile.rb",
              path: "files/ubuntu/afile.rb",
              checksum: "3333",
              specificity: "ubuntu",
              url: "http://example.org/files/3333",
            },
            {
              name: "files/afile.rb",
              path: "files/default/afile.rb",
              checksum: "4444",
              specificity: "default",
              url: "http://example.org/files/4444",
            },
          ],
        }

      end

      describe "with --fqdn" do
        it "should pass the fqdn" do
          knife.config[:platform] = "example_platform"
          knife.config[:platform_version] = "1.0"
          knife.config[:fqdn] = "examplehost.example.org"
          expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
          expect(rest).to receive(:streaming_request).with("http://example.org/files/1111").and_return(StringIO.new(content))
          expect(knife).to receive(:pretty_print).with(content)
          knife.run
        end
      end

      describe "and --platform" do
        it "should pass the platform" do
          knife.config[:platform] = "ubuntu"
          knife.config[:platform_version] = "1.0"
          knife.config[:fqdn] = "differenthost.example.org"
          expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
          expect(rest).to receive(:streaming_request).with("http://example.org/files/3333").and_return(StringIO.new(content))
          expect(knife).to receive(:pretty_print).with(content)
          knife.run
        end
      end

      describe "and --platform-version" do
        it "should pass the platform" do
          knife.config[:platform] = "ubuntu"
          knife.config[:platform_version] = "9.10"
          knife.config[:fqdn] = "differenthost.example.org"
          expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
          expect(rest).to receive(:streaming_request).with("http://example.org/files/2222").and_return(StringIO.new(content))
          expect(knife).to receive(:pretty_print).with(content)
          knife.run
        end
      end

      describe "with none of the arguments, it should use the default" do
        it "should pass them all" do
          expect(Chef::CookbookVersion).to receive(:load).with("cookbook_name", "0.1.0").and_return(cb)
          expect(rest).to receive(:streaming_request).with("http://example.org/files/4444").and_return(StringIO.new(content))
          expect(knife).to receive(:pretty_print).with(content)
          knife.run
        end
      end

    end
  end
end
