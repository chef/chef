#
# Author:: Stephen Haynes (<sh@nomitor.com>)
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

describe Chef::Provider::User::Pw, "set_options" do
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
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end
  
  field_list = {
    'comment' => "-c",
    'home' => "-d",
    'gid' => "-g",
    'uid' => "-u",
    'shell' => "-s"
  }
  field_list.each do |attribute, option|
    it "should check for differences in #{attribute} between the new and current resources" do
      @current_resource.should_receive(attribute)
      @new_resource.should_receive(attribute)
      @provider.set_options
    end
    
    it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
      @new_resource.stub!(attribute).and_return("hola")
      @provider.set_options.should eql(" #{@new_resource.username} #{option} '#{@new_resource.send(attribute)}' -m")
    end
    
    it "should set the option for #{attribute} if the new resources #{attribute} is not null, without homedir management" do
      @new_resource.stub!(:supports).and_return({:manage_home => false})
      @new_resource.stub!(attribute).and_return("hola")
      @provider.set_options.should eql(" #{@new_resource.username} #{option} '#{@new_resource.send(attribute)}'")
    end
  end
  
  it "should combine all the possible options" do
    match_string = " adam"
    field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
      @new_resource.stub!(attribute).and_return("hola")
      match_string << " #{option} 'hola'"
    end
    match_string << " -m"
    @provider.set_options.should eql(match_string)
  end
end

describe Chef::Provider::User::Pw, "create_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
    @provider.stub!(:modify_password).and_return(true)
  end
  
  it "should run pw useradd with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "pw useradd monkey" }).and_return(true)
    @provider.create_user
  end
  
  it "should modify the password" do
    @provider.should_receive(:modify_password).and_return(true)
    @provider.create_user
  end
end

describe Chef::Provider::User::Pw, "manage_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    @provider.stub!(:run_command).and_return(true)
    @provider.stub!(:set_options).and_return(" monkey")
    @provider.stub!(:modify_password).and_return(true)
  end
  
  it "should run pw usermod with the return of set_options" do
    @provider.should_receive(:run_command).with({ :command => "pw usermod monkey" }).and_return(true)
    @provider.manage_user
  end
  
  it "should modify the password" do
    @provider.should_receive(:modify_password).and_return(true)
    @provider.create_user
  end
end

describe Chef::Provider::User::Pw, "remove_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :supports => { :manage_home => false }
    )
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
  end
  
  it "should run pw userdel with the new resources user name" do
    @provider.should_receive(:run_command).with({ :command => "pw userdel #{@new_resource.username}" }).and_return(true)
    @provider.remove_user
  end
  
  it "should run pw userdel with the new resources user name and -r if manage_home is true" do
    @new_resource.stub!(:supports).and_return({ :manage_home => true })
    @provider.should_receive(:run_command).with({ :command => "pw userdel #{@new_resource.username} -r"}).and_return(true)
    @provider.remove_user
  end
end

describe Chef::Provider::User::Pw, "check_lock" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true)
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :password => "abracadabra"
    )
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should return true if user is locked" do
    @current_resource.stub!(:password).and_return("*LOCKED*abracadabra")
    @provider.check_lock.should eql(true)
  end

  it "should return false if user is not locked" do
    @current_resource.stub!(:password).and_return("abracadabra")
    @provider.check_lock.should eql(false)
  end
end

describe Chef::Provider::User::Pw, "lock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
  end
  
  it "should run pw lock with the new resources username" do
    @provider.should_receive(:run_command).with({ :command => "pw lock #{@new_resource.username}"})
    @provider.lock_user
  end
end

describe Chef::Provider::User::Pw, "unlock_user" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam"
    )
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
  end
  
  it "should run pw unlock with the new resources username" do
    @provider.should_receive(:run_command).with({ :command => "pw unlock #{@new_resource.username}"})
    @provider.unlock_user
  end
end

describe Chef::Provider::User::Pw, "modify_password" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :password => "abracadabra"
    )
    @current_resource = mock("Chef::Resource::User",
      :null_object => true,
      :username => "adam",
      :password => "abracadabra"
    )
    @new_resource.stub!(:to_s).and_return("user[adam]")
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end
  
  it "should check for differences in password between the new and current resources" do
    @current_resource.should_receive(:password)
    @new_resource.should_receive(:password)
    @provider.modify_password
  end
  
  describe "with both passwords being identical" do
    before(:each) do
      @new_resource.stub!(:password).and_return("abracadabra")
      @current_resource.stub!(:password).and_return("abracadabra")
    end
    
    it "should log an appropriate message" do
      Chef::Log.should_receive(:debug).with("user[adam]: no change needed to password")
      @provider.modify_password
    end
  end
  
  describe "with differing passwords" do
    before(:each) do
      @new_resource.stub!(:password).and_return("abracadabra")
      @current_resource.stub!(:password).and_return("sesame")
    end
    
    it "should log an appropriate message" do
      Chef::Log.should_receive(:debug).with("user[adam]: updating password")
      @provider.modify_password
    end
    
    it "should run pw usermod with the username and the option -H 0" do
      @provider.should_receive(:popen4).with("pw usermod adam -H 0", :waitlast => true).and_return(@status)
      @provider.modify_password
    end
    
    it "should send the new password to the stdin of pw usermod" do
      @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @stdin.should_receive(:puts).with("abracadabra")
      @provider.modify_password
    end
    
    it "should raise an exception if pw usermod fails" do
      @status.should_receive(:exitstatus).and_return(1)
      lambda { @provider.modify_password }.should raise_error(Chef::Exceptions::User)
    end
    
    it "should not raise an exception if pw usermod succeeds" do
      @status.should_receive(:exitstatus).and_return(0)
      lambda { @provider.modify_password }.should_not raise_error(Chef::Exceptions::User)
    end
  end
end

describe Chef::Provider::User::Pw, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::User", :null_object => true, :username => "adam")
    @provider = Chef::Provider::User::Pw.new(@node, @new_resource)
    File.stub!(:exists?).and_return(false)
  end
  
  it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
    File.should_receive(:exists?).with("/usr/sbin/pw").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::User)
  end
  
  it "shouldn't raise an error if /usr/sbin/pw exists" do
    File.stub!(:exists?).and_return(true)
    lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::User)
  end
end