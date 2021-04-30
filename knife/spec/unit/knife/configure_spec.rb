require "knife_spec_helper"

describe Chef::Knife::Configure do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name] = "webmonkey.example.com"
    @knife = Chef::Knife::Configure.new
    @rest_client = double("null rest client", post: { result: :true })
    allow(@knife).to receive(:rest).and_return(@rest_client)

    @out = StringIO.new
    allow(@knife.ui).to receive(:stdout).and_return(@out)
    @knife.config[:config_file] = "/home/you/.chef/knife.rb"

    @in = StringIO.new("\n" * 7)
    allow(@knife.ui).to receive(:stdin).and_return(@in)

    @err = StringIO.new
    allow(@knife.ui).to receive(:stderr).and_return(@err)

    allow(Ohai::System).to receive(:new).and_return(ohai)
  end

  let(:fqdn) { "foo.example.org" }

  let(:ohai) do
    o = {}
    allow(o).to receive(:all_plugins).with(%w{ os hostname fqdn })
    o[:fqdn] = fqdn
    o
  end

  let(:default_admin_key) { "/etc/chef-server/admin.pem" }
  let(:default_admin_key_win32) { File.expand_path(default_admin_key) }

  let(:default_validator_key) { "/etc/chef-server/chef-validator.pem" }
  let(:default_validator_key_win32) { File.expand_path(default_validator_key) }

  let(:default_server_url) { "https://#{fqdn}/organizations/myorg" }

  it "asks the user for the URL of the chef server" do
    @knife.ask_user_for_config
    expect(@out.string).to match(Regexp.escape("Please enter the chef server URL: [#{default_server_url}]"))
    expect(@knife.chef_server).to eq(default_server_url)
  end

  it "asks the user for the clientname they want for the new client if -i is specified" do
    @knife.config[:initial] = true
    allow(Etc).to receive(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    expect(@out.string).to match(Regexp.escape("Please enter a name for the new user: [a-new-user]"))
    expect(@knife.new_client_name).to eq(Etc.getlogin)
  end

  it "should not ask the user for the clientname they want for the new client if -i and --node_name are specified" do
    @knife.config[:initial] = true
    @knife.config[:node_name] = "testnode"
    allow(Etc).to receive(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    expect(@out.string).not_to match(Regexp.escape("Please enter a name for the new user"))
    expect(@knife.new_client_name).to eq("testnode")
  end

  it "asks the user for the existing API username or clientname if -i is not specified" do
    allow(Etc).to receive(:getlogin).and_return("a-new-user")
    @knife.ask_user_for_config
    expect(@out.string).to match(Regexp.escape("Please enter an existing username or clientname for the API: [a-new-user]"))
    expect(@knife.new_client_name).to eq(Etc.getlogin)
  end

  it "asks the user for the existing admin client's name if -i is specified" do
    @knife.config[:initial] = true
    @knife.ask_user_for_config
    expect(@out.string).to match(Regexp.escape("Please enter the existing admin name: [admin]"))
    expect(@knife.admin_client_name).to eq("admin")
  end

  it "should not ask the user for the existing admin client's name if -i and --admin-client_name are specified" do
    @knife.config[:initial] = true
    @knife.config[:admin_client_name] = "my-webui"
    @knife.ask_user_for_config
    expect(@out.string).not_to match(Regexp.escape("Please enter the existing admin:"))
    expect(@knife.admin_client_name).to eq("my-webui")
  end

  it "should not ask the user for the existing admin client's name if -i is not specified" do
    @knife.ask_user_for_config
    expect(@out.string).not_to match(Regexp.escape("Please enter the existing admin: [admin]"))
    expect(@knife.admin_client_name).not_to eq("admin")
  end

  it "asks the user for the location of the existing admin key if -i is specified" do
    @knife.config[:initial] = true
    @knife.ask_user_for_config
    expect(@out.string).to match(Regexp.escape("Please enter the location of the existing admin's private key: [#{default_admin_key}]"))
    if windows?
      expect(@knife.admin_client_key.capitalize).to eq(default_admin_key_win32.capitalize)
    else
      expect(@knife.admin_client_key).to eq(default_admin_key)
    end
  end

  it "should not ask the user for the location of the existing admin key if -i and --admin_client_key are specified" do
    @knife.config[:initial] = true
    @knife.config[:admin_client_key] = "/home/you/.chef/my-webui.pem"
    @knife.ask_user_for_config
    expect(@out.string).not_to match(Regexp.escape("Please enter the location of the existing admin client's private key:"))
    if windows?
      expect(@knife.admin_client_key).to match %r{^[A-Za-z]:/home/you/\.chef/my-webui\.pem$}
    else
      expect(@knife.admin_client_key).to eq("/home/you/.chef/my-webui.pem")
    end
  end

  it "should not ask the user for the location of the existing admin key if -i is not specified" do
    @knife.ask_user_for_config
    expect(@out.string).not_to match(Regexp.escape("Please enter the location of the existing admin client's private key: [#{default_admin_key}]"))
    if windows?
      expect(@knife.admin_client_key).not_to eq(default_admin_key_win32)
    else
      expect(@knife.admin_client_key).not_to eq(default_admin_key)
    end
  end

  it "should not ask the user for anything if -i and all other properties are specified" do
    @knife.config[:initial] = true
    @knife.config[:chef_server_url] = "http://localhost:5000"
    @knife.config[:node_name] = "testnode"
    @knife.config[:admin_client_name] = "my-webui"
    @knife.config[:admin_client_key] = "/home/you/.chef/my-webui.pem"
    @knife.config[:client_key] = "/home/you/a-new-user.pem"
    allow(Etc).to receive(:getlogin).and_return("a-new-user")

    @knife.ask_user_for_config
    expect(@out.string).to match(/\s*/)

    expect(@knife.new_client_name).to eq("testnode")
    expect(@knife.chef_server).to eq("http://localhost:5000")
    expect(@knife.admin_client_name).to eq("my-webui")
    if windows?
      expect(@knife.admin_client_key).to match %r{^[A-Za-z]:/home/you/\.chef/my-webui\.pem$}
      expect(@knife.new_client_key).to match %r{^[A-Za-z]:/home/you/a-new-user\.pem$}
    else
      expect(@knife.admin_client_key).to eq("/home/you/.chef/my-webui.pem")
      expect(@knife.new_client_key).to eq("/home/you/a-new-user.pem")
    end
  end

  it "writes the new data to a config file" do
    allow(Chef::Util::PathHelper).to receive(:home).with(".chef").and_return("/home/you/.chef")
    allow(File).to receive(:expand_path).with("/home/you/.chef/credentials").and_return("/home/you/.chef/credentials")
    allow(File).to receive(:expand_path).with("/home/you/.chef/#{Etc.getlogin}.pem").and_return("/home/you/.chef/#{Etc.getlogin}.pem")
    allow(File).to receive(:expand_path).with(default_admin_key).and_return(default_admin_key)
    expect(FileUtils).to receive(:mkdir_p).with("/home/you/.chef")
    config_file = StringIO.new
    expect(::File).to receive(:open).with("/home/you/.chef/credentials", "w").and_yield config_file
    @knife.config[:repository] = "/home/you/chef-repo"
    @knife.run
    expect(config_file.string).to match(/^client_name\s+=\s+'#{Etc.getlogin}'$/)
    expect(config_file.string).to match(%r{^client_key\s+=\s+'/home/you/.chef/#{Etc.getlogin}.pem'$})
    expect(config_file.string).to match(/^chef_server_url\s+=\s+'#{default_server_url}'$/)
  end

  it "creates a new client when given the --initial option" do
    allow(Chef::Util::PathHelper).to receive(:home).with(".chef").and_return("/home/you/.chef")
    expect(File).to receive(:expand_path).with("/home/you/.chef/credentials").and_return("/home/you/.chef/credentials")
    expect(File).to receive(:expand_path).with("/home/you/.chef/a-new-user.pem").and_return("/home/you/.chef/a-new-user.pem")
    allow(File).to receive(:expand_path).with(default_admin_key).and_return(default_admin_key)
    Chef::Config[:node_name] = "webmonkey.example.com"

    user_command = Chef::Knife::UserCreate.new
    expect(user_command).to receive(:run)

    allow(Etc).to receive(:getlogin).and_return("a-new-user")

    allow(Chef::Knife::UserCreate).to receive(:new).and_return(user_command)
    expect(FileUtils).to receive(:mkdir_p).with("/home/you/.chef")
    expect(::File).to receive(:open).with("/home/you/.chef/credentials", "w")
    @knife.config[:initial] = true
    @knife.config[:user_password] = "blah"
    @knife.run
    expect(user_command.name_args).to eq(Array("a-new-user"))
    expect(user_command.config[:user_password]).to eq("blah")
    expect(user_command.config[:admin]).to be_truthy
    expect(user_command.config[:file]).to eq("/home/you/.chef/a-new-user.pem")
    expect(user_command.config[:yes]).to be_truthy
    expect(user_command.config[:disable_editing]).to be_truthy
  end
end
