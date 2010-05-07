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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookShow do
  before(:each) do
    @knife = Chef::Knife::CookbookShow.new
    @knife.config = { }
    @knife.name_args = [ "adam" ]
    @rest = mock(Chef::REST, :null_object => true)
    @knife.stub!(:rest).and_return(@rest)
    @knife.stub!(:pretty_print).and_return(true)
    @knife.stub!(:output).and_return(true)
  end

  describe "run" do
    describe "with 1 argument" do
      it "should show the raw cookbook data" do
        response = { "snootch" => "to the bootch" }
        @rest.should_receive(:get_rest).with("cookbooks/adam").and_return(response)
        @knife.should_receive(:output).with(response)
        @knife.run
      end
    end

    describe "with 2 arguments" do
      before(:each) do
        @knife.name_args << "snootchy"
        @response = { "snootchy" => { "bootches" => "snarf!" } }
      end

      it "should show the specific part of a cookbook" do
        @rest.should_receive(:get_rest).with("cookbooks/adam").and_return(@response)
        @knife.should_receive(:output).with(@response["snootchy"])
        @knife.run
      end
    end

    describe "with 3 arguments" do
      before(:each) do
        @knife.name_args = [ "adam", "recipes", "default.rb" ]
        @response = "Feel the fire that burns us all"
      end

      it "should print the raw result of the request (likely a file!)" do
        @rest.should_receive(:get_rest).with("cookbooks/adam/recipes?id=default.rb").and_return(@response)
        @knife.should_receive(:pretty_print).with(@response)
        @knife.run
      end

      describe "and --fqdn" do
        it "should pass the fqdn" do
          @knife.config[:fqdn] = "woot.com"
          @rest.should_receive(:get_rest).with("cookbooks/adam/recipes?fqdn=woot.com&id=default.rb").and_return(@response)
          @knife.run
        end
      end

      describe "and --platform" do
        it "should pass the platform" do
          @knife.config[:platform] = "ubuntu"
          @rest.should_receive(:get_rest).with("cookbooks/adam/recipes?id=default.rb&platform=ubuntu").and_return(@response)
          @knife.run
        end
      end

      describe "and --platform-version" do
        it "should pass the platform" do
          @knife.config[:platform_version] = "9.04"
          @rest.should_receive(:get_rest).with("cookbooks/adam/recipes?id=default.rb&version=9.04").and_return(@response)
          @knife.run
        end
      end

      describe "and with all three arguments" do
        it "should pass them all" do
          @knife.config[:fqdn] = "woot.com"
          @knife.config[:platform] = "ubuntu"
          @knife.config[:platform_version] = "9.04"
          @rest.should_receive(:get_rest).with("cookbooks/adam/recipes?fqdn=woot.com&id=default.rb&platform=ubuntu&version=9.04").and_return(@response)
          @knife.run
        end
      end

    end
  end
end

