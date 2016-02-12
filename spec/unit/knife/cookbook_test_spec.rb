#
# Author:: Stephen Delano (<stephen@chef.io>)$
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.$
# Copyright:: Copyright 2010-2016, Matthew Kent
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

require "spec_helper"
Chef::Knife::CookbookTest.load_deps

describe Chef::Knife::CookbookTest do
  before(:each) do
    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::CookbookTest.new
    @knife.config[:cookbook_path] = File.join(CHEF_SPEC_DATA, "cookbooks")
    allow(@knife.cookbook_loader).to receive(:cookbook_exists?).and_return(true)
    @cookbooks = []
    %w{tats central_market jimmy_johns pho}.each do |cookbook_name|
      @cookbooks << Chef::CookbookVersion.new(cookbook_name)
    end
    @stdout = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@stdout)
  end

  describe "run" do
    it "should test the cookbook" do
      allow(@knife).to receive(:test_cookbook).and_return(true)
      @knife.name_args = ["italian"]
      expect(@knife).to receive(:test_cookbook).with("italian")
      @knife.run
    end

    it "should test multiple cookbooks when provided" do
      allow(@knife).to receive(:test_cookbook).and_return(true)
      @knife.name_args = %w{tats jimmy_johns}
      expect(@knife).to receive(:test_cookbook).with("tats")
      expect(@knife).to receive(:test_cookbook).with("jimmy_johns")
      expect(@knife).not_to receive(:test_cookbook).with("central_market")
      expect(@knife).not_to receive(:test_cookbook).with("pho")
      @knife.run
    end

    it "should test both ruby and templates" do
      @knife.name_args = ["example"]
      expect(@knife.config[:cookbook_path]).not_to be_empty
      Array(@knife.config[:cookbook_path]).reverse_each do |path|
        expect(@knife).to receive(:test_ruby).with(an_instance_of(Chef::Cookbook::SyntaxCheck))
        expect(@knife).to receive(:test_templates).with(an_instance_of(Chef::Cookbook::SyntaxCheck))
      end
      @knife.run
    end

    describe "with -a or --all" do
      it "should test all of the cookbooks" do
        allow(@knife).to receive(:test_cookbook).and_return(true)
        @knife.config[:all] = true
        @loader = {}
        allow(@loader).to receive(:load_cookbooks).and_return(@loader)
        @cookbooks.each do |cookbook|
          @loader[cookbook.name] = cookbook
        end
        allow(@knife).to receive(:cookbook_loader).and_return(@loader)
        @loader.each do |key, cookbook|
          expect(@knife).to receive(:test_cookbook).with(cookbook.name)
        end
        @knife.run
      end
    end

  end
end
