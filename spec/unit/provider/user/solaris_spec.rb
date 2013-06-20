#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
#
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

require 'spec_helper'

describe Chef::Provider::User::Solaris do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::User.new("adam", @run_context)
    @new_resource.comment "Adam Jacob"
    @new_resource.uid 1000
    @new_resource.gid 1000
    @new_resource.home "/home/adam"
    @new_resource.shell "/usr/bin/zsh"
    @new_resource.password "abracadabra"
    @new_resource.system false
    @new_resource.manage_home false
    @new_resource.non_unique false
    @current_resource = Chef::Resource::User.new("adam", @run_context)
    @current_resource.comment "Adam Jacob"
    @current_resource.uid 1000
    @current_resource.gid 1000
    @current_resource.home "/home/adam"
    @current_resource.shell "/usr/bin/zsh"
    @current_resource.password "abracadabra"
    @current_resource.system false
    @current_resource.manage_home false
    @current_resource.non_unique false
    @current_resource.supports({:manage_home => false, :non_unique => false})
    @provider = Chef::Provider::User::Solaris.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "when setting option" do
    field_list = {
      'comment' => "-c",
      'gid' => "-g",
      'uid' => "-u",
      'shell' => "-s"
    }

    field_list.each do |attribute, option|
      it "should check for differences in #{attribute} between the new and current resources" do
        @current_resource.should_receive(attribute)
        @new_resource.should_receive(attribute)
        @provider.universal_options
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil" do
        @new_resource.stub!(attribute).and_return("hola")
        @provider.universal_options.should eql(" #{option} 'hola'")
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil, without homedir management" do
        @new_resource.stub!(:supports).and_return({:manage_home => false,
                                                    :non_unique => false})
        @new_resource.stub!(attribute).and_return("hola")
        @provider.universal_options.should eql(" #{option} 'hola'")
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil, without homedir management (using real attributes)" do
        @new_resource.stub!(:manage_home).and_return(false)
        @new_resource.stub!(:non_unique).and_return(false)
        @new_resource.stub!(attribute).and_return("hola")
        @provider.universal_options.should eql(" #{option} 'hola'")
      end
    end

    it "should combine all the possible options" do
      match_string = ""
      field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
        @new_resource.stub!(attribute).and_return("hola")
        match_string << " #{option} 'hola'"
      end
      @provider.universal_options.should eql(match_string)
    end

    describe "when we want to set a password" do
      before do
        @new_resource.password "hocus-pocus"
      end

      it "should use its own shadow file writer to set the password" do
        @provider.should_receive(:write_shadow_file)
        @provider.stub!(:shell_out!).and_return(true)
        @provider.manage_user
      end

      it "should write out a modified version of the password file" do
        password_file = Tempfile.new("shadow")
        password_file.puts "adam:existingpassword:15441::::::"
        password_file.close
        @provider.password_file = password_file.path
        @provider.stub!(:shell_out!).and_return(true)
        # may not be able to write to /etc for tests...
        temp_file = Tempfile.new("shadow")
        Tempfile.stub!(:new).with("shadow", "/etc").and_return(temp_file)
        @new_resource.password "verysecurepassword"
        @provider.manage_user
        ::File.open(password_file.path, "r").read.should =~ /adam:verysecurepassword:/
        password_file.unlink
      end
    end

    describe "when we want to create a system user" do
      before do
        @new_resource.manage_home(true)
        @new_resource.non_unique(false)
      end

      it "should set useradd -r" do
        @new_resource.system(true)
        @provider.useradd_options.should == " -r"
      end
    end

    describe "when the resource has a different home directory and supports home directory management" do
      before do
        @new_resource.stub!(:home).and_return("/wowaweea")
        @new_resource.stub!(:supports).and_return({:manage_home => true,
                                                   :non_unique => false})
      end

      it "should set -m -d /homedir" do
        @provider.universal_options.should == " -m -d '/wowaweea'"
        @provider.useradd_options.should == ""
      end
    end

    describe "when the resource has a different home directory and supports home directory management (using real attributes)" do
      before do
        @new_resource.stub!(:home).and_return("/wowaweea")
        @new_resource.stub!(:manage_home).and_return(true)
        @new_resource.stub!(:non_unique).and_return(false)
      end

      it "should set -m -d /homedir" do
        @provider.universal_options.should eql(" -m -d '/wowaweea'")
        @provider.useradd_options.should == ""
      end
    end

    describe "when the resource supports non_unique ids" do
      before do
        @new_resource.stub!(:supports).and_return({:manage_home => false,
                                                  :non_unique => true})
      end

      it "should set -m -o" do
        @provider.universal_options.should eql(" -o")
      end
    end

    describe "when the resource supports non_unique ids (using real attributes)" do
      before do
        @new_resource.stub!(:manage_home).and_return(false)
        @new_resource.stub!(:non_unique).and_return(true)
      end

      it "should set -m -o" do
        @provider.universal_options.should eql(" -o")
      end
    end
  end

  describe "when creating a user" do
    before(:each) do
      @current_resource = Chef::Resource::User.new(@new_resource.name, @run_context)
      @current_resource.username(@new_resource.username)
      @provider.current_resource = @current_resource
      @provider.new_resource.manage_home true
      @provider.new_resource.home "/Users/mud"
      @provider.new_resource.gid '23'
    end

    it "runs useradd with the computed command options" do
      command = "useradd -c 'Adam Jacob' -g '23' -s '/usr/bin/zsh' -u '1000' -m -d '/Users/mud' adam"
      @provider.should_receive(:shell_out!).with(command).and_return(true)
      @provider.should_receive(:manage_password).and_return(nil)
      @provider.create_user
    end

    describe "and home is not specified for new system user resource" do

      before do
        @provider.new_resource.system true
        # there is no public API to set attribute's value to nil
        @provider.new_resource.instance_variable_set("@home", nil)
      end

      it "should not include -m or -d in the command options" do
        command = "useradd -c 'Adam Jacob' -g '23' -s '/usr/bin/zsh' -u '1000' -r adam"
        @provider.should_receive(:shell_out!).with(command).and_return(true)
        @provider.should_receive(:manage_password).and_return(nil)
        @provider.create_user
      end

    end

  end

  describe "when managing a user" do
    before(:each) do
      @provider.new_resource.manage_home true
      @provider.new_resource.home "/Users/mud"
      @provider.new_resource.gid '23'
    end

    # CHEF-3423, -m must come before the username
    it "runs usermod with the computed command options" do
      @provider.should_receive(:shell_out!).with("usermod -g '23' -m -d '/Users/mud' adam").and_return(true)
      @provider.manage_user
    end

    it "does not set the -r option to usermod" do
      @new_resource.system(true)
      @provider.should_receive(:shell_out!).with("usermod -g '23' -m -d '/Users/mud' adam").and_return(true)
      @provider.manage_user
    end

    it "CHEF-3429: does not set -m if we aren't changing the home directory" do
      @provider.should_receive(:updating_home?).and_return(false)
      @provider.should_receive(:shell_out!).with("usermod -g '23' adam").and_return(true)
      @provider.manage_user
    end
  end

  describe "when removing a user" do

    it "should run userdel with the new resources user name" do
      @provider.should_receive(:shell_out!).with("userdel #{@new_resource.username}").and_return(true)
      @provider.remove_user
    end

    it "should run userdel with the new resources user name and -r if manage_home is true" do
      @new_resource.stub!(:supports).and_return({ :manage_home => true,
                                                  :non_unique => false})
      @provider.should_receive(:shell_out!).with("userdel -r #{@new_resource.username}").and_return(true)
      @provider.remove_user
    end

    it "should run userdel with the new resources user name if non_unique is true" do
      @new_resource.stub!(:supports).and_return({ :manage_home => false,
                                                  :non_unique => true})
      @provider.should_receive(:shell_out!).with("userdel #{@new_resource.username}").and_return(true)
      @provider.remove_user
    end
  end

  describe "when checking the lock" do
    # lazy initialize so we can modify stdout and stderr strings
    let(:passwd_s_status) do
      mock("Mixlib::ShellOut command", :exitstatus => 0, :stdout => @stdout, :stderr => @stderr)
    end

    before(:each) do
      # @node = Chef::Node.new
      # @new_resource = mock("Chef::Resource::User",
      #   :nil_object => true,
      #   :username => "adam"
      # )
      #@provider = Chef::Provider::User::Useradd.new(@node, @new_resource)
      @stdout = "root P 09/02/2008 0 99999 7 -1"
      @stderr = ""
    end

    it "should return false if status begins with P" do
      @provider.should_receive(:shell_out!).with("passwd -S #{@new_resource.username}", {:returns=>[0, 1]}).and_return(passwd_s_status)
      @provider.check_lock.should eql(false)
    end

    it "should return false if status begins with N" do
      @stdout = "root N"
      @provider.should_receive(:shell_out!).with("passwd -S #{@new_resource.username}", {:returns=>[0, 1]}).and_return(passwd_s_status)
      @provider.check_lock.should eql(false)
    end

    it "should return true if status begins with L" do
      @stdout = "root L"
      @provider.should_receive(:shell_out!).with("passwd -S #{@new_resource.username}", {:returns=>[0, 1]}).and_return(passwd_s_status)
      @provider.check_lock.should eql(true)
    end

    it "should raise a Chef::Exceptions::User if passwd -S fails" do
      @node.automatic_attrs[:platform] = 'solaris2'
      @provider.should_receive(:shell_out!).with("passwd -S #{@new_resource.username}", {:returns=>[0, 1]}).and_return(passwd_s_status)
      passwd_s_status.should_receive(:exitstatus).and_return(1)
      lambda { @provider.check_lock }.should raise_error(Chef::Exceptions::User)
    end
  end

  describe "when locking the user" do
    it "should run usermod -L with the new resources username" do
      @provider.should_receive(:shell_out!).with("usermod -L #{@new_resource.username}")
      @provider.lock_user
    end
  end

  describe "when unlocking the user" do
    it "should run usermod -L with the new resources username" do
      @provider.should_receive(:shell_out!).with("usermod -U #{@new_resource.username}")
      @provider.unlock_user
    end
  end

  describe "when checking if home needs updating" do
    [
     {
       "action" => "should return false if home matches",
       "current_resource_home" => [ "/home/laurent" ],
       "new_resource_home" => [ "/home/laurent" ],
       "expected_result" => false
     },
     {
       "action" => "should return true if home doesn't match",
       "current_resource_home" => [ "/home/laurent" ],
       "new_resource_home" => [ "/something/else" ],
       "expected_result" => true
     },
     {
       "action" => "should return false if home only differs by trailing slash",
       "current_resource_home" => [ "/home/laurent" ],
       "new_resource_home" => [ "/home/laurent/", "/home/laurent" ],
       "expected_result" => false
     },
     {
       "action" => "should return false if home is an equivalent path",
       "current_resource_home" => [ "/home/laurent" ],
       "new_resource_home" => [ "/home/./laurent", "/home/laurent" ],
       "expected_result" => false
     },
    ].each do |home_check|
      it home_check["action"] do
        @provider.current_resource.home home_check["current_resource_home"].first
        @current_home_mock = mock("Pathname")
        @provider.new_resource.home home_check["new_resource_home"].first
        @new_home_mock = mock("Pathname")

        Pathname.should_receive(:new).with(@current_resource.home).and_return(@current_home_mock)
        @current_home_mock.should_receive(:cleanpath).and_return(home_check["current_resource_home"].last)
        Pathname.should_receive(:new).with(@new_resource.home).and_return(@new_home_mock)
        @new_home_mock.should_receive(:cleanpath).and_return(home_check["new_resource_home"].last)

        @provider.updating_home?.should == home_check["expected_result"]
      end
    end
    it "should return true if the current home does not exist but a home is specified by the new resource" do
      @new_resource = Chef::Resource::User.new("adam", @run_context)
      @current_resource = Chef::Resource::User.new("adam", @run_context)
      @provider = Chef::Provider::User::Solaris.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
      @current_resource.home nil
      @new_resource.home "/home/kitten"

      @provider.updating_home?.should == true
    end
  end
end
