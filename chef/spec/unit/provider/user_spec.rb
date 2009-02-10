#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::User, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )

    @provider = Chef::Provider::User.new(@node, @new_resource)
  end
  
  it "should return a Chef::Provider::User" do
    @provider.should be_a_kind_of(Chef::Provider::User)
  end
  
  it "should assume the user exists by default" do
    @provider.user_exists.should eql(true)
  end
  
  it "should assume we do not know the locked state" do
    @provider.locked.should eql(nil)
  end
end

describe Chef::Provider::User, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    Chef::Resource::User.stub!(:new).and_return(@current_resource)
    @pw_user = mock("Etc::User",
      :null_object => true,
      :uid => "adam",
      :gid => 1000,
      :uid => 1000,
      :comment => "Adam Jacob",
      :home => "/home/adam",
      :shell => "/usr/bin/zsh"
    )
    Etc.stub!(:getpwnam).and_return(@pw_user)

    @provider = Chef::Provider::User.new(@node, @new_resource)
  end
 
  it "should create a current resource with the same name as the new resource" do
    Chef::Resource::User.should_receive(:new).with(@new_resource.name).and_return(@current_resource)
    @provider.load_current_resource
  end
  
  it "should set the username of the current resource to the username of the new resource" do
    @current_resource.should_receive(:username).with(@new_resource.username)
    @provider.load_current_resource
  end
  
  it "should look up the user in /etc/passwd with getpwnam" do
    Etc.should_receive(:getpwnam).with(@new_resource.username).and_return(@pw_user)
    @provider.load_current_resource
  end
  
  it "should set user_exists to false if the user is not found with getpwnam" do
    Etc.should_receive(:getpwnam).and_raise(ArgumentError)
    @provider.load_current_resource
    @provider.user_exists.should eql(false)
  end
  
  # The mapping between the Chef::Resource::User and Getpwnam struct
  user_attrib_map = {
    :uid => :uid,
    :gid => :gid,
    :comment => :gecos,
    :home => :dir,
    :shell => :shell
  }
  user_attrib_map.each do |user_attrib, getpwnam_attrib|
    it "should set the current resources #{user_attrib} based on getpwnam #{getpwnam_attrib}" do
      @current_resource.should_receive(user_attrib).with(@pw_user.send(getpwnam_attrib))
      @provider.load_current_resource
    end
  end
  
  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::User, "compare_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  %w{uid gid comment home shell password}.each do |attribute|
    it "should return true if #{attribute} doesn't match" do
      @new_resource.should_receive(attribute).exactly(2).times.and_return(true)
      @current_resource.should_receive(attribute).once.and_return(false)
      @provider.compare_user.should eql(true)
    end
  end
  
  it "should return false if the objects are identical" do
    @provider.compare_user.should eql(false)
  end  
end

describe Chef::Provider::User, "action_create" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => "/home/adam",
      :shell => "/usr/bin/zsh",
      :password => nil,
      :updated => nil
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = false
    @provider.stub!(:create_user).and_return(true)
    @provider.stub!(:manage_user).and_return(true)
  end
  
  it "should call create_user if the user does not exist" do
    @provider.should_receive(:create_user).and_return(true)
    @provider.action_create
  end
  
  it "should set the the new_resources updated flag when it creates the user" do
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end
  
  it "should check to see if the user has mismatched attributes if the user exists" do
    @provider.user_exists = true
    @provider.should_receive(:compare_user).and_return(false)
    @provider.action_create
  end
  
  it "should call manage_user if the user exists and has mismatched attributes" do
    @provider.user_exists = true
    @provider.stub!(:compare_user).and_return(true)
    @provider.should_receive(:manage_user).and_return(true)
    @provider.action_create
  end
  
  it "should set the the new_resources updated flag when it creates the user if we call manage_user" do
    @provider.user_exists = true
    @provider.stub!(:compare_user).and_return(true)
    @provider.stub!(:manage_user).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_create
  end
end

describe Chef::Provider::User, "action_remove" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = false
    @provider.stub!(:remove_user).and_return(true)
  end
  
  it "should not call remove_user if the user does not exist" do
    @provider.should_not_receive(:remove_user) 
    @provider.action_remove
  end
  
  it "should call remove_user if the user exists" do
    @provider.user_exists = true
    @provider.should_receive(:remove_user)
    @provider.action_remove
  end
  
  it "should set the new_resources updated flag to true if the user is removed" do
    @provider.user_exists = true
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_remove
  end
end

describe Chef::Provider::User, "action_manage" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = true
    @provider.stub!(:manage_user).and_return(true)
  end
 
  it "should run manage_user if the user exists and has mismatched attributes" do
    @provider.should_receive(:compare_user).and_return(true)
    @provider.should_receive(:manage_user).and_return(true)
    @provider.action_manage
  end
  
  it "should set the new resources updated flag to true if manage_user is called" do
    @provider.stub!(:compare_user).and_return(true)
    @provider.stub!(:manage_user).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_manage
  end
  
  it "should not run manage_user if the user does not exist" do
    @provider.user_exists = false
    @provider.should_not_receive(:manage_user)
    @provider.action_manage
  end
  
  it "should not run manage_user if the user exists but has no differing attributes" do
    @provider.should_receive(:compare_user).and_return(false)
    @provider.should_not_receive(:manage_user)
    @provider.action_manage
  end
end

describe Chef::Provider::User, "action_modify" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = true
    @provider.stub!(:manage_user).and_return(true)
  end
 
  it "should run manage_user if the user exists and has mismatched attributes" do
    @provider.should_receive(:compare_user).and_return(true)
    @provider.should_receive(:manage_user).and_return(true)
    @provider.action_modify
  end
  
  it "should set the new resources updated flag to true if manage_user is called" do
    @provider.stub!(:compare_user).and_return(true)
    @provider.stub!(:manage_user).and_return(true)
    @new_resource.should_receive(:updated=).with(true).and_return(true)
    @provider.action_modify
  end
  
  it "should not run manage_user if the user exists but has no differing attributes" do
    @provider.should_receive(:compare_user).and_return(false)
    @provider.should_not_receive(:manage_user)
    @provider.action_modify
  end
  
  it "should raise a Chef::Exception::User if the user doesn't exist" do
    @provider.user_exists = false
    lambda { @provider.action_modify }.should raise_error(Chef::Exception::User)
  end
end

describe Chef::Provider::User, "check_lock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam"
    )
    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::User.new(@node, @new_resource)    
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)    
    @stdout.stub!(:gets).and_return("root P 09/02/2008 0 99999 7 -1")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should call passwd -S to check the lock status" do
    @provider.should_receive(:popen4).with("passwd -S #{@new_resource.username}").and_return(@status)
    @provider.check_lock
  end
  
  it "should get the first line of passwd -S STDOUT" do
    @provider.should_receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:gets).and_return("root P 09/02/2008 0 99999 7 -1")
    @provider.check_lock
  end
  
  it "should return false if status begins with P" do
    @provider.should_receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.check_lock.should eql(false)
  end
  
  it "should return false if status begins with N" do
    @stdout.stub!(:gets).and_return("root N")
    @provider.should_receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.check_lock.should eql(false)
  end
  
  it "should return true if status begins with L" do
    @stdout.stub!(:gets).and_return("root L")
    @provider.should_receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @provider.check_lock.should eql(true)
  end
  
  it "should raise a Chef::Exception::User if passwd -S fails" do
    @status.should_receive(:exitstatus).and_return(1)
    lambda { @provider.check_lock }.should raise_error(Chef::Exception::User)
  end
end

describe Chef::Provider::User, "action_lock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = true
    @provider.stub!(:check_lock).and_return(true)
    @provider.stub!(:lock_user).and_return(true)
  end
 
  it "should lock the user if it exists and is unlocked" do
    @provider.stub!(:check_lock).and_return(false)
    @provider.should_receive(:lock_user).and_return(true)
    @provider.action_lock
  end
 
  it "should set the new resources updated flag to true if lock_user is called" do
    @provider.stub!(:check_lock).and_return(false)
    @new_resource.should_receive(:updated=).with(true)
    @provider.action_lock
  end
  
  it "should raise a Chef::Exception::User if we try and lock a user that does not exist" do
    @provider.user_exists = false
    lambda { @provider.action_lock }.should raise_error(Chef::Exception::User)
  end
end

describe Chef::Provider::User, "action_unlock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @current_resource = mock("Chef::Resource::User", 
      :null_object => true
    )
    @provider = Chef::Provider::User.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.user_exists = true
    @provider.stub!(:check_lock).and_return(true)
    @provider.stub!(:unlock_user).and_return(true)
  end
 
  it "should unlock the user if it exists and is locked" do
    @provider.should_receive(:unlock_user).and_return(true)
    @provider.action_unlock
  end
 
  it "should set the new resources updated flag to true if unlock_user is called" do
    @new_resource.should_receive(:updated=).with(true)
    @provider.action_unlock
  end
  
  it "should raise a Chef::Exception::User if we try and unlock a user that does not exist" do
    @provider.user_exists = false
    lambda { @provider.action_unlock }.should raise_error(Chef::Exception::User)
  end
end