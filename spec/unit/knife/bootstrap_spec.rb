#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Copyright:: Copyright (c) 2010 Ian Meyer
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

Chef::Knife::Bootstrap.load_deps
require 'net/ssh'

describe Chef::Knife::Bootstrap do
  before(:all) do
    @original_config = Chef::Config.hash_dup
    @original_knife_config = Chef::Config[:knife].dup
  end

  after(:all) do
    Chef::Config.configuration = @original_config
    Chef::Config[:knife] = @original_knife_config
  end

  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)
    @knife = Chef::Knife::Bootstrap.new
    # Merge default settings in.
    @knife.merge_configs
    @knife.config[:template_file] = File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test.erb"))
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@stdout)
    @stderr = StringIO.new
    @knife.ui.stub!(:stderr).and_return(@stderr)
  end

  it "should return a name of default bootstrap template" do
    @knife.find_template.should be_a_kind_of(String)
  end

  it "should error if template can not be found" do
    @knife.config[:template_file] = false
    @knife.config[:distro] = 'penultimate'
    lambda { @knife.find_template }.should raise_error
  end

  it "should look for templates early in the run" do
    File.stub(:exists?).and_return(true)
    @knife.name_args = ['shatner']
    @knife.stub!(:read_template).and_return("")
    @knife.stub!(:knife_ssh).and_return(true)
    @knife_ssh = @knife.knife_ssh
    @knife.should_receive(:find_template).ordered
    @knife.should_receive(:knife_ssh).ordered
    @knife_ssh.should_receive(:run) # rspec appears to keep order per object
    @knife.run
  end

  it "should load the specified template" do
    @knife.config[:distro] = 'fedora13-gems'
    lambda { @knife.find_template }.should_not raise_error
  end

  it "should load the specified template from a Ruby gem" do
    @knife.config[:template_file] = false
    Gem.stub(:find_files).and_return(["/Users/schisamo/.rvm/gems/ruby-1.9.2-p180@chef-0.10/gems/knife-windows-0.5.4/lib/chef/knife/bootstrap/fake-bootstrap-template.erb"])
    File.stub(:exists?).and_return(true)
    IO.stub(:read).and_return('random content')
    @knife.config[:distro] = 'fake-bootstrap-template'
    lambda { @knife.find_template }.should_not raise_error
  end

  it "should return an empty run_list" do
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.render_template(template_string).should == '{"run_list":[]}'
  end

  it "should have role[base] in the run_list" do
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.parse_options(["-r","role[base]"])
    @knife.render_template(template_string).should == '{"run_list":["role[base]"]}'
  end

  it "should have role[base] and recipe[cupcakes] in the run_list" do
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.parse_options(["-r", "role[base],recipe[cupcakes]"])
    @knife.render_template(template_string).should == '{"run_list":["role[base]","recipe[cupcakes]"]}'
  end

  it "should have foo => {bar => baz} in the first_boot" do
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.parse_options(["-j", '{"foo":{"bar":"baz"}}'])
    expected_hash = Yajl::Parser.new.parse('{"foo":{"bar":"baz"},"run_list":[]}')
    actual_hash = Yajl::Parser.new.parse(@knife.render_template(template_string))
    actual_hash.should == expected_hash
  end

  it "should create a hint file when told to" do
    @knife.config[:template_file] = File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test-hints.erb"))
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.parse_options(["--hint", "openstack"])
    @knife.render_template(template_string).should match /\/etc\/chef\/ohai\/hints\/openstack.json/
  end

  it "should populate a hint file with JSON when given a file to read" do
    @knife.stub(:find_template).and_return(true)
    @knife.config[:template_file] = File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test-hints.erb"))
    ::File.stub!(:read).and_return('{ "foo" : "bar" }')
    @knife.instance_variable_set("@template_file", @knife.config[:template_file])
    template_string = @knife.read_template
    @knife.stub!(:read_template).and_return('{ "foo" : "bar" }')
    @knife.parse_options(["--hint", "openstack=hints/openstack.json"])
    @knife.render_template(template_string).should match /\{\"foo\":\"bar\"\}/
  end


  it "should take the node name from ARGV" do
    @knife.name_args = ['barf']
    @knife.name_args.first.should == "barf"
  end

  describe "when configuring the underlying knife ssh command"
    context "from the command line" do
      before do
        @knife.name_args = ["foo.example.com"]
        @knife.config[:ssh_user]      = "rooty"
        @knife.config[:ssh_port]      = "4001"
        @knife.config[:ssh_password]  = "open_sesame"
        Chef::Config[:knife][:ssh_user] = nil
        Chef::Config[:knife][:ssh_port] = nil
        @knife.config[:identity_file] = "~/.ssh/me.rsa"
        @knife.stub!(:read_template).and_return("")
        @knife_ssh = @knife.knife_ssh
      end
  
      it "configures the hostname" do
        @knife_ssh.name_args.first.should == "foo.example.com"
      end
  
      it "configures the ssh user" do
        @knife_ssh.config[:ssh_user].should == 'rooty'
      end
  
      it "configures the ssh password" do
        @knife_ssh.config[:ssh_password].should == 'open_sesame'
      end
  
      it "configures the ssh port" do
        @knife_ssh.config[:ssh_port].should == '4001'
      end
  
      it "configures the ssh identity file" do
        @knife_ssh.config[:identity_file].should == '~/.ssh/me.rsa'
      end
    end

    context "from the knife config file" do
      before do
        @knife.name_args = ["config.example.com"]
        @knife.config[:ssh_user] = nil
        @knife.config[:ssh_port] = nil
        @knife.config[:ssh_gateway] = nil
        @knife.config[:identity_file] = nil
        @knife.config[:host_key_verify] = nil
        Chef::Config[:knife][:ssh_user] = "curiosity"
        Chef::Config[:knife][:ssh_port] = "2430"
        Chef::Config[:knife][:identity_file] = "~/.ssh/you.rsa"
        Chef::Config[:knife][:ssh_gateway] = "towel.blinkenlights.nl"
        Chef::Config[:knife][:host_key_verify] = true
        @knife.stub!(:read_template).and_return("")
        @knife_ssh = @knife.knife_ssh
      end
  
      it "configures the ssh user" do
        @knife_ssh.config[:ssh_user].should == 'curiosity'
      end
  
      it "configures the ssh port" do
        @knife_ssh.config[:ssh_port].should == '2430'
      end
  
      it "configures the ssh identity file" do
        @knife_ssh.config[:identity_file].should == '~/.ssh/you.rsa'
      end
  
      it "configures the ssh gateway" do
        @knife_ssh.config[:ssh_gateway].should == 'towel.blinkenlights.nl'
      end

      it "configures the host key verify mode" do
        @knife_ssh.config[:host_key_verify].should == true
      end
  end

  describe "when falling back to password auth when host key auth fails" do
    before do
      @knife.name_args = ["foo.example.com"]
      @knife.config[:ssh_user]      = "rooty"
      @knife.config[:identity_file] = "~/.ssh/me.rsa"
      @knife.stub!(:read_template).and_return("")
      @knife_ssh = @knife.knife_ssh
    end

    it "prompts the user for a password " do
      @knife.stub!(:knife_ssh).and_return(@knife_ssh)
      @knife_ssh.stub!(:get_password).and_return('typed_in_password')
      alternate_knife_ssh = @knife.knife_ssh_with_password_auth
      alternate_knife_ssh.config[:ssh_password].should == 'typed_in_password'
    end

    it "configures knife not to use the identity file that didn't work previously" do
      @knife.stub!(:knife_ssh).and_return(@knife_ssh)
      @knife_ssh.stub!(:get_password).and_return('typed_in_password')
      alternate_knife_ssh = @knife.knife_ssh_with_password_auth
      alternate_knife_ssh.config[:identity_file].should be_nil
    end
  end

  describe "when running the bootstrap" do
    before do
      @knife.name_args = ["foo.example.com"]
      @knife.config[:ssh_user]      = "rooty"
      @knife.config[:identity_file] = "~/.ssh/me.rsa"
      @knife.stub!(:read_template).and_return("")
      @knife_ssh = @knife.knife_ssh
      @knife.stub!(:knife_ssh).and_return(@knife_ssh)
    end

    it "verifies that a server to bootstrap was given as a command line arg" do
      @knife.name_args = nil
      lambda { @knife.run }.should raise_error(SystemExit)
      @stderr.string.should match /ERROR:.+FQDN or ip/
    end

    it "configures the underlying ssh command and then runs it" do
      @knife_ssh.should_receive(:run)
      @knife.run
    end

    it "falls back to password based auth when auth fails the first time" do
      @knife.stub!(:puts)

      @fallback_knife_ssh = @knife_ssh.dup
      @knife_ssh.should_receive(:run).and_raise(Net::SSH::AuthenticationFailed.new("no ssh for you"))
      @knife.stub!(:knife_ssh_with_password_auth).and_return(@fallback_knife_ssh)
      @fallback_knife_ssh.should_receive(:run)
      @knife.run
    end

  end

end
