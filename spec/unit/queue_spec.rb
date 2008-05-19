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

describe Chef::Queue do
 
  it "should connect to a stomp server on localhost and 61613" do
    Stomp::Connection.should_receive(:open).with("", "", "localhost", 61613, false).once
    Chef::Queue.connect
  end
 
  it "should allow config options to override defaults on connect" do
    Chef::Config[:queue_user] = "monkey"
    Chef::Config[:queue_password] = "password"
    Chef::Config[:queue_host] = "10.10.10.10"
    Chef::Config[:queue_port] = 61614
    Stomp::Connection.should_receive(:open).with("monkey", "password", "10.10.10.10", 61614, false).once
    Chef::Queue.connect
  end
  
  it "should make a url based on type and name" do
    Chef::Queue.make_url("topic", "goal").should eql("/topic/chef/goal")
    Chef::Queue.make_url("queue", "pool").should eql("/queue/chef/pool")
  end
  
  it "should allow you to subscribe to a queue" do
    queue = mock("Queue", :null_object => true)
    queue.should_receive(:subscribe).with(Chef::Queue.make_url(:topic, :node)).once
    Stomp::Connection.stub!(:open).and_return(queue)
    Chef::Queue.connect
    Chef::Queue.subscribe(:topic, :node)
  end
  
  it "should allow you to send a message" do
    message = mock("Message", :null_object => true)
    message.should_receive(:to_json).once.and_return("some json")
    connection = mock("Connection", :null_object => true)
    connection.should_receive(:send).with(Chef::Queue.make_url(:queue, :node), "some json").once.and_return(true)
    Stomp::Connection.stub!(:open).and_return(connection)
    Chef::Queue.connect
    Chef::Queue.send_msg(:queue, :node, message)
  end
  
  it "should receive a message with receive_msg" do
    raw_msg = mock("Stomp Message", :null_object => true)
    raw_msg.should_receive(:body).twice.and_return("the body")
    connection = mock("Connection", :null_object => true)
    connection.should_receive(:receive).once.and_return(raw_msg)
    JSON.should_receive(:parse).with("the body").and_return("the body")
    Stomp::Connection.stub!(:open).and_return(connection)
    Chef::Queue.connect
    Chef::Queue.receive_msg.should eql([ "the body", raw_msg ])
  end
  
  it "should poll for a message with poll_msg, returning a message if there is one" do
    raw_msg = mock("Stomp Message", :null_object => true)
    raw_msg.should_receive(:body).once.and_return("the body")
    connection = mock("Connection", :null_object => true)
    connection.should_receive(:poll).once.and_return(raw_msg)
    JSON.should_receive(:parse).with("the body").and_return("the body")
    Stomp::Connection.stub!(:open).and_return(connection)
    Chef::Queue.connect
    Chef::Queue.poll_msg.should eql("the body")
  end
  
  it "should poll for a message with poll_msg, returning nil if there is not a message" do
    connection = mock("Connection", :null_object => true)
    connection.should_receive(:poll).once.and_return(nil)
    JSON.should_not_receive(:parse).with(nil)
    Stomp::Connection.stub!(:open).and_return(connection)
    Chef::Queue.connect
    Chef::Queue.poll_msg.should eql(nil)
  end
  
  it "should raise an exception if you disconnect without a connection" do
    Stomp::Connection.stub!(:open).and_return(nil)
    Chef::Queue.connect 
    lambda { Chef::Queue.disconnect }.should raise_error(ArgumentError)
  end
  
  it "should disconnect an active connection" do
    connection = mock("Connection", :null_object => true)
    connection.should_receive(:disconnect).once.and_return(true)
    Stomp::Connection.stub!(:open).and_return(connection)
    Chef::Queue.connect
    Chef::Queue.disconnect
  end

end