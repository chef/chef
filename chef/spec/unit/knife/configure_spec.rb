require 'spec_helper'

describe Chef::Knife::Configure do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::Configure.new
    @rest_client = mock("null rest client", :post_rest => { :result => :true })
    @knife.stub!(:rest).and_return(@rest_client)

    @out = StringIO.new
    @knife.ui.stub!(:stdout).and_return(@out)
    @knife.config[:config_file] = '/home/you/.chef/knife.rb'

    @in = StringIO.new("\n" * 7)
    @knife.ui.stub!(:stdin).and_return(@in)

    @err = StringIO.new
    @knife.ui.stub!(:stderr).and_return(@err)

    @ohai = Ohai::System.new
    @ohai.stub(:require_plugin)
    @ohai[:fqdn] = "foo.example.org"
    Ohai::System.stub!(:new).and_return(@ohai)
  end

  it "asks the user for the URL of the chef server" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape('Please enter the chef server URL: [http://foo.example.org:4000]'))
    @knife.chef_server.should == 'http://foo.example.org:4000'
  end

  it "asks the user for the clientname they want for the new client if -i is specified" do
    @knife.config[:initial] = true
    Etc.stub!(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter a clientname for the new client: [a-new-user]"))
    @knife.new_client_name.should == Etc.getlogin
  end

  it "asks the user for the existing API username or clientname if -i is not specified" do
    Etc.stub!(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter an existing username or clientname for the API: [a-new-user]"))
    @knife.new_client_name.should == Etc.getlogin
  end

  it "asks the user for the existing admin client's name if -i is specified" do
     @knife.config[:initial] = true
     @knife.ask_user_for_config
     @out.string.should match(Regexp.escape("Please enter the existing admin clientname: [chef-webui]"))
     @knife.admin_client_name.should == 'chef-webui'
   end

   it "should not ask the user for the existing admin client's name if -i is not specified" do
     @knife.ask_user_for_config
     @out.string.should_not match(Regexp.escape("Please enter the existing admin clientname: [chef-webui]"))
     @knife.admin_client_name.should_not == 'chef-webui'
   end

   it "asks the user for the location of the existing admin key if -i is specified" do
     @knife.config[:initial] = true
     @knife.ask_user_for_config
     @out.string.should match(Regexp.escape("Please enter the location of the existing admin client's private key: [/etc/chef/webui.pem]"))
     @knife.admin_client_key.should == '/etc/chef/webui.pem'
   end

   it "should not ask the user for the location of the existing admin key if -i is not specified" do
     @knife.ask_user_for_config
     @out.string.should_not match(Regexp.escape("Please enter the location of the existing admin client's private key: [/etc/chef/webui.pem]"))
     @knife.admin_client_key.should_not == '/etc/chef/webui.pem'
   end

  it "asks the user for the location of a chef repo" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the path to a chef repository (or leave blank):"))
    @knife.chef_repo.should == ''
  end

  it "asks the users for the name of the validation client" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the validation clientname: [chef-validator]"))
    @knife.validation_client_name.should == 'chef-validator'
  end

  it "asks the users for the location of the validation key" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the location of the validation key: [/etc/chef/validation.pem]"))
    @knife.validation_key.should == '/etc/chef/validation.pem'
  end

  it "writes the new data to a config file" do
    File.stub!(:expand_path).with("/home/you/.chef/knife.rb").and_return("/home/you/.chef/knife.rb")
    FileUtils.should_receive(:mkdir_p).with("/home/you/.chef")
    config_file = StringIO.new
    ::File.should_receive(:open).with("/home/you/.chef/knife.rb", "w").and_yield config_file
    @knife.config[:repository] = '/home/you/chef-repo'
    @knife.run
    config_file.string.should match(/^node_name[\s]+'#{Etc.getlogin}'$/)
    config_file.string.should match(%r{^client_key[\s]+'/home/you/.chef/#{Etc.getlogin}.pem'$})
    config_file.string.should match(/^validation_client_name\s+'chef-validator'$/)
    config_file.string.should match(%r{^validation_key\s+'/etc/chef/validation.pem'$})
    config_file.string.should match(%r{^chef_server_url\s+'http://foo.example.org:4000'$})
    config_file.string.should match(%r{cookbook_path\s+\[ '/home/you/chef-repo/cookbooks' \]})
  end

  it "creates a new client when given the --initial option" do
    File.stub!(:expand_path).with("/home/you/.chef/knife.rb").and_return("/home/you/.chef/knife.rb")
    Chef::Config[:node_name]  = "webmonkey.example.com"
    client_command = Chef::Knife::ClientCreate.new
    client_command.should_receive(:run)

    Etc.stub!(:getlogin).and_return("a-new-user")

    Chef::Knife::ClientCreate.stub!(:new).and_return(client_command)
    FileUtils.should_receive(:mkdir_p).with("/home/you/.chef")
    ::File.should_receive(:open).with("/home/you/.chef/knife.rb", "w")
    @knife.config[:initial] = true
    @knife.run
    client_command.name_args.should == Array("a-new-user")
    client_command.config[:admin].should be_true
    client_command.config[:file].should == "/home/you/.chef/a-new-user.pem"
    client_command.config[:yes].should be_true
    client_command.config[:disable_editing].should be_true
  end
end
