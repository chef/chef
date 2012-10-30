#
# Author:: Stephen Delano (<stephen@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Knife::CookbookBulkDelete do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::CookbookBulkDelete.new
    @knife.config = {:print_after => nil}
    @knife.name_args = ["."]
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @knife.ui.stub!(:confirm).and_return(true)
    @cookbooks = Hash.new
    %w{cheezburger pizza lasagna}.each do |cookbook_name|
      cookbook = Chef::CookbookVersion.new(cookbook_name)
      @cookbooks[cookbook_name] = cookbook
    end
    @rest = mock("Chef::REST")
    @rest.stub!(:get_rest).and_return(@cookbooks)
    @rest.stub!(:delete_rest).and_return(true)
    @knife.stub!(:rest).and_return(@rest)
    Chef::CookbookVersion.stub!(:list).and_return(@cookbooks)

  end



  describe "when there are several cookbooks on the server" do
    before do
      @cheezburger = {'cheezburger' => {"url" => "file:///dev/null", "versions" => [{"url" => "file:///dev/null-cheez", "version" => "1.0.0"}]}}
      @rest.stub!(:get_rest).with('cookbooks/cheezburger').and_return(@cheezburger)
      @pizza = {'pizza' => {"url" => "file:///dev/null", "versions" => [{"url" => "file:///dev/null-pizza", "version" => "2.0.0"}]}}
      @rest.stub!(:get_rest).with('cookbooks/pizza').and_return(@pizza)
      @lasagna = {'lasagna' => {"url" => "file:///dev/null", "versions" => [{"url" => "file:///dev/null-lasagna", "version" => "3.0.0"}]}}
      @rest.stub!(:get_rest).with('cookbooks/lasagna').and_return(@lasagna)
    end

    it "should print the cookbooks you are about to delete" do
      expected = @knife.ui.list(@cookbooks.keys.sort, :columns_down)
      @knife.run
      @stdout.string.should match(/#{expected}/)
    end

    it "should confirm you really want to delete them" do
      @knife.ui.should_receive(:confirm)
      @knife.run
    end

    it "should delete each cookbook" do
      {"cheezburger" => "1.0.0", "pizza" => "2.0.0", "lasagna" => '3.0.0'}.each do |cookbook_name, version|
        @rest.should_receive(:delete_rest).with("cookbooks/#{cookbook_name}/#{version}")
      end
      @knife.run
    end

    it "should only delete cookbooks that match the regex" do
      @knife.name_args = ["cheezburger"]
      @rest.should_receive(:delete_rest).with('cookbooks/cheezburger/1.0.0')
      @knife.run
    end
  end

  it "should exit if the regex is not provided" do
    @knife.name_args = []
    lambda { @knife.run }.should raise_error(SystemExit)
  end

end
