#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008, 2011 Opscode, Inc.
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

# Fixtures for subcommand loading live in this namespace
module KnifeSpecs
end

require 'spec_helper'
require 'uri'

describe Chef::Knife do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"

    # Prevent gratuitous code reloading:
    Chef::Knife.stub(:load_commands)
    @knife = Chef::Knife.new
    @knife.ui.stub(:puts)
    @knife.ui.stub(:print)
    Chef::Log.stub(:init)
    Chef::Log.stub(:level)
    [:debug, :info, :warn, :error, :crit].each do |level_sym|
      Chef::Log.stub(level_sym)
    end
    Chef::Knife.stub(:puts)
    @stderr = StringIO.new
  end

  describe "selecting a config file" do
    context "when the current working dir is inside a symlinked directory" do
      before do
        Chef::Knife.reset_config_path!
        # pwd according to your shell is /home/someuser/prod/chef-repo, but
        # chef-repo is a symlink to /home/someuser/codes/chef-repo
        if Chef::Platform.windows?
          ENV.should_receive(:[]).with("CD").and_return("/home/someuser/prod/chef-repo")
        else
          ENV.should_receive(:[]).with("PWD").and_return("/home/someuser/prod/chef-repo")
        end

        Dir.stub(:pwd).and_return("/home/someuser/codes/chef-repo")
      end

      after do
        Chef::Knife.reset_config_path!
      end

      it "loads the config from the non-dereferenced directory path" do
        File.should_receive(:exist?).with("/home/someuser/prod/chef-repo/.chef").and_return(false)
        File.should_receive(:exist?).with("/home/someuser/prod/.chef").and_return(true)
        File.should_receive(:directory?).with("/home/someuser/prod/.chef").and_return(true)
        Chef::Knife.chef_config_dir.should == "/home/someuser/prod/.chef"
      end
    end
  end

  describe "after loading a subcommand" do
    before do
      Chef::Knife.reset_subcommands!

      if KnifeSpecs.const_defined?(:TestNameMapping)
        KnifeSpecs.send(:remove_const, :TestNameMapping)
      end

      if KnifeSpecs.const_defined?(:TestExplicitCategory)
        KnifeSpecs.send(:remove_const, :TestExplicitCategory)
      end

      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_name_mapping.rb'))
      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_explicit_category.rb'))
    end

    it "has a category based on its name" do
      KnifeSpecs::TestNameMapping.subcommand_category.should == 'test'
    end

    it "has an explictly defined category if set" do
      KnifeSpecs::TestExplicitCategory.subcommand_category.should == 'cookbook site'
    end

    it "can reference the subcommand by its snake cased name" do
      Chef::Knife.subcommands['test_name_mapping'].should equal(KnifeSpecs::TestNameMapping)
    end

    it "lists subcommands by category" do
      Chef::Knife.subcommands_by_category['test'].should include('test_name_mapping')
    end

    it "lists subcommands by category when the subcommands have explicit categories" do
      Chef::Knife.subcommands_by_category['cookbook site'].should include('test_explicit_category')
    end

    it "has empty dependency_loader list by default" do
      KnifeSpecs::TestNameMapping.dependency_loaders.should be_empty
    end
  end

  describe "after loading all subcommands" do
    before do
      Chef::Knife.reset_subcommands!
      Chef::Knife.load_commands
    end

    it "references a subcommand class by its snake cased name" do
      class SuperAwesomeCommand < Chef::Knife
      end

      Chef::Knife.load_commands

      Chef::Knife.subcommands.should have_key("super_awesome_command")
      Chef::Knife.subcommands["super_awesome_command"].should == SuperAwesomeCommand
    end

    it "guesses a category from a given ARGV" do
      Chef::Knife.subcommands_by_category["cookbook"] << :cookbook
      Chef::Knife.subcommands_by_category["cookbook site"] << :cookbook_site
      Chef::Knife.guess_category(%w{cookbook foo bar baz}).should == 'cookbook'
      Chef::Knife.guess_category(%w{cookbook site foo bar baz}).should == 'cookbook site'
      Chef::Knife.guess_category(%w{cookbook site --help}).should == 'cookbook site'
    end

    it "finds a subcommand class based on ARGV" do
      Chef::Knife.subcommands["cookbook_site_vendor"] = :CookbookSiteVendor
      Chef::Knife.subcommands["cookbook"] = :Cookbook
      Chef::Knife.subcommand_class_from(%w{cookbook site vendor --help foo bar baz}).should == :CookbookSiteVendor
    end

  end

  describe "the headers include X-Remote-Request-Id" do

    let(:headers) {{"Accept"=>"application/json",
                    "Accept-Encoding"=>"gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                    'X-Chef-Version' => Chef::VERSION,
                    "Host"=>"api.opscode.piab",
                    "X-REMOTE-REQUEST-ID"=>request_id}}

    let(:request_id) {"1234"}

    let(:request_mock) { {} }

    let(:rest) do
      Net::HTTP.stub(:new).and_return(http_client)
      Chef::RequestID.instance.stub(:request_id).and_return(request_id)
      Chef::Config.stub(:chef_server_url).and_return("https://api.opscode.piab")
      command = Chef::Knife.run(%w{test yourself})
      rest = command.noauth_rest
      rest
    end

    let!(:http_client) do
      http_client = Net::HTTP.new(url.host, url.port)
      http_client.stub(:request).and_yield(http_response).and_return(http_response)
      http_client
    end

    let(:url) { URI.parse("https://api.opscode.piab") }

    let(:http_response) do
      http_response = Net::HTTPSuccess.new("1.1", "200", "successful rest req")
      http_response.stub(:read_body)
      http_response.stub(:body).and_return(body)
      http_response["Content-Length"] = body.bytesize.to_s
      http_response
    end

    let(:body) { "ninja" }

    before(:each) do
      Chef::Config[:chef_server_url] = "https://api.opscode.piab"
      if KnifeSpecs.const_defined?(:TestYourself)
        KnifeSpecs.send :remove_const, :TestYourself
      end
      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_yourself.rb'))
      Chef::Knife.subcommands.each { |name, klass| Chef::Knife.subcommands.delete(name) unless klass.kind_of?(Class) }
    end

    it "confirms that the headers include X-Remote-Request-Id" do
      Net::HTTP::Get.should_receive(:new).with("/monkey", headers).and_return(request_mock)
      rest.get_rest("monkey")
    end
  end

  describe "when running a command" do
    before(:each) do
      if KnifeSpecs.const_defined?(:TestYourself)
        KnifeSpecs.send :remove_const, :TestYourself
      end
      Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_yourself.rb'))
      Chef::Knife.subcommands.each { |name, klass| Chef::Knife.subcommands.delete(name) unless klass.kind_of?(Class) }
    end

    it "merges the global knife CLI options" do
      extra_opts = {}
      extra_opts[:editor] = {:long=>"--editor EDITOR",
                             :description=>"Set the editor to use for interactive commands",
                             :short=>"-e EDITOR",
                             :default=>"/usr/bin/vim"}

      # there is special hackery to return the subcommand instance going on here.
      command = Chef::Knife.run(%w{test yourself}, extra_opts)
      editor_opts = command.options[:editor]
      editor_opts[:long].should         == "--editor EDITOR"
      editor_opts[:description].should  == "Set the editor to use for interactive commands"
      editor_opts[:short].should        == "-e EDITOR"
      editor_opts[:default].should      == "/usr/bin/vim"
    end

    it "creates an instance of the subcommand and runs it" do
      command = Chef::Knife.run(%w{test yourself})
      command.should be_an_instance_of(KnifeSpecs::TestYourself)
      command.ran.should be_true
    end

    it "passes the command specific args to the subcommand" do
      command = Chef::Knife.run(%w{test yourself with some args})
      command.name_args.should == %w{with some args}
    end

    it "excludes the command name from the name args when parts are joined with underscores" do
      command = Chef::Knife.run(%w{test_yourself with some args})
      command.name_args.should == %w{with some args}
    end

    it "exits if no subcommand matches the CLI args" do
      Chef::Knife.ui.stub(:stderr).and_return(@stderr)
      Chef::Knife.ui.should_receive(:fatal)
      lambda {Chef::Knife.run(%w{fuuu uuuu fuuuu})}.should raise_error(SystemExit) { |e| e.status.should_not == 0 }
    end

    it "loads lazy dependencies" do
      command = Chef::Knife.run(%w{test yourself})
      KnifeSpecs::TestYourself.test_deps_loaded.should be_true
    end

    it "loads lazy dependencies from multiple deps calls" do
      other_deps_loaded = false
      KnifeSpecs::TestYourself.class_eval do
        deps { other_deps_loaded = true }
      end
      command = Chef::Knife.run(%w{test yourself})
      KnifeSpecs::TestYourself.test_deps_loaded.should be_true
      other_deps_loaded.should be_true
    end

    describe "merging configuration options" do
      before do
        KnifeSpecs::TestYourself.option(:opt_with_default,
                                        :short => "-D VALUE",
                                        :default => "default-value")
      end

      it "prefers the default value if no config or command line value is present" do
        knife_command = KnifeSpecs::TestYourself.new([]) #empty argv
        knife_command.configure_chef
        knife_command.config[:opt_with_default].should == "default-value"
      end

      it "prefers a value in Chef::Config[:knife] to the default" do
        Chef::Config[:knife][:opt_with_default] = "from-knife-config"
        knife_command = KnifeSpecs::TestYourself.new([]) #empty argv
        knife_command.configure_chef
        knife_command.config[:opt_with_default].should == "from-knife-config"
      end

      it "prefers a value from command line over Chef::Config and the default" do
        Chef::Config[:knife][:opt_with_default] = "from-knife-config"
        knife_command = KnifeSpecs::TestYourself.new(["-D", "from-cli"])
        knife_command.configure_chef
        knife_command.config[:opt_with_default].should == "from-cli"
      end
    end

  end

  describe "when first created" do
    before do
      unless KnifeSpecs.const_defined?(:TestYourself)
        Kernel.load(File.join(CHEF_SPEC_DATA, 'knife_subcommand', 'test_yourself.rb'))
      end
      @knife = KnifeSpecs::TestYourself.new(%w{with some args -s scrogramming})
    end

    it "it parses the options passed to it" do
      @knife.config[:scro].should == 'scrogramming'
    end

    it "extracts its command specific args from the full arg list" do
      @knife.name_args.should == %w{with some args}
    end

    it "does not have lazy dependencies loaded" do
      @knife.class.test_deps_loaded.should_not be_true
    end
  end

  describe "when formatting exceptions" do
    before do
      @stdout, @stderr, @stdin = StringIO.new, StringIO.new, StringIO.new
      @knife.ui = Chef::Knife::UI.new(@stdout, @stderr, @stdin, {})
      @knife.should_receive(:exit).with(100)
    end

    it "formats 401s nicely" do
      response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "y u no syncronize your clock?"))
      @knife.stub(:run).and_raise(Net::HTTPServerException.new("401 Unauthorized", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(/ERROR: Failed to authenticate to/)
      @stderr.string.should match(/Response:  y u no syncronize your clock\?/)
    end

    it "formats 403s nicely" do
      response = Net::HTTPForbidden.new("1.1", "403", "Forbidden")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "y u no administrator"))
      @knife.stub(:run).and_raise(Net::HTTPServerException.new("403 Forbidden", response))
      @knife.stub(:username).and_return("sadpanda")
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: You authenticated successfully to http.+ as sadpanda but you are not authorized for this action])
      @stderr.string.should match(%r[Response:  y u no administrator])
    end

    it "formats 400s nicely" do
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "y u search wrong"))
      @knife.stub(:run).and_raise(Net::HTTPServerException.new("400 Bad Request", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: The data in your request was invalid])
      @stderr.string.should match(%r[Response: y u search wrong])
    end

    it "formats 404s nicely" do
      response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "nothing to see here"))
      @knife.stub(:run).and_raise(Net::HTTPServerException.new("404 Not Found", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: The object you are looking for could not be found])
      @stderr.string.should match(%r[Response: nothing to see here])
    end

    it "formats 500s nicely" do
      response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "sad trombone"))
      @knife.stub(:run).and_raise(Net::HTTPFatalError.new("500 Internal Server Error", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: internal server error])
      @stderr.string.should match(%r[Response: sad trombone])
    end

    it "formats 502s nicely" do
      response = Net::HTTPBadGateway.new("1.1", "502", "Bad Gateway")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "sadder trombone"))
      @knife.stub(:run).and_raise(Net::HTTPFatalError.new("502 Bad Gateway", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: bad gateway])
      @stderr.string.should match(%r[Response: sadder trombone])
    end

    it "formats 503s nicely" do
      response = Net::HTTPServiceUnavailable.new("1.1", "503", "Service Unavailable")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "saddest trombone"))
      @knife.stub(:run).and_raise(Net::HTTPFatalError.new("503 Service Unavailable", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: Service temporarily unavailable])
      @stderr.string.should match(%r[Response: saddest trombone])
    end

    it "formats other HTTP errors nicely" do
      response = Net::HTTPPaymentRequired.new("1.1", "402", "Payment Required")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      response.stub(:body).and_return(Chef::JSONCompat.to_json(:error => "nobugfixtillyoubuy"))
      @knife.stub(:run).and_raise(Net::HTTPServerException.new("402 Payment Required", response))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: Payment Required])
      @stderr.string.should match(%r[Response: nobugfixtillyoubuy])
    end

    it "formats NameError and NoMethodError nicely" do
      @knife.stub(:run).and_raise(NameError.new("Undefined constant FUUU"))
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: knife encountered an unexpected error])
      @stderr.string.should match(%r[This may be a bug in the 'knife' knife command or plugin])
      @stderr.string.should match(%r[Exception: NameError: Undefined constant FUUU])
    end

    it "formats missing private key errors nicely" do
      @knife.stub(:run).and_raise(Chef::Exceptions::PrivateKeyMissing.new('key not there'))
      @knife.stub(:api_key).and_return("/home/root/.chef/no-key-here.pem")
      @knife.run_with_pretty_exceptions
      @stderr.string.should match(%r[ERROR: Your private key could not be loaded from /home/root/.chef/no-key-here.pem])
      @stderr.string.should match(%r[Check your configuration file and ensure that your private key is readable])
    end

    it "formats connection refused errors nicely" do
      @knife.stub(:run).and_raise(Errno::ECONNREFUSED.new('y u no shut up'))
      @knife.run_with_pretty_exceptions
      # Errno::ECONNREFUSED message differs by platform
      # *nix = Errno::ECONNREFUSED: Connection refused
      # win32: Errno::ECONNREFUSED: No connection could be made because the target machine actively refused it.
      @stderr.string.should match(%r[ERROR: Network Error: .* - y u no shut up])
      @stderr.string.should match(%r[Check your knife configuration and network settings])
    end
  end

end
