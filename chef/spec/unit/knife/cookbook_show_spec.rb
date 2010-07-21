#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

# rename to cookbook not coookbook
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookShow do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::CookbookShow.new
    @knife.config = { }
    @knife.name_args = [ "cookbook_name" ]
    @rest = mock(Chef::REST, :null_object => true)
    @knife.stub!(:rest).and_return(@rest)
    @knife.stub!(:pretty_print).and_return(true)
    @knife.stub!(:output).and_return(true)
  end

  describe "run" do
    describe "with 1 argument: versions" do
      it "should show the raw cookbook data" do
        @response = ["0.1.0"]
        @rest.should_receive(:get_rest).with("cookbooks/cookbook_name").and_return(@response)
        @knife.should_receive(:output).with(@response)
        @knife.run
      end
    end

    describe "with 2 arguments: name and version" do
      before(:each) do
        @knife.name_args << "0.1.0"
        @response = { "0.1.0" => { "recipes" => {"default.rb" => ""} } }
      end

      it "should show the specific part of a cookbook" do
        @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@response)
        @knife.should_receive(:output).with(@response)
        @knife.run
      end
    end

    # 3-argument needed

    describe "with 4 arguments: name, version, segment and filename" do
      before(:each) do
        @knife.name_args = [ "cookbook_name", "0.1.0", "recipes", "default.rb" ]
        @cookbook_response = {
          "recipes" => [
            {
              :name => "default.rb",
              :path => "recipes/default.rb",
              :checksum => "1234"
            }
          ]
        }
        @response = "Example recipe text"
      end

      it "should print the raw result of the request (likely a file!)" do
        @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@cookbook_response)
        @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0/files/1234").and_return(@response)
        @knife.should_receive(:pretty_print).with(@response)
        @knife.run
      end
    end

    describe "with 4 arguments: name, version, segment and filename -- with specificity" do
      before(:each) do
        @knife.name_args = [ "cookbook_name", "0.1.0", "files", "afile.rb" ]
        @cookbook_response = {
          "files" => [
            {
              :name => "afile.rb",
              :path => "files/host-examplehost.example.org/afile.rb",
              :checksum => "1111",
              :specificity => "host-examplehost.example.org"
            },
            {
              :name => "afile.rb",
              :path => "files/ubuntu-9.10/afile.rb",
              :checksum => "2222",
              :specificity => "ubuntu-9.10"
            },
            {
              :name => "afile.rb",
              :path => "files/ubuntu/afile.rb",
              :checksum => "3333",
              :specificity => "ubuntu"
            },
            {
              :name => "afile.rb",
              :path => "files/default/afile.rb",
              :checksum => "4444",
              :specificity => "default"
            },
          ]
        }
        @response = "Example recipe text"
      end
      
      describe "with --fqdn" do
        it "should pass the fqdn" do
          @knife.config[:platform] = "example_platform"
          @knife.config[:platform_version] = "1.0"
          @knife.config[:fqdn] = "examplehost.example.org"
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@cookbook_response)
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0/files/1111").and_return(@response)
          @knife.should_receive(:pretty_print).with(@response)
          @knife.run
        end
      end

      describe "and --platform" do
        it "should pass the platform" do
          @knife.config[:platform] = "ubuntu"
          @knife.config[:platform_version] = "1.0"
          @knife.config[:fqdn] = "differenthost.example.org"
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@cookbook_response)
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0/files/3333").and_return(@response)
          @knife.should_receive(:pretty_print).with(@response)
          @knife.run
        end
      end

      describe "and --platform-version" do
        it "should pass the platform" do
          @knife.config[:platform] = "ubuntu"
          @knife.config[:platform_version] = "9.10"
          @knife.config[:fqdn] = "differenthost.example.org"
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@cookbook_response)
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0/files/2222").and_return(@response)
          @knife.should_receive(:pretty_print).with(@response)
          @knife.run
        end
      end

      describe "with none of the arguments, it should use the default" do
        it "should pass them all" do
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0").and_return(@cookbook_response)
          @rest.should_receive(:get_rest).with("cookbooks/cookbook_name/0.1.0/files/4444").and_return(@response)
          @knife.should_receive(:pretty_print).with(@response)
          @knife.run
        end
      end

    end
  end
end

