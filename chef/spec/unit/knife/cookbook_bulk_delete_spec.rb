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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Knife::CookbookBulkDelete do
  before(:each) do
    @knife = Chef::Knife::CookbookBulkDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = ["."]
    @knife.stub!(:output).and_return(:true)
    @knife.stub!(:confirm).and_return(true)
    @cookbooks = Hash.new
    %w{cheezburger pizza lasagna}.each do |cookbook_name|
      cookbook = Chef::Cookbook.new(cookbook_name)
      @cookbooks[cookbook_name] = cookbook
    end
    @rest = mock("Chef::REST")
    @rest.stub!(:get_rest).and_return(@cookbooks)
    @rest.stub!(:delete_rest).and_return(true)
    @knife.stub!(:rest).and_return(@rest)
  end
  
  describe "run" do
    
    it "should get the list of the cookbooks" do
      @rest.should_receive(:get_rest).with("cookbooks").and_return(@cookbooks)
      @knife.run
    end
    
    it "should print the cookbooks you are about to delete" do
      @knife.should_receive(:output).with(@knife.format_list_for_display(@cookbooks))
      @knife.run
    end
    
    it "should confirm you really want to delete them" do
      @knife.should_receive(:confirm)
      @knife.run
    end
    
    it "should delete each cookbook" do
      @cookbooks.each_value do |c|
        @rest.should_receive(:delete_rest).with(c)
      end
      @knife.run
    end
    
    it "should only delete cookbooks that match the regex" do
      @knife.name_args = ["cheezburger"]
      @rest.should_receive(:delete_rest).with(@cookbooks["cheezburger"])
      @rest.should_not_receive(:delete_rest).with(@cookbooks["pizza"])
      @rest.should_not_receive(:delete_rest).with(@cookbooks["lasagna"])
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe "with -p or --print_after" do
      it "should pretty_print the node, formatted for display" do
        @knife.config[:print_after] = true
        @cookbooks.each_value do |n|
          @knife.should_receive(:output).with(@knife.format_for_display(n))
        end
        @knife.run
      end
    end
  end
end
