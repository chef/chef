#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
