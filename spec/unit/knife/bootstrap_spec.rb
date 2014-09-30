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
  before do
    Chef::Platform.stub(:windows?) { false }
  end
  let(:knife) do
    Chef::Log.logger = Logger.new(StringIO.new)
    Chef::Config[:knife][:bootstrap_template] = bootstrap_template unless bootstrap_template.nil?

    k = Chef::Knife::Bootstrap.new
    k.merge_configs

    k.ui.stub(:stderr).and_return(stderr)
    allow(k).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(false)
    k
  end

  let(:stderr) { StringIO.new }

  let(:bootstrap_template) { nil }

  it "should use chef-full as default template" do
    knife.bootstrap_template.should be_a_kind_of(String)
    File.basename(knife.bootstrap_template).should eq("chef-full")
  end

  context "when finding templates" do
    context "when :bootstrap_template config is set to a file" do
      context "that doesn't exist" do
        let(:bootstrap_template) { "/opt/blah/not/exists/template.erb" }

        it "raises an error" do
          lambda { knife.find_template }.should raise_error
        end
      end

      context "that exists" do
        let(:bootstrap_template) { File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test.erb")) }

        it "loads the given file as the template" do
          Chef::Log.should_receive(:debug)
          knife.find_template.should eq(File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test.erb")))
        end
      end
    end

    context "when :bootstrap_template config is set to a template name" do
      let(:bootstrap_template) { "example" }

      let(:builtin_template_path) { File.expand_path(File.join(File.dirname(__FILE__), '../../../lib/chef/knife/bootstrap', "example.erb"))}

      let(:chef_config_dir_template_path) { "/knife/chef/config/bootstrap/example.erb" }

      let(:env_home_template_path) { "/env/home/.chef/bootstrap/example.erb" }

      let(:gem_files_template_path) { "/Users/schisamo/.rvm/gems/ruby-1.9.2-p180@chef-0.10/gems/knife-windows-0.5.4/lib/chef/knife/bootstrap/fake-bootstrap-template.erb" }

      def configure_chef_config_dir
        Chef::Knife.stub(:chef_config_dir).and_return("/knife/chef/config")
      end

      def configure_env_home
        ENV['HOME'] = "/env/home"
      end

      def configure_gem_files
        Gem.stub(:find_files).and_return([ gem_files_template_path ])
      end

      before(:each) do
        @original_home = ENV['HOME']
        ENV['HOME'] = nil
        File.should_receive(:exists?).with(bootstrap_template).and_return(false)
      end

      after(:each) do
        ENV['HOME'] = @original_home
      end

      context "when file is available everywhere" do
        before do
          configure_chef_config_dir
          configure_env_home
          configure_gem_files

          File.should_receive(:exists?).with(builtin_template_path).and_return(true)
        end

        it "should load the template from built-in templates" do
          knife.find_template.should eq(builtin_template_path)
        end
      end

      context "when file is available in chef_config_dir" do
        before do
          configure_chef_config_dir
          configure_env_home
          configure_gem_files

          File.should_receive(:exists?).with(builtin_template_path).and_return(false)
          File.should_receive(:exists?).with(chef_config_dir_template_path).and_return(true)

          it "should load the template from chef_config_dir" do
            knife.find_template.should eq(chef_config_dir_template_path)
          end
        end
      end

      context "when file is available in ENV['HOME']" do
        before do
          configure_chef_config_dir
          configure_env_home
          configure_gem_files

          File.should_receive(:exists?).with(builtin_template_path).and_return(false)
          File.should_receive(:exists?).with(chef_config_dir_template_path).and_return(false)
          File.should_receive(:exists?).with(env_home_template_path).and_return(true)
        end

        it "should load the template from chef_config_dir" do
          knife.find_template.should eq(env_home_template_path)
        end
      end

      context "when file is available in Gem files" do
        before do
          configure_chef_config_dir
          configure_gem_files

          File.should_receive(:exists?).with(builtin_template_path).and_return(false)
          File.should_receive(:exists?).with(chef_config_dir_template_path).and_return(false)
          File.should_receive(:exists?).with(gem_files_template_path).and_return(true)
        end

        it "should load the template from Gem files" do
          knife.find_template.should eq(gem_files_template_path)
        end
      end
    end
  end

  ["-d", "--distro", "-t", "--bootstrap-template", "--template-file"].each do |t|
    context "when #{t} option is given in the command line" do
      it "sets the knife :bootstrap_template config" do
        knife.parse_options([t,"blahblah"])
        knife.merge_configs
        knife.bootstrap_template.should eq("blahblah")
      end
    end
  end

  context "with run_list template" do
    let(:bootstrap_template) { File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test.erb")) }

    it "should return an empty run_list" do
      knife.render_template.should == '{"run_list":[]}'
    end

    it "should have role[base] in the run_list" do
      knife.parse_options(["-r","role[base]"])
      knife.merge_configs
      knife.render_template.should == '{"run_list":["role[base]"]}'
    end

    it "should have role[base] and recipe[cupcakes] in the run_list" do
      knife.parse_options(["-r", "role[base],recipe[cupcakes]"])
      knife.merge_configs
      knife.render_template.should == '{"run_list":["role[base]","recipe[cupcakes]"]}'
    end

    it "should have foo => {bar => baz} in the first_boot" do
      knife.parse_options(["-j", '{"foo":{"bar":"baz"}}'])
      knife.merge_configs
      expected_hash = FFI_Yajl::Parser.new.parse('{"foo":{"bar":"baz"},"run_list":[]}')
      actual_hash = FFI_Yajl::Parser.new.parse(knife.render_template)
      actual_hash.should == expected_hash
    end
  end

  context "with hints template" do
    let(:bootstrap_template) { File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "test-hints.erb")) }

    it "should create a hint file when told to" do
      knife.parse_options(["--hint", "openstack"])
      knife.merge_configs
      knife.render_template.should match /\/etc\/chef\/ohai\/hints\/openstack.json/
    end

    it "should populate a hint file with JSON when given a file to read" do
      ::File.stub(:read).and_return('{ "foo" : "bar" }')
      knife.parse_options(["--hint", "openstack=hints/openstack.json"])
      knife.merge_configs
      knife.render_template.should match /\{\"foo\":\"bar\"\}/
    end
  end

  describe "specifying no_proxy with various entries" do
    subject(:knife) do
      k = described_class.new
      Chef::Config[:knife][:bootstrap_template] = template_file
      k.parse_options(options)
      k.merge_configs
      k
    end

    let(:options){ ["--bootstrap-no-proxy", setting, "-s", "foo"] }
    let(:template_file) { File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "no_proxy.erb")) }
    let(:rendered_template) do
      knife.render_template
    end

    context "via --bootstrap-no-proxy" do
      let(:setting) { "api.opscode.com" }

      it "renders the client.rb with a single FQDN no_proxy entry" do
        rendered_template.should match(%r{.*no_proxy\s*"api.opscode.com".*})
      end
    end

    context "via --bootstrap-no-proxy multiple" do
      let(:setting) { "api.opscode.com,172.16.10.*" }

      it "renders the client.rb with comma-separated FQDN and wildcard IP address no_proxy entries" do
        rendered_template.should match(%r{.*no_proxy\s*"api.opscode.com,172.16.10.\*".*})
      end
    end

    context "via --ssl-verify-mode none" do
      let(:options) { ["--node-ssl-verify-mode", "none"] }

      it "renders the client.rb with ssl_verify_mode set to :verify_none" do
        rendered_template.should match(/ssl_verify_mode :verify_none/)
      end
    end

    context "via --node-ssl-verify-mode peer" do
      let(:options) { ["--node-ssl-verify-mode", "peer"] }

      it "renders the client.rb with ssl_verify_mode set to :verify_peer" do
        rendered_template.should match(/ssl_verify_mode :verify_peer/)
      end
    end

    context "via --node-ssl-verify-mode all" do
      let(:options) { ["--node-ssl-verify-mode", "all"] }

      it "raises error" do
        lambda{ rendered_template }.should raise_error
      end
    end

    context "via --node-verify-api-cert" do
      let(:options) { ["--node-verify-api-cert"] }

      it "renders the client.rb with verify_api_cert set to true" do
        rendered_template.should match(/verify_api_cert true/)
      end
    end

    context "via --no-node-verify-api-cert" do
      let(:options) { ["--no-node-verify-api-cert"] }

      it "renders the client.rb with verify_api_cert set to false" do
        rendered_template.should match(/verify_api_cert false/)
      end
    end
  end

  describe "specifying the encrypted data bag secret key" do
    let(:secret) { "supersekret" }
    let(:options) { [] }
    let(:bootstrap_template) { File.expand_path(File.join(CHEF_SPEC_DATA, "bootstrap", "secret.erb")) }
    let(:rendered_template) do
      knife.parse_options(options)
      knife.merge_configs
      knife.render_template
    end

    it "creates a secret file" do
      expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(true)
      expect(knife).to receive(:read_secret).and_return(secret)
      rendered_template.should match(%r{#{secret}})
    end

    it "renders the client.rb with an encrypted_data_bag_secret entry" do
      expect(knife).to receive(:encryption_secret_provided_ignore_encrypt_flag?).and_return(true)
      expect(knife).to receive(:read_secret).and_return(secret)
      rendered_template.should match(%r{encrypted_data_bag_secret\s*"/etc/chef/encrypted_data_bag_secret"})
    end

  end

  describe "when transferring trusted certificates" do
    let(:trusted_certs_dir) { Chef::Util::PathHelper.cleanpath(File.join(File.dirname(__FILE__), '../../data/trusted_certs')) }

    let(:rendered_template) do
      knife.merge_configs
      knife.render_template
    end

    before do
      Chef::Config[:trusted_certs_dir] = trusted_certs_dir
      IO.stub(:read).and_call_original
      IO.stub(:read).with(File.expand_path(Chef::Config[:validation_key])).and_return("")
    end

    def certificates
      Dir[File.join(trusted_certs_dir, "*.{crt,pem}")]
    end

    it "creates /etc/chef/trusted_certs" do
      rendered_template.should match(%r{mkdir -p /etc/chef/trusted_certs})
    end

    it "copies the certificates in the directory" do
      certificates.each do |cert|
        IO.should_receive(:read).with(File.expand_path(cert))
      end

      certificates.each do |cert|
        rendered_template.should match(%r{cat > /etc/chef/trusted_certs/#{File.basename(cert)} <<'EOP'})
      end
    end

    it "doesn't create /etc/chef/trusted_certs if :trusted_certs_dir is empty" do
      Dir.should_receive(:glob).with(File.join(trusted_certs_dir, "*.{crt,pem}")).and_return([])
      rendered_template.should_not match(%r{mkdir -p /etc/chef/trusted_certs})
    end
  end

  describe "when configuring the underlying knife ssh command" do
    context "from the command line" do
      let(:knife_ssh) do
        knife.name_args = ["foo.example.com"]
        knife.config[:ssh_user]      = "rooty"
        knife.config[:ssh_port]      = "4001"
        knife.config[:ssh_password]  = "open_sesame"
        Chef::Config[:knife][:ssh_user] = nil
        Chef::Config[:knife][:ssh_port] = nil
        knife.config[:forward_agent] = true
        knife.config[:identity_file] = "~/.ssh/me.rsa"
        knife.stub(:render_template).and_return("")
        knife.knife_ssh
      end

      it "configures the hostname" do
        knife_ssh.name_args.first.should == "foo.example.com"
      end

      it "configures the ssh user" do
        knife_ssh.config[:ssh_user].should == 'rooty'
      end

      it "configures the ssh password" do
        knife_ssh.config[:ssh_password].should == 'open_sesame'
      end

      it "configures the ssh port" do
        knife_ssh.config[:ssh_port].should == '4001'
      end

      it "configures the ssh agent forwarding" do
        knife_ssh.config[:forward_agent].should == true
      end

      it "configures the ssh identity file" do
        knife_ssh.config[:identity_file].should == '~/.ssh/me.rsa'
      end
    end

    context "validating use_sudo_password" do
      before do
        knife.config[:ssh_password] = "password"
        knife.stub(:render_template).and_return("")
      end

      it "use_sudo_password contains description and long params for help" do
        knife.options.should have_key(:use_sudo_password) \
          and knife.options[:use_sudo_password][:description].to_s.should_not == ''\
          and knife.options[:use_sudo_password][:long].to_s.should_not == ''
      end

      it "uses the password from --ssh-password for sudo when --use-sudo-password is set" do
        knife.config[:use_sudo] = true
        knife.config[:use_sudo_password] = true
        knife.ssh_command.should include("echo \'#{knife.config[:ssh_password]}\' | sudo -S")
      end

      it "should not honor --use-sudo-password when --use-sudo is not set" do
        knife.config[:use_sudo] = false
        knife.config[:use_sudo_password] = true
        knife.ssh_command.should_not include("echo #{knife.config[:ssh_password]} | sudo -S")
      end
    end

    context "from the knife config file" do
      let(:knife_ssh) do
        knife.name_args = ["config.example.com"]
        knife.config[:ssh_user] = nil
        knife.config[:ssh_port] = nil
        knife.config[:ssh_gateway] = nil
        knife.config[:forward_agent] = nil
        knife.config[:identity_file] = nil
        knife.config[:host_key_verify] = nil
        Chef::Config[:knife][:ssh_user] = "curiosity"
        Chef::Config[:knife][:ssh_port] = "2430"
        Chef::Config[:knife][:forward_agent] = true
        Chef::Config[:knife][:identity_file] = "~/.ssh/you.rsa"
        Chef::Config[:knife][:ssh_gateway] = "towel.blinkenlights.nl"
        Chef::Config[:knife][:host_key_verify] = true
        knife.stub(:render_template).and_return("")
        knife.knife_ssh
      end

      it "configures the ssh user" do
        knife_ssh.config[:ssh_user].should == 'curiosity'
      end

      it "configures the ssh port" do
        knife_ssh.config[:ssh_port].should == '2430'
      end

      it "configures the ssh agent forwarding" do
        knife_ssh.config[:forward_agent].should == true
      end

      it "configures the ssh identity file" do
        knife_ssh.config[:identity_file].should == '~/.ssh/you.rsa'
      end

      it "configures the ssh gateway" do
        knife_ssh.config[:ssh_gateway].should == 'towel.blinkenlights.nl'
      end

      it "configures the host key verify mode" do
        knife_ssh.config[:host_key_verify].should == true
      end
    end

    describe "when falling back to password auth when host key auth fails" do
      let(:knife_ssh_with_password_auth) do
        knife.name_args = ["foo.example.com"]
        knife.config[:ssh_user]      = "rooty"
        knife.config[:identity_file] = "~/.ssh/me.rsa"
        knife.stub(:render_template).and_return("")
        k = knife.knife_ssh
        k.stub(:get_password).and_return('typed_in_password')
        knife.stub(:knife_ssh).and_return(k)
        knife.knife_ssh_with_password_auth
      end

      it "prompts the user for a password " do
        knife_ssh_with_password_auth.config[:ssh_password].should == 'typed_in_password'
      end

      it "configures knife not to use the identity file that didn't work previously" do
        knife_ssh_with_password_auth.config[:identity_file].should be_nil
      end
    end
  end

  it "verifies that a server to bootstrap was given as a command line arg" do
    knife.name_args = nil
    lambda { knife.run }.should raise_error(SystemExit)
    stderr.string.should match /ERROR:.+FQDN or ip/
  end

  describe "when running the bootstrap" do
    let(:knife_ssh) do
      knife.name_args = ["foo.example.com"]
      knife.config[:ssh_user]      = "rooty"
      knife.config[:identity_file] = "~/.ssh/me.rsa"
      knife.stub(:render_template).and_return("")
      knife_ssh = knife.knife_ssh
      knife.stub(:knife_ssh).and_return(knife_ssh)
      knife_ssh
    end

    it "configures the underlying ssh command and then runs it" do
      knife_ssh.should_receive(:run)
      knife.run
    end

    it "falls back to password based auth when auth fails the first time" do
      knife.stub(:puts)

      fallback_knife_ssh = knife_ssh.dup
      knife_ssh.should_receive(:run).and_raise(Net::SSH::AuthenticationFailed.new("no ssh for you"))
      knife.stub(:knife_ssh_with_password_auth).and_return(fallback_knife_ssh)
      fallback_knife_ssh.should_receive(:run)
      knife.run
    end

    it "raises the exception if config[:ssh_password] is set and an authentication exception is raised" do
      knife.config[:ssh_password] = "password"
      knife_ssh.should_receive(:run).and_raise(Net::SSH::AuthenticationFailed)
      lambda { knife.run }.should raise_error(Net::SSH::AuthenticationFailed)
    end
  end

  describe "specifying ssl verification" do

  end

end
