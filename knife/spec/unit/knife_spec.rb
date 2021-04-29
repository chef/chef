#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"
require "uri"
require "chef/knife/core/gem_glob_loader"

describe Chef::Knife do

  let(:stderr) { StringIO.new }

  let(:knife) { Chef::Knife.new }

  let(:config_location) { File.expand_path("~/.chef/config.rb") }

  let(:config_loader) do
    instance_double("WorkstationConfigLoader",
      load: nil, no_config_found?: false,
      config_location: config_location,
      chef_config_dir: "/etc/chef")
  end

  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name] = "webmonkey.example.com"

    allow(Chef::WorkstationConfigLoader).to receive(:new).and_return(config_loader)
    allow(config_loader).to receive(:explicit_config_file=)
    allow(config_loader).to receive(:profile=)

    # Prevent gratuitous code reloading:
    allow(Chef::Knife).to receive(:load_commands)
    allow(knife.ui).to receive(:puts)
    allow(knife.ui).to receive(:print)
    allow(Chef::Log).to receive(:init)
    allow(Chef::Log).to receive(:level)
    %i{debug info warn error crit}.each do |level_sym|
      allow(Chef::Log).to receive(level_sym)
    end
    allow(Chef::Knife).to receive(:puts)
  end

  after(:each) do
    Chef::Knife.reset_config_loader!
  end

  it "does not reset Chef::Config[:verbosity to nil if config[:verbosity] is nil" do
    Chef::Config[:verbosity] = 2
    Chef::Knife.new
    expect(Chef::Config[:verbosity]).to eq(2)
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

      Kernel.load(File.join(CHEF_SPEC_DATA, "knife_subcommand", "test_name_mapping.rb"))
      Kernel.load(File.join(CHEF_SPEC_DATA, "knife_subcommand", "test_explicit_category.rb"))
    end

    it "has a category based on its name" do
      expect(KnifeSpecs::TestNameMapping.subcommand_category).to eq("test")
    end

    it "has an explicitly defined category if set" do
      expect(KnifeSpecs::TestExplicitCategory.subcommand_category).to eq("cookbook site")
    end

    it "can reference the subcommand by its snake cased name" do
      expect(Chef::Knife.subcommands["test_name_mapping"]).to equal(KnifeSpecs::TestNameMapping)
    end

    it "lists subcommands by category" do
      expect(Chef::Knife.subcommands_by_category["test"]).to include("test_name_mapping")
    end

    it "lists subcommands by category when the subcommands have explicit categories" do
      expect(Chef::Knife.subcommands_by_category["cookbook site"]).to include("test_explicit_category")
    end

    it "has empty dependency_loader list by default" do
      expect(KnifeSpecs::TestNameMapping.dependency_loaders).to be_empty
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

      expect(Chef::Knife.subcommands).to have_key("super_awesome_command")
      expect(Chef::Knife.subcommands["super_awesome_command"]).to eq(SuperAwesomeCommand)
    end

    it "records the location of ChefFS-based commands correctly" do
      class AwesomeCheffsCommand < Chef::ChefFS::Knife
      end

      Chef::Knife.load_commands
      expect(Chef::Knife.subcommand_files["awesome_cheffs_command"]).to eq([__FILE__])
    end

    it "guesses a category from a given ARGV" do
      Chef::Knife.subcommands_by_category["cookbook"] << :cookbook
      Chef::Knife.subcommands_by_category["cookbook site"] << :cookbook_site
      expect(Chef::Knife.guess_category(%w{cookbook foo bar baz})).to eq("cookbook")
      expect(Chef::Knife.guess_category(%w{cookbook site foo bar baz})).to eq("cookbook site")
      expect(Chef::Knife.guess_category(%w{cookbook site --help})).to eq("cookbook site")
    end

    it "finds a subcommand class based on ARGV" do
      Chef::Knife.subcommands["cookbook_site_install"] = :CookbookSiteInstall
      Chef::Knife.subcommands["cookbook"] = :Cookbook
      expect(Chef::Knife.subcommand_class_from(%w{cookbook site install --help foo bar baz})).to eq(:CookbookSiteInstall)
    end

    it "special case sets the subcommand_loader to GemGlobLoader when running rehash" do
      Chef::Knife.subcommands["rehash"] = :Rehash
      expect(Chef::Knife.subcommand_class_from(%w{rehash })).to eq(:Rehash)
      expect(Chef::Knife.subcommand_loader).to be_a(Chef::Knife::SubcommandLoader::GemGlobLoader)
    end

  end

  describe "the headers include X-Remote-Request-Id" do

    let(:headers) do
      { "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "X-Chef-Version" => Chef::VERSION,
        "Host" => "api.opscode.piab",
        "X-REMOTE-REQUEST-ID" => request_id,
    }
    end

    let(:request_id) { "1234" }

    let(:request_mock) { {} }

    let(:rest) do
      allow(Net::HTTP).to receive(:new).and_return(http_client)
      allow(Chef::RequestID.instance).to receive(:request_id).and_return(request_id)
      allow(Chef::Config).to receive(:chef_server_url).and_return("https://api.opscode.piab")
      command = Chef::Knife.run(%w{test yourself})
      rest = command.noauth_rest
      rest
    end

    let!(:http_client) do
      http_client = Net::HTTP.new(url.host, url.port)
      allow(http_client).to receive(:request).and_yield(http_response).and_return(http_response)
      http_client
    end

    let(:url) { URI.parse("https://api.opscode.piab") }

    let(:http_response) do
      http_response = Net::HTTPSuccess.new("1.1", "200", "successful rest req")
      allow(http_response).to receive(:read_body)
      allow(http_response).to receive(:body).and_return(body)
      http_response["Content-Length"] = body.bytesize.to_s
      http_response
    end

    let(:body) { "ninja" }

    before(:each) do
      Chef::Config[:chef_server_url] = "https://api.opscode.piab"
      if KnifeSpecs.const_defined?(:TestYourself)
        KnifeSpecs.send :remove_const, :TestYourself
      end
      Kernel.load(File.join(CHEF_SPEC_DATA, "knife_subcommand", "test_yourself.rb"))
      Chef::Knife.subcommands.each { |name, klass| Chef::Knife.subcommands.delete(name) unless klass.is_a?(Class) }
    end

    it "confirms that the headers include X-Remote-Request-Id" do
      expect(Net::HTTP::Get).to receive(:new).with("/monkey", headers).and_return(request_mock)
      rest.get("monkey")
    end
  end

  describe "when running a command" do
    before(:each) do
      if KnifeSpecs.const_defined?(:TestYourself)
        KnifeSpecs.send :remove_const, :TestYourself
      end
      Kernel.load(File.join(CHEF_SPEC_DATA, "knife_subcommand", "test_yourself.rb"))
      Chef::Knife.subcommands.each { |name, klass| Chef::Knife.subcommands.delete(name) unless klass.is_a?(Class) }
    end

    it "merges the global knife CLI options" do
      extra_opts = {}
      extra_opts[:editor] = { long: "--editor EDITOR",
                              description: "Set the editor to use for interactive commands",
                              short: "-e EDITOR",
                              default: "/usr/bin/vim" }

      # there is special hackery to return the subcommand instance going on here.
      command = Chef::Knife.run(%w{test yourself}, extra_opts)
      editor_opts = command.options[:editor]
      expect(editor_opts[:long]).to         eq("--editor EDITOR")
      expect(editor_opts[:description]).to  eq("Set the editor to use for interactive commands")
      expect(editor_opts[:short]).to        eq("-e EDITOR")
      expect(editor_opts[:default]).to      eq("/usr/bin/vim")
    end

    it "creates an instance of the subcommand and runs it" do
      command = Chef::Knife.run(%w{test yourself})
      expect(command).to be_an_instance_of(KnifeSpecs::TestYourself)
      expect(command.ran).to be_truthy
    end

    it "passes the command specific args to the subcommand" do
      command = Chef::Knife.run(%w{test yourself with some args})
      expect(command.name_args).to eq(%w{with some args})
    end

    it "excludes the command name from the name args when parts are joined with underscores" do
      command = Chef::Knife.run(%w{test_yourself with some args})
      expect(command.name_args).to eq(%w{with some args})
    end

    it "exits if no subcommand matches the CLI args" do
      stdout = StringIO.new

      allow(Chef::Knife.ui).to receive(:stderr).and_return(stderr)
      allow(Chef::Knife.ui).to receive(:stdout).and_return(stdout)
      expect(Chef::Knife.ui).to receive(:fatal)
      expect { Chef::Knife.run(%w{fuuu uuuu fuuuu}) }.to raise_error(SystemExit) { |e| expect(e.status).not_to eq(0) }
    end

    it "loads lazy dependencies" do
      Chef::Knife.run(%w{test yourself})
      expect(KnifeSpecs::TestYourself.test_deps_loaded).to be_truthy
    end

    it "loads lazy dependencies from multiple deps calls" do
      other_deps_loaded = false
      KnifeSpecs::TestYourself.class_eval do
        deps { other_deps_loaded = true }
      end

      Chef::Knife.run(%w{test yourself})
      expect(KnifeSpecs::TestYourself.test_deps_loaded).to be_truthy
      expect(other_deps_loaded).to be_truthy
    end

    describe "working with unmerged configuration in #config_source" do
      let(:command) { KnifeSpecs::TestYourself.new([]) }

      before do
        KnifeSpecs::TestYourself.option(:opt_with_default,
          short: "-D VALUE",
          default: "default-value")
      end
      # This supports a use case used by plugins, where the pattern
      # seems to follow:
      #   cmd = KnifeCommand.new
      #   cmd.config[:config_key] = value
      #   cmd.run
      #
      # This bypasses Knife::run and the `merge_configs` call it
      # performs - config_source should break when that happens.
      context "when config is fed in directly without a merge" do
        it "retains the value but returns nil as a config source" do
          command.config[:test1] = "value"
          expect(command.config[:test1]).to eq "value"
          expect(command.config_source(:test1)).to eq nil
        end
      end

    end
    describe "merging configuration options" do
      before do
        KnifeSpecs::TestYourself.option(:opt_with_default,
          short: "-D VALUE",
          default: "default-value")
      end

      it "sets the default log_location to STDERR for Chef::Log warnings" do
        knife_command = KnifeSpecs::TestYourself.new([])
        knife_command.configure_chef
        expect(Chef::Config[:log_location]).to eq(STDERR)
      end

      it "sets the default log_level to warn so we can issue Chef::Log.warn" do
        knife_command = KnifeSpecs::TestYourself.new([])
        knife_command.configure_chef
        expect(Chef::Config[:log_level]).to eql(:warn)
      end

      it "prefers the default value from option definition if no config or command line value is present and reports the source as default" do
        knife_command = KnifeSpecs::TestYourself.new([]) # empty argv
        knife_command.configure_chef
        expect(knife_command.config[:opt_with_default]).to eq("default-value")
        expect(knife_command.config_source(:opt_with_default)).to eq(:cli_default)
      end

      it "prefers a value in Chef::Config[:knife] to the default and reports the source as config" do
        Chef::Config[:knife][:opt_with_default] = "from-knife-config"
        knife_command = KnifeSpecs::TestYourself.new([]) # empty argv
        knife_command.configure_chef
        expect(knife_command.config[:opt_with_default]).to eq("from-knife-config")
        expect(knife_command.config_source(:opt_with_default)).to eq(:config)
      end

      it "prefers a value from command line over Chef::Config and the default and reports the source as CLI" do
        knife_command = KnifeSpecs::TestYourself.new(["-D", "from-cli"])
        knife_command.configure_chef
        expect(knife_command.config[:opt_with_default]).to eq("from-cli")
        expect(knife_command.config_source(:opt_with_default)).to eq(:cli)
      end

      it "merges `listen` config to Chef::Config" do
        knife_command = Chef::Knife.run(%w{test yourself --no-listen}, Chef::Application::Knife.options)
        expect(Chef::Config[:listen]).to be(false)
        expect(knife_command.config_source(:listen)).to eq(:cli)
      end

      it "merges Chef::Config[:knife] values into the config hash even if they have no cli keys" do
        Chef::Config[:knife][:opt_with_no_cli_key] = "from-knife-config"
        knife_command = KnifeSpecs::TestYourself.new([]) # empty argv
        knife_command.configure_chef
        expect(knife_command.config[:opt_with_no_cli_key]).to eq("from-knife-config")
        expect(knife_command.config_source(:opt_with_no_cli_key)).to eq(:config)
      end

      it "merges Chef::Config[:knife] default values into the config hash even if they have no cli keys" do
        Chef::Config.config_context :knife do
          default :opt_with_no_cli_key, "from-knife-default"
        end
        knife_command = KnifeSpecs::TestYourself.new([]) # empty argv
        knife_command.configure_chef
        expect(knife_command.config[:opt_with_no_cli_key]).to eq("from-knife-default")
        expect(knife_command.config_source(:opt_with_no_cli_key)).to eq(:config_default)
      end

      context "verbosity is one" do
        let(:fake_config) { "/does/not/exist/knife.rb" }

        before do
          knife.config[:verbosity] = 1
          knife.config[:config_file] = fake_config
          config_loader = double("Chef::WorkstationConfigLoader", load: true, no_config_found?: false, chef_config_dir: "/etc/chef", config_location: fake_config)
          allow(config_loader).to receive(:explicit_config_file=).with(fake_config).and_return(fake_config)
          allow(config_loader).to receive(:profile=)
          allow(Chef::WorkstationConfigLoader).to receive(:new).and_return(config_loader)
        end

        it "prints the path to the configuration file used" do
          stdout, stderr, stdin = StringIO.new, StringIO.new, StringIO.new
          knife.ui = Chef::Knife::UI.new(stdout, stderr, stdin, {})
          expect(Chef::Log).to receive(:info).with("Using configuration from #{fake_config}")
          knife.configure_chef
        end
      end

      # -VV (2) is debug, -VVV (3) is trace
      [ 2, 3 ].each do |verbosity|
        it "does not humanize the exception if Chef::Config[:verbosity] is #{verbosity}" do
          Chef::Config[:verbosity] = verbosity
          allow(knife).to receive(:run).and_raise(Exception)
          expect(knife).not_to receive(:humanize_exception)
          expect { knife.run_with_pretty_exceptions }.to raise_error(Exception)
        end
      end
    end

    describe "setting arbitrary configuration with --config-option" do

      let(:stdout) { StringIO.new }

      let(:stderr) { StringIO.new }

      let(:stdin) { StringIO.new }

      let(:ui) { Chef::Knife::UI.new(stdout, stderr, stdin, disable_editing: true) }

      let(:subcommand) do
        KnifeSpecs::TestYourself.options = Chef::Application::Knife.options.merge(KnifeSpecs::TestYourself.options)
        KnifeSpecs::TestYourself.new(%w{--config-option badly_formatted_arg}).tap do |cmd|
          cmd.ui = ui
        end
      end

      it "sets arbitrary configuration via --config-option" do
        Chef::Knife.run(%w{test yourself --config-option arbitrary_config_thing=hello}, Chef::Application::Knife.options)
        expect(Chef::Config[:arbitrary_config_thing]).to eq("hello")
      end

      it "handles errors in arbitrary configuration" do
        expect(subcommand).to receive(:exit).with(1)
        subcommand.configure_chef
        expect(stderr.string).to include("ERROR: Unparsable config option \"badly_formatted_arg\"")
        expect(stdout.string).to include(subcommand.opt_parser.to_s)
      end
    end

  end

  describe "when first created" do

    let(:knife) {
      Kernel.load "spec/data/knife_subcommand/test_yourself.rb"
      KnifeSpecs::TestYourself.new(%w{with some args -s scrogramming})
    }

    it "it parses the options passed to it" do
      expect(knife.config[:scro]).to eq("scrogramming")
    end

    it "extracts its command specific args from the full arg list" do
      expect(knife.name_args).to eq(%w{with some args})
    end

    it "does not have lazy dependencies loaded" do
      skip "unstable with randomization... prolly needs more isolation"

      expect(knife.class.test_deps_loaded).not_to be_truthy
    end
  end

  describe "when formatting exceptions" do

    let(:stdout) { StringIO.new }
    let(:stderr) { StringIO.new }
    let(:stdin) { StringIO.new }

    let(:ui) { Chef::Knife::UI.new(stdout, stderr, stdin, {}) }

    before do
      knife.ui = ui
      expect(knife).to receive(:exit).with(100)
    end

    it "formats 401s nicely" do
      response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "y u no syncronize your clock?"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("401 Unauthorized", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: Failed to authenticate to/)
      expect(stderr.string).to match(/Response:  y u no syncronize your clock\?/)
    end

    it "formats 403s nicely" do
      response = Net::HTTPForbidden.new("1.1", "403", "Forbidden")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "y u no administrator"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("403 Forbidden", response))
      allow(knife).to receive(:username).and_return("sadpanda")
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: You authenticated successfully to http.+ as sadpanda but you are not authorized for this action/)
      expect(stderr.string).to match(/Response:  y u no administrator/)
    end

    context "when proxy servers are set" do
      before do
        ENV["http_proxy"] = "xyz"
      end

      after do
        ENV.delete("http_proxy")
      end

      it "formats proxy errors nicely" do
        response = Net::HTTPForbidden.new("1.1", "403", "Forbidden")
        response.instance_variable_set(:@read, true)
        allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "y u no administrator"))
        allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("403 Forbidden", response))
        allow(knife).to receive(:username).and_return("sadpanda")
        knife.run_with_pretty_exceptions
        expect(stderr.string).to match(/ERROR: You authenticated successfully to http.+ as sadpanda but you are not authorized for this action/)
        expect(stderr.string).to match(/ERROR: There are proxy servers configured, your server url may need to be added to NO_PROXY./)
        expect(stderr.string).to match(/Response:  y u no administrator/)
      end
    end

    it "formats 400s nicely" do
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "y u search wrong"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("400 Bad Request", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: The data in your request was invalid/)
      expect(stderr.string).to match(/Response: y u search wrong/)
    end

    it "formats 404s nicely" do
      response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "nothing to see here"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("404 Not Found", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: The object you are looking for could not be found/)
      expect(stderr.string).to match(/Response: nothing to see here/)
    end

    it "formats 406s (non-supported API version error) nicely" do
      response = Net::HTTPNotAcceptable.new("1.1", "406", "Not Acceptable")
      response.instance_variable_set(:@read, true) # I hate you, net/http.

      # set the header
      response["x-ops-server-api-version"] = Chef::JSONCompat.to_json(min_version: "0", max_version: "1", request_version: "10000000")

      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "sad trombone"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("406 Not Acceptable", response))

      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/The request that .* sent was using API version 10000000./)
      expect(stderr.string).to match(/The server you sent the request to supports a min API version of 0 and a max API version of 1./)
      expect(stderr.string).to match(/Please either update your .* or the server to be a compatible set./)
    end

    it "formats 500s nicely" do
      response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "sad trombone"))
      allow(knife).to receive(:run).and_raise(Net::HTTPFatalError.new("500 Internal Server Error", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: internal server error/)
      expect(stderr.string).to match(/Response: sad trombone/)
    end

    it "formats 502s nicely" do
      response = Net::HTTPBadGateway.new("1.1", "502", "Bad Gateway")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "sadder trombone"))
      allow(knife).to receive(:run).and_raise(Net::HTTPFatalError.new("502 Bad Gateway", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: bad gateway/)
      expect(stderr.string).to match(/Response: sadder trombone/)
    end

    it "formats 503s nicely" do
      response = Net::HTTPServiceUnavailable.new("1.1", "503", "Service Unavailable")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "saddest trombone"))
      allow(knife).to receive(:run).and_raise(Net::HTTPFatalError.new("503 Service Unavailable", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: Service temporarily unavailable/)
      expect(stderr.string).to match(/Response: saddest trombone/)
    end

    it "formats other HTTP errors nicely" do
      response = Net::HTTPPaymentRequired.new("1.1", "402", "Payment Required")
      response.instance_variable_set(:@read, true) # I hate you, net/http.
      allow(response).to receive(:body).and_return(Chef::JSONCompat.to_json(error: "nobugfixtillyoubuy"))
      allow(knife).to receive(:run).and_raise(Net::HTTPClientException.new("402 Payment Required", response))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: Payment Required/)
      expect(stderr.string).to match(/Response: nobugfixtillyoubuy/)
    end

    it "formats NameError and NoMethodError nicely" do
      allow(knife).to receive(:run).and_raise(NameError.new("Undefined constant FUUU"))
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(/ERROR: .* encountered an unexpected error/)
      expect(stderr.string).to match(/This may be a bug in the 'knife' .* command or plugin/)
      expect(stderr.string).to match(/Exception: NameError: Undefined constant FUUU/)
    end

    it "formats missing private key errors nicely" do
      allow(knife).to receive(:run).and_raise(Chef::Exceptions::PrivateKeyMissing.new("key not there"))
      allow(knife).to receive(:api_key).and_return("/home/root/.chef/no-key-here.pem")
      knife.run_with_pretty_exceptions
      expect(stderr.string).to match(%r{ERROR: Your private key could not be loaded from /home/root/.chef/no-key-here.pem})
      expect(stderr.string).to match(/Check your configuration file and ensure that your private key is readable/)
    end

    it "formats connection refused errors nicely" do
      allow(knife).to receive(:run).and_raise(Errno::ECONNREFUSED.new("y u no shut up"))
      knife.run_with_pretty_exceptions
      # Errno::ECONNREFUSED message differs by platform
      # *nix = Errno::ECONNREFUSED: Connection refused
      # win32: Errno::ECONNREFUSED: No connection could be made because the target machine actively refused it.
      expect(stderr.string).to match(/ERROR: Network Error: .* - y u no shut up/)
      expect(stderr.string).to match(/Check your .* configuration and network settings/)
    end

    it "formats SSL errors nicely and suggests to use `knife ssl check` and `knife ssl fetch`" do
      error = OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed")
      allow(knife).to receive(:run).and_raise(error)

      knife.run_with_pretty_exceptions

      expected_message = <<~MSG
        ERROR: Could not establish a secure connection to the server.
        Use `.* ssl check` to troubleshoot your SSL configuration.
        If your server uses a self-signed certificate, you can use
        `.* ssl fetch` to make .* trust the server's certificates.
      MSG
      expect(stderr.string).to match(expected_message)
    end

  end

end
