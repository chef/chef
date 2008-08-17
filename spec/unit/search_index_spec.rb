#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::SearchIndex, "initialize method" do
  it "should create a new Chef::SearchIndex object" do
    mf = mock("Ferret::Index::Index", :null_object => true)
    Ferret::Index::Index.stub!(:new).and_return(mf)
    Chef::SearchIndex.new.should be_kind_of(Chef::SearchIndex)
  end
  
  it "should create a Ferret Indexer" do
    mf = mock("Ferret::Index::Index", :null_object => true)
    Ferret::Index::Index.should_receive(:new).and_return(mf)
    Chef::SearchIndex.new
  end
end

describe Chef::SearchIndex, "create_index_object method" do
  before(:each) do
    @mf = mock("Ferret::Index::Index", :null_object => true)
    @fakeobj = mock("ToIndex", :null_object => true)
    @the_pigeon = { :index_name => "bird", :id => "pigeon" }
    @fakeobj.stub!(:respond_to?).with(:to_index).and_return(true)
    @fakeobj.stub!(:to_index).and_return(@the_pigeon)
    Ferret::Index::Index.stub!(:new).and_return(@mf)
  end
  
  def do_create_index_object
    index = Chef::SearchIndex.new
    index.create_index_object(@fakeobj)
  end
  
  it "should call to_index if the passed object responds to it" do
    @fakeobj.should_receive(:respond_to?).with(:to_index).and_return(true)
    @fakeobj.should_receive(:to_index).and_return(@the_pigeon)
    do_create_index_object
  end
  
  it "should use a hash if the passed argument does not have to_index (but is a hash)" do
    @fakeobj.stub!(:respond_to?).with(:to_index).and_return(false)
    @fakeobj.should_receive(:kind_of?).with(Hash).and_return(true)
    do_create_index_object
  end
  
  it "should raise SearchIndex exception if the hash does not contain an :id field" do
    @the_pigeon.delete(:id)
    lambda { do_create_index_object }.should raise_error(Chef::Exception::SearchIndex)
  end
  
  it "should raise SearchIndex exception if the hash does not contain an :index_name field" do
    @the_pigeon.delete(:index_name)
    lambda { do_create_index_object }.should raise_error(Chef::Exception::SearchIndex)
  end
end

describe Chef::SearchIndex, "add method" do
  before(:each) do
    @mf = mock("Ferret::Index::Index", :null_object => true)
    @fakeobj = mock("ToIndex", :null_object => true)
    @the_pigeon = { :index_name => "bird", :id => "pigeon" }
    @fakeobj.stub!(:respond_to?).with(:to_index).and_return(true)
    @fakeobj.stub!(:to_index).and_return(@the_pigeon)
    Ferret::Index::Index.stub!(:new).and_return(@mf)
  end
  
  def do_add
    index = Chef::SearchIndex.new
    index.add(@fakeobj)
  end

  it "should send the resulting hash to the index" do
    @mf.should_receive(:add_document).with(@the_pigeon)
    do_add
  end
end

describe Chef::SearchIndex, "delete method" do
  before(:each) do
    @mf = mock("Ferret::Index::Index", :null_object => true)
    @fakeobj = mock("ToIndex", :null_object => true)
    @the_pigeon = { :index_name => "bird", :id => "pigeon" }
    @fakeobj.stub!(:respond_to?).with(:to_index).and_return(true)
    @fakeobj.stub!(:to_index).and_return(@the_pigeon)
    Ferret::Index::Index.stub!(:new).and_return(@mf)
  end
  
  def do_delete(object)
    index = Chef::SearchIndex.new
    index.delete(object)
  end
  
  it "should delete the resulting hash to the index" do
    @mf.should_receive(:delete).with(@the_pigeon[:id])
    do_delete(@fakeobj)
  end
end
