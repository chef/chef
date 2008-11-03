#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

# require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')
# 
# describe OpenidRegister, "index action" do  
#   it "should get a list of all registered nodes" do
#     Chef::OpenIDRegistration.should_receive(:list).with(true).and_return(["one"])
#     dispatch_to(OpenidRegister, :index) do |c|
#       c.stub!(:display)
#     end
#   end
# end
# 
# describe OpenidRegister, "show action" do  
#   it "should raise a 404 if the nodes registration is not found" do
#     Chef::OpenIDRegistration.should_receive(:load).with("foo").and_raise(RuntimeError)
#     lambda { 
#       dispatch_to(OpenidRegister, :show, { :id => "foo" }) 
#     }.should raise_error(Merb::ControllerExceptions::NotFound)
#   end
#   
#   it "should call display on the node registration" do
#     Chef::OpenIDRegistration.stub!(:load).and_return(true)
#     dispatch_to(OpenidRegister, :show, { :id => "foo" }) do |c|
#       c.should_receive(:display).with(true)
#     end
#   end
# end
# 
# describe OpenidRegister, "create action" do
#   def do_create
#     dispatch_to(OpenidRegister, :create, { :id => "foo", :password => "beck" }) do |c|
#       c.stub!(:display)
#     end
#   end
#   
#   it "should require an id to register" do
#     lambda {
#       dispatch_to(OpenidRegister, :create, { :password => "beck" }) 
#     }.should raise_error(Merb::ControllerExceptions::BadRequest)
#   end
#   
#   it "should require a password to register" do
#     lambda { 
#       dispatch_to(OpenidRegister, :create, { :id => "foo" }) 
#     }.should raise_error(Merb::ControllerExceptions::BadRequest)
#   end
#   
#   it "should return 400 if a node is already registered" do
#     Chef::OpenIDRegistration.should_receive(:has_key?).with("foo").and_return(true)
#     lambda { 
#       dispatch_to(OpenidRegister, :create, { :id => "foo", :password => "beck" }) 
#     }.should raise_error(Merb::ControllerExceptions::BadRequest)
#   end
#   
#   it "should store the registration in a new Chef::OpenIDRegistration" do
#     mock_reg = mock("Chef::OpenIDRegistration", :null_object => true)
#     mock_reg.should_receive(:name=).with("foo").and_return(true)
#     mock_reg.should_receive(:set_password).with("beck").and_return(true)
#     mock_reg.should_receive(:save).and_return(true)
#     Chef::OpenIDRegistration.stub!(:has_key?).and_return(false)
#     Chef::OpenIDRegistration.should_receive(:new).and_return(mock_reg)
#     do_create
#   end
# end
# 
# describe OpenidRegister, "update action" do
#   it "should raise a 400 error" do
#     lambda { 
#       dispatch_to(OpenidRegister, :update)
#     }
#   end
# end
# 
# describe OpenidRegister, "destroy action" do
#   def do_destroy
#     dispatch_to(OpenidRegister, :destroy, { :id => "foo" }) do |c|
#       c.stub!(:display)
#     end
#   end
#   
#   it "should return 400 if it cannot find the registration" do
#     Chef::OpenIDRegistration.should_receive(:load).and_raise(ArgumentError)
#     lambda { 
#       do_destroy
#     }.should raise_error(Merb::ControllerExceptions::BadRequest)
#   end
#   
#   it "should delete the registration from the store" do
#     mock_reg = mock("OpenIDRegistration")
#     mock_reg.should_receive(:destroy).and_return(true)
#     Chef::OpenIDRegistration.should_receive(:load).with("foo").and_return(mock_reg)
#     do_destroy
#   end
# end