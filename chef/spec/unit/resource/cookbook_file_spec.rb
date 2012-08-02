[#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
#p License:: Apache License, Version 2.0
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

describe Chef::Resource::CookbookFile do
  before do
    @cookbook_file = Chef::Resource::CookbookFile.new('sourcecode_tarball.tgz')
  end
  
  it "uses the name parameter for the source parameter" do
    @cookbook_file.name.should == 'sourcecode_tarball.tgz'
  end
  
  it "has a source parameter" do
    @cookbook_file.name('config_file.conf')
    @cookbook_file.name.should == 'config_file.conf'
  end
  
  it "defaults to a nil cookbook parameter (current cookbook will be used)" do
    @cookbook_file.cookbook.should be_nil
  end
  
  it "has a cookbook parameter" do
    @cookbook_file.cookbook("munin")
    @cookbook_file.cookbook.should == 'munin'
  end
  
  it "sets the provider to Chef::Provider::CookbookFile" do
    @cookbook_file.provider.should == Chef::Provider::CookbookFile
  end
  
  describe "when it has a backup number, group, mode, owner, source, and cookbook" do
    before do
      @cookbook_file.path("/tmp/origin/file.txt")
      @cookbook_file.backup(5)
      @cookbook_file.group("wheel")
      @cookbook_file.mode("0664")
      @cookbook_file.owner("root")
      @cookbook_file.source("/tmp/foo.txt")
      @cookbook_file.cookbook("/tmp/cookbooks/cooked.rb")
    end

    it "describes the state" do
      state = @cookbook_file.state
      state[:backup].should eql(5)
      state[:group].should == "wheel"
      state[:mode].should == "0664"
      state[:owner].should == "root"
      state[:source].should == "/tmp/foo.txt"
      state[:cookbook].should == "/tmp/cookbooks/cooked.rb"
    end
    
    it "returns the path as its identity" do
      @cookbook_file.identity.should == "/tmp/origin/file.txt"
    end
    
  end
end
