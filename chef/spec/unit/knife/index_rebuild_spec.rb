#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

describe Chef::Knife::IndexRebuild do
  before do
    @knife = Chef::Knife::IndexRebuild.new
    @knife.stub!(:edit_data)
    @rest_client = mock("null rest client", :post_rest => { :result => :true })
    @knife.stub!(:output)
    @knife.stub!(:rest).and_return(@rest_client)
  end
  
  it "asks a yes/no confirmation and aborts on 'no'" do
    @knife.should_receive(:print).with(/yes\/no/)
    STDIN.stub(:readline).and_return("NO\n")
    @knife.should_receive(:puts)
    @knife.should_receive(:exit).with(7)
    @knife.run
  end
  
  it "asks a confirmation and continues on 'yes'" do
    @knife.should_receive(:print).with(/yes\/no/)
    STDIN.stub(:readline).and_return("yes\n")
    @knife.should_not_receive(:exit)
    @knife.run
  end
  
  describe "after confirming the operation" do
    before do
      @knife.stub!(:print)
      @knife.stub!(:puts)
      @knife.stub!(:nag)
      @knife.stub!(:output)
    end
    
    it "POSTs to /search/reindex and displays the result" do
      @rest_client = mock("Chef::REST")
      @knife.stub!(:rest).and_return(@rest_client)
      @rest_client.should_receive(:post_rest).with("/search/reindex", {}).and_return("monkey")
      @knife.should_receive(:output).with("monkey")
      @knife.run
    end
  end

end
