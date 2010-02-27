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

describe Chef::Knife::ClientBulkDelete do
  before(:each) do
    @knife = Chef::Knife::ClientBulkDelete.new
    @knife.config = {
      :print_after => nil
    }
    @knife.name_args = ["."]
    @knife.stub!(:json_pretty_print).and_return(:true)
    @knife.stub!(:confirm).and_return(true)
    @clients = Hash.new
    %w{tim dan stephen}.each do |client_name|
      client = Chef::ApiClient.new()
      client.name(client_name)
      client.stub!(:destroy).and_return(true)
      @clients[client_name] = client
    end
    Chef::ApiClient.stub!(:list).and_return(@clients)
  end
  
  describe "run" do
    
    it "should get the list of the clients" do
      Chef::ApiClient.should_receive(:list).and_return(@clients)
      @knife.run
    end
    
    it "should print the clients you are about to delete" do
      @knife.should_receive(:json_pretty_print).with(@knife.format_list_for_display(@clients))
      @knife.run
    end
    
    it "should confirm you really want to delete them" do
      @knife.should_receive(:confirm)
      @knife.run
    end
    
    it "should delete each client" do
      @clients.each_value do |c|
        c.should_receive(:destroy)
      end
      @knife.run
    end
    
    it "should only delete clients that match the regex" do
      @knife.name_args = ["tim"]
      @clients["tim"].should_receive(:destroy)
      @clients["stephen"].should_not_receive(:destroy)
      @clients["dan"].should_not_receive(:destroy)
      @knife.run
    end

    it "should exit if the regex is not provided" do
      @knife.name_args = []
      lambda { @knife.run }.should raise_error(SystemExit)
    end

    describe "with -p or --print_after" do
      it "should pretty_print the client, formatted for display" do
        @knife.config[:print_after] = true
        @clients.each_value do |n|
          @knife.should_receive(:json_pretty_print).with(@knife.format_for_display(n))
        end
        @knife.run
      end
    end
  end
end
