#
# Author:: Stephen Delano (<stephen@opscode.com>)$
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.$
# Copyright:: Copyright (c) 2010 Matthew Kent
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
Chef::Knife::CookbookTest.load_deps

describe Chef::Knife::CookbookTest do
  before(:each) do
    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::CookbookTest.new
    @knife.config[:cookbook_path] = File.join(CHEF_SPEC_DATA,'cookbooks')
    @knife.cookbook_loader.stub!(:cookbook_exists?).and_return(true)
    @cookbooks = []
    %w{tats central_market jimmy_johns pho}.each do |cookbook_name|
      @cookbooks << Chef::CookbookVersion.new(cookbook_name)
    end
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should test the cookbook" do
      @knife.stub!(:test_cookbook).and_return(true)
      @knife.name_args = ["italian"]
      @knife.should_receive(:test_cookbook).with("italian")
      @knife.run
    end

    it "should test multiple cookbooks when provided" do
      @knife.stub!(:test_cookbook).and_return(true)
      @knife.name_args = ["tats", "jimmy_johns"]
      @knife.should_receive(:test_cookbook).with("tats")
      @knife.should_receive(:test_cookbook).with("jimmy_johns")
      @knife.should_not_receive(:test_cookbook).with("central_market")
      @knife.should_not_receive(:test_cookbook).with("pho")
      @knife.run
    end

    it "should test both ruby and templates" do
      @knife.name_args = ["example"]
      @knife.config[:cookbook_path].should_not be_empty
      Array(@knife.config[:cookbook_path]).reverse.each do |path|
        @knife.should_receive(:test_ruby).with(an_instance_of(Chef::Cookbook::SyntaxCheck))
        @knife.should_receive(:test_templates).with(an_instance_of(Chef::Cookbook::SyntaxCheck))
      end
      @knife.run
    end

    describe "with -a or --all" do
      it "should test all of the cookbooks" do
        @knife.stub!(:test_cookbook).and_return(true)
        @knife.config[:all] = true
        @loader = {}
        @loader.stub!(:load_cookbooks).and_return(@loader)
        @cookbooks.each do |cookbook|
          @loader[cookbook.name] = cookbook
        end
        @knife.stub!(:cookbook_loader).and_return(@loader)
        @loader.each do |key, cookbook|
          @knife.should_receive(:test_cookbook).with(cookbook.name)
        end
        @knife.run
      end
    end

  end
end
