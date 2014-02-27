require 'spec_helper'

describe Chef::Knife::Configure do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    @knife = Chef::Knife::Configure.new
    @rest_client = double("null rest client", :post_rest => { :result => :true })
    @knife.stub(:rest).and_return(@rest_client)

    @out = StringIO.new
    @knife.ui.stub(:stdout).and_return(@out)
    @knife.config[:config_file] = '/home/you/.chef/knife.rb'

    @in = StringIO.new("\n" * 7)
    @knife.ui.stub(:stdin).and_return(@in)

    @err = StringIO.new
    @knife.ui.stub(:stderr).and_return(@err)

    Ohai::System.stub(:new).and_return(ohai)
  end


  let(:fqdn) { "foo.example.org" }

  let(:ohai) do
    o = {}
    o.stub(:require_plugin)
    o[:fqdn] = fqdn
    o
  end

  let(:default_admin_key) { "/etc/chef-server/admin.pem" }
  let(:default_admin_key_win32) { File.expand_path(default_admin_key) }

  let(:default_validator_key) { "/etc/chef-server/chef-validator.pem" }
  let(:default_validator_key_win32) { File.expand_path(default_validator_key) }

  let(:default_server_url) { "https://#{fqdn}:443" }


  it "asks the user for the URL of the chef server" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the chef server URL: [#{default_server_url}]"))
    @knife.chef_server.should == default_server_url
  end

  it "asks the user for the clientname they want for the new client if -i is specified" do
    @knife.config[:initial] = true
    Etc.stub(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter a name for the new user: [a-new-user]"))
    @knife.new_client_name.should == Etc.getlogin
  end

  it "should not ask the user for the clientname they want for the new client if -i and --node_name are specified" do
    @knife.config[:initial] = true
    @knife.config[:node_name] = 'testnode'
    Etc.stub(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter a name for the new user"))
    @knife.new_client_name.should == 'testnode'
  end

  it "asks the user for the existing API username or clientname if -i is not specified" do
    Etc.stub(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter an existing username or clientname for the API: [a-new-user]"))
    @knife.new_client_name.should == Etc.getlogin
  end

  it "asks the user for the existing admin client's name if -i is specified" do
    @knife.config[:initial] = true
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the existing admin name: [admin]"))
    @knife.admin_client_name.should == 'admin'
  end

  it "should not ask the user for the existing admin client's name if -i and --admin-client_name are specified" do
    @knife.config[:initial] = true
    @knife.config[:admin_client_name] = 'my-webui'
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the existing admin:"))
    @knife.admin_client_name.should == 'my-webui'
  end

  it "should not ask the user for the existing admin client's name if -i is not specified" do
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the existing admin: [admin]"))
    @knife.admin_client_name.should_not == 'admin'
  end

  it "asks the user for the location of the existing admin key if -i is specified" do
    @knife.config[:initial] = true
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the location of the existing admin's private key: [#{default_admin_key}]"))
    if windows?
      @knife.admin_client_key.capitalize.should == default_admin_key_win32.capitalize
    else
      @knife.admin_client_key.should == default_admin_key
    end
  end

  it "should not ask the user for the location of the existing admin key if -i and --admin_client_key are specified" do
    @knife.config[:initial] = true
    @knife.config[:admin_client_key] = '/home/you/.chef/my-webui.pem'
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the location of the existing admin client's private key:"))
    if windows?
      @knife.admin_client_key.should match %r{^[A-Za-z]:/home/you/\.chef/my-webui\.pem$}
    else
      @knife.admin_client_key.should == '/home/you/.chef/my-webui.pem'
    end
  end

  it "should not ask the user for the location of the existing admin key if -i is not specified" do
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the location of the existing admin client's private key: [#{default_admin_key}]"))
    if windows?
      @knife.admin_client_key.should_not == default_admin_key_win32
    else
      @knife.admin_client_key.should_not == default_admin_key
    end
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

  it "should not ask the users for the name of the validation client if --validation_client_name is specified" do
    @knife.config[:validation_client_name] = 'my-validator'
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the validation clientname:"))
    @knife.validation_client_name.should == 'my-validator'
  end

  it "asks the users for the location of the validation key" do
    @knife.ask_user_for_config
    @out.string.should match(Regexp.escape("Please enter the location of the validation key: [#{default_validator_key}]"))
    if windows?
      @knife.validation_key.capitalize.should == default_validator_key_win32.capitalize
    else
      @knife.validation_key.should == default_validator_key
    end
  end

  it "should not ask the users for the location of the validation key if --validation_key is specified" do
    @knife.config[:validation_key] = '/home/you/.chef/my-validation.pem'
    @knife.ask_user_for_config
    @out.string.should_not match(Regexp.escape("Please enter the location of the validation key:"))
    if windows?
      @knife.validation_key.should match %r{^[A-Za-z]:/home/you/\.chef/my-validation\.pem$}
    else
      @knife.validation_key.should == '/home/you/.chef/my-validation.pem'
    end
  end

  it "should not ask the user for anything if -i and all other properties are specified" do
    @knife.config[:initial] = true
    @knife.config[:chef_server_url] = 'http://localhost:5000'
    @knife.config[:node_name] = 'testnode'
    @knife.config[:admin_client_name] = 'my-webui'
    @knife.config[:admin_client_key] = '/home/you/.chef/my-webui.pem'
    @knife.config[:validation_client_name] = 'my-validator'
    @knife.config[:validation_key] = '/home/you/.chef/my-validation.pem'
    @knife.config[:repository] = ''
    @knife.config[:client_key] = '/home/you/a-new-user.pem'
    Etc.stub(:getlogin).and_return('a-new-user')

    @knife.ask_user_for_config
    @out.string.should match(/\s*/)

    @knife.new_client_name.should == 'testnode'
    @knife.chef_server.should == 'http://localhost:5000'
    @knife.admin_client_name.should == 'my-webui'
    if windows?
      @knife.admin_client_key.should match %r{^[A-Za-z]:/home/you/\.chef/my-webui\.pem$}
      @knife.validation_key.should match %r{^[A-Za-z]:/home/you/\.chef/my-validation\.pem$}
      @knife.new_client_key.should match %r{^[A-Za-z]:/home/you/a-new-user\.pem$}
    else
      @knife.admin_client_key.should == '/home/you/.chef/my-webui.pem'
      @knife.validation_key.should == '/home/you/.chef/my-validation.pem'
      @knife.new_client_key.should == '/home/you/a-new-user.pem'
    end
    @knife.validation_client_name.should == 'my-validator'
    @knife.chef_repo.should == ''
  end

  it "writes the new data to a config file" do
    File.stub(:expand_path).with("/home/you/.chef/knife.rb").and_return("/home/you/.chef/knife.rb")
    File.stub(:expand_path).with("/home/you/.chef/#{Etc.getlogin}.pem").and_return("/home/you/.chef/#{Etc.getlogin}.pem")
    File.stub(:expand_path).with(default_validator_key).and_return(default_validator_key)
    File.stub(:expand_path).with(default_admin_key).and_return(default_admin_key)
    FileUtils.should_receive(:mkdir_p).with("/home/you/.chef")
    config_file = StringIO.new
    ::File.should_receive(:open).with("/home/you/.chef/knife.rb", "w").and_yield config_file
    @knife.config[:repository] = '/home/you/chef-repo'
    @knife.run
    config_file.string.should match(/^node_name[\s]+'#{Etc.getlogin}'$/)
    config_file.string.should match(%r{^client_key[\s]+'/home/you/.chef/#{Etc.getlogin}.pem'$})
    config_file.string.should match(/^validation_client_name\s+'chef-validator'$/)
    config_file.string.should match(%r{^validation_key\s+'#{default_validator_key}'$})
    config_file.string.should match(%r{^chef_server_url\s+'#{default_server_url}'$})
    config_file.string.should match(%r{cookbook_path\s+\[ '/home/you/chef-repo/cookbooks' \]})
  end

  it "creates a new client when given the --initial option" do
    File.should_receive(:expand_path).with("/home/you/.chef/knife.rb").and_return("/home/you/.chef/knife.rb")
    File.should_receive(:expand_path).with("/home/you/.chef/a-new-user.pem").and_return("/home/you/.chef/a-new-user.pem")
    File.should_receive(:expand_path).with(default_validator_key).and_return(default_validator_key)
    File.should_receive(:expand_path).with(default_admin_key).and_return(default_admin_key)
    Chef::Config[:node_name]  = "webmonkey.example.com"

    user_command = Chef::Knife::UserCreate.new
    user_command.should_receive(:run)

    Etc.stub(:getlogin).and_return("a-new-user")

    Chef::Knife::UserCreate.stub(:new).and_return(user_command)
    FileUtils.should_receive(:mkdir_p).with("/home/you/.chef")
    ::File.should_receive(:open).with("/home/you/.chef/knife.rb", "w")
    @knife.config[:initial] = true
    @knife.config[:user_password] = "blah"
    @knife.run
    user_command.name_args.should == Array("a-new-user")
    user_command.config[:user_password].should == "blah"
    user_command.config[:admin].should be_true
    user_command.config[:file].should == "/home/you/.chef/a-new-user.pem"
    user_command.config[:yes].should be_true
    user_command.config[:disable_editing].should be_true
  end
end
