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

describe Chef::Knife::CookbookUpload do
  before(:each) do
    @knife = Chef::Knife::CookbookUpload.new
    @knife.config = {
      
    }
    @knife.stub!(:upload_cookbook).and_return(true)
    @cookbooks = []
    %w{tats central_market jimmy_johns pho}.each do |cookbook_name|
      @cookbooks << Chef::Cookbook.new(cookbook_name)
    end
  end
  
  describe "run" do
    
    it "should upload the cookbook" do
      @knife.name_args = ["italian"]
      @knife.should_receive(:upload_cookbook).with("italian")
      @knife.run
    end
    
    it "should upload multiple cookbooks when provided" do
      @knife.name_args = ["tats", "jimmy_johns"]
      @knife.should_receive(:upload_cookbook).with("tats")
      @knife.should_receive(:upload_cookbook).with("jimmy_johns")
      @knife.should_not_receive(:upload_cookbook).with("central_market")
      @knife.should_not_receive(:upload_cookbook).with("pho")
      @knife.run
    end
    
    describe "with -a or --all" do
      
      it "should upload all of the cookbooks" do
        @knife.config[:all] = true
        @loader = mock("Chef::CookbookLoader")
        @cookbooks.inject(@loader.stub!(:each)) { |stub, cookbook| 
          stub.and_yield(cookbook)
        }
        Chef::CookbookLoader.stub!(:new).and_return(@loader)
        @cookbooks.each do |cookbook|
          @knife.should_receive(:upload_cookbook).with(cookbook.name)
        end
        @knife.run
      end
    end

  end
end
