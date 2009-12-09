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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::User::Useradd, "set_options" do
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
      :password => "abracadabra",
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
      :password => "abracadabra",
      :updated => nil
    )
    @new_resource.stub!(:supports).and_return({:manage_home => false,
                                                :non_unique => false})
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  field_list = {
    'comment' => "-c",
    'gid' => "-g",
    'uid' => "-u",
    'shell' => "-s",
    'password' => "-p"
  }
  field_list.each do |attribute, option|
    it "should check for differences in #{attribute} between the new and current resources" do
      @current_resource.should_receive(attribute)
      @new_resource.should_receive(attribute)
      @provider.set_options
    end
    
    it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
      @new_resource.stub!(attribute).and_return("hola")
      @provider.set_options.should eql(" #{option} '#{@new_resource.send(attribute)}' #{@new_resource.username}")
    end
    
    it "should set the option for #{attribute} if the new resources #{attribute} is not null, without homedir management" do
      @new_resource.stub!(:supports).and_return({:manage_home => false,
                                                  :non_unique => false})
      @new_resource.stub!(attribute).and_return("hola")
      @provider.set_options.should eql(" #{option} '#{@new_resource.send(attribute)}' #{@new_resource.username}")
    end
  end
  
  it "should combine all the possible options" do
    match_string = ""
    field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
      @new_resource.stub!(attribute).and_return("hola")
      match_string << " #{option} 'hola'"
    end
    match_string << " adam"
    @provider.set_options.should eql(match_string)
  end
  
  describe "when the resource has a different home directory and supports home directory management" do
    before do
      @new_resource.stub!(:home).and_return("/wowaweea")
      @new_resource.stub!(:supports).and_return({:manage_home => true,
                                                :non_unique => false})
    end
    
    it "should set -d /homedir -m" do    
      @provider.set_options.should eql(" -d '/wowaweea' -m adam")
    end
  end

  describe "when the resource supports non_unique ids" do
    before do
      @new_resource.stub!(:supports).and_return({:manage_home => false,
                                                 :non_unique => true})
    end
    
    it "should set -m -o" do    
      @provider.set_options.should eql(" -o adam")
    end
  end
end

describe Chef::Provider::User::Useradd, "create_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
    @provider.stub!(:set_options).and_return(" monkey")
  end
  
  it "should run useradd with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "useradd monkey" }).and_return(true)
    @provider.create_user
  end
end

describe Chef::Provider::User::Useradd, "manage_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
    @provider.stub!(:set_options).and_return(" monkey")
  end
  
  it "should run usermod with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "usermod monkey" }).and_return(true)
    @provider.manage_user
  end
end

describe Chef::Provider::User::Useradd, "remove_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam",
      :supports => { :manage_home => false,
                     :non_unique => false}
    )
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
  end
  
  it "should run userdel with the new resources user name" do
    @provider.should_receive(:run_command).with({ :command => "userdel #{@new_resource.username}" }).and_return(true)
    @provider.remove_user
  end
  
  it "should run userdel with the new resources user name and -r if manage_home is true" do
    @new_resource.stub!(:supports).and_return({ :manage_home => true,
                                                :non_unique => false})
    @provider.should_receive(:run_command).with({ :command => "userdel -r #{@new_resource.username}"}).and_return(true)
    @provider.remove_user
  end

  it "should run userdel with the new resources user name if non_unique is true" do
    @new_resource.stub!(:supports).and_return({ :manage_home => false,
                                                :non_unique => true})
    @provider.should_receive(:run_command).with({ :command => "userdel #{@new_resource.username}"}).and_return(true)
    @provider.remove_user
  end
end

describe Chef::Provider::User::Useradd, "check_lock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @status = mock("Status", :exitstatus => 0)
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
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
  
  it "should raise a Chef::Exceptions::User if passwd -S fails" do
    @status.should_receive(:exitstatus).and_return(1)
    lambda { @provider.check_lock }.should raise_error(Chef::Exceptions::User)
  end
end

describe Chef::Provider::User::Useradd, "lock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam"
    )
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
  end
  
  it "should run usermod -L with the new resources username" do
    @provider.should_receive(:run_command).with({ :command => "usermod -L #{@new_resource.username}"})
    @provider.lock_user
  end
end

describe Chef::Provider::User::Useradd, "unlock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", 
      :null_object => true,
      :username => "adam"
    )
    @provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
  end
  
  it "should run usermod -L with the new resources username" do
    @provider.should_receive(:run_command).with({ :command => "usermod -U #{@new_resource.username}"})
    @provider.unlock_user
  end
end
