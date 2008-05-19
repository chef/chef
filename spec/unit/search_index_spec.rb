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

describe Chef::SearchIndex do
  before(:each) do
    @fake_indexer = stub("Indexer", :null_object => true)
    Ferret::Index::Index.stub!(:new).and_return(@fake_indexer)
    @sindex = Chef::SearchIndex.new()
    @node = Chef::Node.new
    @node.name "adam.foo.com"
    @node.fqdn "adam.foo.com"
    @node.mars "volta"
    @node.recipes "one", "two"
  end

  it "should index a node object with add" do
    @sindex.should_receive(:_prepare_node).with(@node).and_return("my value")
    @fake_indexer.should_receive(:add_document).with("my value")
    @sindex.add(@node)
  end
  
  it "should remove a node from the index with delete" do
    @sindex.should_receive(:_prepare_node).with(@node).and_return({ :id => "node-my value" })
    @fake_indexer.should_receive(:delete).with(:id => "node-my value")
    @sindex.delete(@node)
  end
  
  it "should prepare a node by creating a proper hash" do
    node_hash = @sindex.send(:_prepare_node, @node)
    node_hash[:id].should eql("node-adam.foo.com")
    node_hash[:type].should eql("node")
    node_hash[:name].should eql("adam.foo.com")
    node_hash[:fqdn].should eql("adam.foo.com")
    node_hash[:mars].should eql("volta")
    node_hash[:recipe].should eql(["one", "two"])
  end
  
end