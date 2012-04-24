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

describe Chef::Provider::User::Useradd do
  include SpecHelpers::Provider

  let(:new_resource) { Chef::Resource::User.new('adam', run_context).tap(&with_attributes.call(new_resource_attributes)) }
  let(:current_resource) { Chef::Resource::User.new('adam', run_context).tap(&with_attributes.call(current_resource_attributes)) }
  let(:provider) { Chef::Provider::User::Useradd.new(new_resource, run_context).tap(&with_attributes.call(provider_attributes)) }

  let(:current_home_path) { new_home_path }
  let(:new_home_path) { '/home/adam' }

  let(:new_resource_attributes) do
    { :comment     => "Adam Jacob",
      :uid         => 1000,
      :gid         => 1000,
      :home        => new_home_path,
      :shell       => "/usr/bin/zsh",
      :password    => "abracadabra",
      :system      => false,
      :manage_home => false,
      :non_unique  => false }
  end

  let(:current_resource_attributes) do
    { :comment => "Adam Jacob",
      :uid => 1000,
      :gid => 1000,
      :home => current_home_path,
      :shell => "/usr/bin/zsh",
      :password => "abracadabra",
      :system => false,
      :manage_home => false,
      :non_unique => false,
      :supports => { :manage_home => false, :non_unique => false } }
  end

  let(:home) { '/home/adam' }
  let(:provider_attributes) { { :current_resource= => current_resource } }

  context "when setting option" do
    field_list = {
      'comment' => "-c",
      'gid' => "-g",
      'uid' => "-u",
      'shell' => "-s",
      'password' => "-p"
    }

    field_list.each do |attribute, option|
      it "should check for differences in #{attribute} between the new and current resources" do
        current_resource.should_receive(attribute)
        new_resource.should_receive(attribute)
        provider.universal_options
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil" do
        new_resource.stub!(attribute).and_return("hola")
        provider.universal_options.should eql(" #{option} 'hola'")
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil, without homedir management" do
        new_resource.stub!(:supports).and_return({:manage_home => false,
                                                    :non_unique => false})
        new_resource.stub!(attribute).and_return("hola")
        provider.universal_options.should eql(" #{option} 'hola'")
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not nil, without homedir management (using real attributes)" do
        new_resource.stub!(:manage_home).and_return(false)
        new_resource.stub!(:non_unique).and_return(false)
        new_resource.stub!(attribute).and_return("hola")
        provider.universal_options.should eql(" #{option} 'hola'")
      end
    end

    it "should combine all the possible options" do
      match_string = ""
      field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
        new_resource.stub!(attribute).and_return("hola")
        match_string << " #{option} 'hola'"
      end
      provider.universal_options.should eql(match_string)
    end

    context "when we want to create a system user" do
      before do
        new_resource.manage_home(true)
        new_resource.non_unique(false)
      end

      it "should set useradd -r" do
        new_resource.system(true)
        provider.useradd_options.should == " -r"
      end
    end

    context "when the resource has a different home directory and supports home directory management" do
      before do
        new_resource.stub!(:home).and_return("/wowaweea")
        new_resource.stub!(:supports).and_return({:manage_home => true,
                                                  :non_unique => false})
      end

      it "should set -d /homedir -m" do
        provider.universal_options.should == " -d '/wowaweea'"
        provider.useradd_options.should == " -m"
      end
    end

    context "when the resource has a different home directory and supports home directory management (using real attributes)" do
      before do
        new_resource.stub!(:home).and_return("/wowaweea")
        new_resource.stub!(:manage_home).and_return(true)
        new_resource.stub!(:non_unique).and_return(false)
      end

      it "should set -d /homedir -m" do
        provider.universal_options.should eql(" -d '/wowaweea'")
        provider.useradd_options.should == " -m"
      end
    end

    context "when the resource supports non_unique ids" do
      before do
        new_resource.stub!(:supports).and_return({:manage_home => false,
                                                  :non_unique => true})
      end

      it "should set -m -o" do
        provider.universal_options.should eql(" -o")
      end
    end

    context "when the resource supports non_unique ids (using real attributes)" do
      before do
        new_resource.stub!(:manage_home).and_return(false)
        new_resource.stub!(:non_unique).and_return(true)
      end

      it "should set -m -o" do
        provider.universal_options.should eql(" -o")
      end
    end
  end

  describe "#create_user" do
    before(:each) do
      provider.new_resource.manage_home true
      provider.new_resource.gid '23'
    end

    let(:current_resource_attributes) { { } }
    let(:expected_command) { "useradd -c 'Adam Jacob' -g '23' -p 'abracadabra' -s '/usr/bin/zsh' -u '1000' -d '/Users/mud' -m adam" }

    it "runs useradd with the computed command options" do
      provider.should_receive(:shell_out).with(expected_command ).and_return(true)
      provider.create_user
    end

    context "and home is not specified for new system user resource" do
      let(:home) { nil }
      let(:expected_command) { "useradd -c 'Adam Jacob' -g '23' -p 'abracadabra' -s '/usr/bin/zsh' -u '1000' adam" }

      it "should not include -d in the command options" do
        provider.should_receive(:shell_out).with(expected_command).and_return(true)
        provider.create_user
      end
    end

  end

  describe "#manage_user" do
    before(:each) do
      provider.new_resource.manage_home true
      provider.new_resource.home "/Users/mud"
      provider.new_resource.gid '23'
    end

    it "runs usermod with the computed command options" do
      provider.should_receive(:shell_out!).with("usermod -g '23' -d '/Users/mud' adam").and_return(true)
      provider.manage_user
    end

    it "does not set the -r option to usermod" do
      new_resource.system(true)
      provider.should_receive(:shell_out!).with("usermod -g '23' -d '/Users/mud' adam").and_return(true)
      provider.manage_user
    end

  end

  describe "#remove_user" do
    it "should run userdel with the new resources user name" do
      provider.should_receive(:shell_out!).with("userdel #{new_resource.username}").and_return(true)
      provider.remove_user
    end

    it "should run userdel with the new resources user name and -r if manage_home is true" do
      new_resource.stub!(:supports).and_return({ :manage_home => true,
                                                 :non_unique => false})
      provider.should_receive(:shell_out!).with("userdel -r #{new_resource.username}").and_return(true)
      provider.remove_user
    end

    it "should run userdel with the new resources user name if non_unique is true" do
      new_resource.stub!(:supports).and_return({ :manage_home => false,
                                                  :non_unique => true})
      provider.should_receive(:shell_out!).with("userdel #{new_resource.username}").and_return(true)
      provider.remove_user
    end
  end

  describe "#check_lock" do
    let(:passwd_status) { mock("passwd -S <username>", :exitstatus => exitstatus, :stdout => stdout) }
    let(:stdout) { "root P 09/02/2008 0 99999 7 -1" }
    let(:exitstatus) { 0 }

    let(:should_shell_out_to_passwd) do
      provider.
        should_receive(:shell_out!).
        with("passwd -S #{new_resource.username}").
        and_return(passwd_status)
    end

    it "should call passwd -S to check the lock status" do
      should_shell_out_to_passwd
      provider.check_lock
    end

    context 'when checking lock status' do
      subject { should_shell_out_to_passwd; provider.check_lock }
      context 'with status that begins with P' do
        let(:stdout) { "root P 09/02/2008 0 99999 7 -1" }

        it { should be_false }
      end

      context 'with status that begins with N' do
        let(:stdout) { "root N 09/02/2008 0 99999 7 -1" }
        it { should be_false }
      end

      context 'with status that begins with L' do
        let(:stdout) { "root L 09/02/2008 0 99999 7 -1" }
        it { should be_true }
      end
    end

    context "when using a broken passwd" do
      let(:given) do
        assume_broken_passwd
        should_shell_out_to_passwd
      end
      let(:assume_broken_passwd) { provider.stub!(:broken_passwd_version?).and_return(true) }

      context "when `passwd -S` exits with a 0" do
        let(:exitstatus) { 0 }

        it "should not raise a Chef::Exceptions::User" do
          given
          lambda { provider.check_lock }.should_not raise_error(Chef::Exceptions::User)
        end
      end

      context "when `passwd -S` exits with a 1" do
        let(:exitstatus) { 1 }

        it "should not raise a Chef::Exceptions::User" do
          given
          lambda { provider.check_lock }.should_not raise_error(Chef::Exceptions::User)
        end
      end
    end

    context "when using a sane passwd" do
      let(:given) do
        assume_sane_passwd
        should_shell_out_to_passwd
      end
      let(:assume_sane_passwd) { provider.stub!(:broken_passwd_version?).and_return(false) }

      context 'when `passwd -S` exists with a 0' do
        let(:exitstatus) { 0 }

        it "should not raise a Chef::Exceptions::User" do
          given
          lambda { provider.check_lock }.should_not raise_error(Chef::Exceptions::User)
        end
      end

      context 'when `passwd -S` exists with a 1' do
        let(:exitstatus) { 1 }

        it "should raise a Chef::Exceptions::User" do
          given
          lambda { provider.check_lock }.should raise_error(Chef::Exceptions::User)
        end
      end

      context 'when `passwd -S` exits with something other than 0 or 1' do
        let(:exitstatus) { rand(50) + 2 }

        it "should raise a Chef::Exceptions::User" do
          given
          lambda { provider.check_lock }.should raise_error(Chef::Exceptions::User)
        end
      end
    end
  end

  describe '#broken_passwd_version?' do
    subject { given; provider.broken_passwd_version? }

    let(:given) do
      assume_platform
      shell_out_to_rpm
    end

    let(:shell_out_to_rpm) { provider.should_receive(:shell_out!).with('rpm -q passwd').and_return(status) }
    let(:status) { mock('rpm -q passwd', :exitstatus => exitstatus, :stdout => passwd_version) }
    let(:exitstatus) { 0 }

    ['redhat', 'centos'].each do |os|
      context "when running on #{os}" do
        let(:assume_platform) { node.automatic_attrs[:platform] = os }

        context 'with passwd version 0.73-1' do
          let(:passwd_version) { 'passwd-0.73-1' }
          it { should be_true }
        end

        context 'with passwd version 0.73-2' do
          let(:passwd_version) { 'passwd-0.73-2' }
          it { should be_false }
        end
      end
    end

    context 'when not running on RHEL or CentOS' do
      let(:assume_platform) { node.automatic_attrs[:platform] = "Random Distro #{rand(10000)}" }
      let(:shell_out_to_rpm) { provider.should_not_receive(:shell_out!).with('rpm -q passwd').and_return(status) }
      let(:passwd_version) { "passwd-irrelevent-#{rand(100)}" }
      it { should be_false }
    end
  end

  describe "#lock_user" do
    it "should run usermod -L with the new resources username" do
      provider.should_receive(:shell_out!).with("usermod -L #{new_resource.username}")
      provider.lock_user
    end
  end

  describe "#unlock_user" do
    it "should run usermod -L with the new resources username" do
      provider.should_receive(:shell_out!).with("usermod -U #{new_resource.username}")
      provider.unlock_user
    end
  end

  describe "#updating_home?" do
    subject { provider.updating_home? }

    let(:current_home_path) { '/home/laurent' }

    context 'when current and new home paths matches' do
      let(:new_home_path) { current_home_path }
      it { should be_false }
    end

    context 'when current and new home paths do not match' do
      let(:new_home_path) { "/home/user#{rand(1000)}" }
      it { should be_true }
    end

    context 'when new home path differs only by trailing slash' do
      let(:new_home_path) { "#{current_home_path}/" }
      it { should be_false }
    end

    context 'when new home path is equivalent to current home path' do
      let(:new_home_path) { "/home/./laurent" }
      it { should be_false }
    end

    context 'when creating a new home path' do
      let(:current_home_path) { nil }
      it { should be_true }
    end
  end

end
