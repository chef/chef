#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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

require "spec_helper"
require "chef/run_context"
require "chef/server_api"
require "rbconfig"

class FooError < RuntimeError
end

#
# SHARED CONTEXTS
#

# Stubs a basic client object
shared_context "client" do
  let(:fqdn)             { "hostname.example.org" }
  let(:hostname)         { "hostname" }
  let(:machinename)      { "machinename.example.org" }
  let(:platform)         { "example-platform" }
  let(:platform_version) { "example-platform-1.0" }

  let(:ohai_data) do
    {
      fqdn: fqdn,
      hostname: hostname,
      machinename: machinename,
      platform: platform,
      platform_version: platform_version,
    }
  end

  let(:ohai_system) do
    ohai = instance_double("Ohai::System", all_plugins: true, data: ohai_data, logger: logger)
    allow(ohai).to receive(:[]) do |k|
      ohai_data[k]
    end
    ohai
  end

  let(:node) do
    Chef::Node.new.tap do |n|
      n.name(fqdn)
      n.chef_environment("_default")
    end
  end

  let(:json_attribs) { nil }
  let(:client_opts) { {} }

  let(:stdout) { STDOUT }
  let(:stderr) { STDERR }

  let(:client) do
    Chef::Config[:event_loggers] = []
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
    opts = client_opts.merge({ logger: logger })
    Chef::Client.new(json_attribs, opts).tap do |c|
      c.node = node
    end
  end

  let(:logger) { instance_double("Mixlib::Log::Child", trace: nil, debug: nil, warn: nil, info: nil, error: nil, fatal: nil) }

  before do
    stub_const("Chef::Client::STDOUT_FD", stdout)
    stub_const("Chef::Client::STDERR_FD", stderr)
    allow(client).to receive(:logger).and_return(logger)
  end
end

# Stubs a client for a client run.
# Requires a client object be defined in the scope of this included context.
# e.g.:
#   describe "some functionality" do
#     include_context "client"
#     include_context "a client run"
#     ...
#   end
shared_context "a client run" do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  let(:api_client_exists?) { false }
  let(:enable_fork)        { false }

  let(:http_cookbook_sync)    { double("Chef::ServerAPI (cookbook sync)") }
  let(:http_node_load)        { double("Chef::ServerAPI (node)") }
  let(:http_node_save)        { double("Chef::ServerAPI (node save)") }
  let(:reporting_rest_client) { double("Chef::ServerAPI (reporting client)") }

  let(:runner) { instance_double("Chef::Runner") }

  def stub_for_register
    # --Client.register
    #   Make sure Client#register thinks the client key doesn't
    #   exist, so it tries to register and create one.
    allow(Chef::HTTP::Authenticator).to receive(:detect_certificate_key).with(fqdn).and_return(false)
    allow(File).to receive(:exists?).and_call_original
    expect(File).to receive(:exists?)
      .with(Chef::Config[:client_key])
      .exactly(:once)
      .and_return(api_client_exists?)

    unless api_client_exists?
      #   Client.register will register with the validation client name.
      expect_any_instance_of(Chef::ApiClient::Registration).to receive(:run)
    end
  end

  def stub_for_event_registration
    expect(client.events).to receive(:register).with(instance_of(Chef::DataCollector::Reporter))
    expect(client.events).to receive(:register).with(instance_of(Chef::ResourceReporter))
    expect(client.events).to receive(:register).with(instance_of(Chef::ActionCollection))
    expect(client.events).to receive(:register).with(instance_of(Chef::Compliance::Runner))
  end

  def stub_for_node_load
    #   Client.register will then turn around create another
    #   Chef::ServerAPI object, this time with the client key it got from the
    #   previous step.
    expect(Chef::ServerAPI).to receive(:new)
      .with(Chef::Config[:chef_server_url], client_name: fqdn,
                                           signing_key_filename: Chef::Config[:client_key])
      .exactly(:once)
      .and_return(http_node_load)

    # --Client#build_node
    #   looks up the node, which we will return, then later saves it.
    expect(Chef::Node).to receive(:find_or_create).with(fqdn).and_return(node)
  end

  def stub_rest_clean
    allow(client).to receive(:rest_clean).and_return(reporting_rest_client)
  end

  def stub_for_sync_cookbooks
    # --Client#setup_run_context
    # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
    #
    expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], version_class: Chef::CookbookManifestVersions).and_return(http_cookbook_sync)
    expect(http_cookbook_sync).to receive(:post)
      .with("environments/_default/cookbook_versions", { run_list: [] })
      .and_return({})
  end

  def stub_for_required_recipe
    response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
    exception = Net::HTTPClientException.new('404 "Not Found"', response)
    expect(http_node_load).to receive(:get).with("required_recipe").and_raise(exception)
  end

  def stub_for_converge
    # define me
  end

  def stub_for_node_save
    # define me
  end

  def stub_for_run
    # define me
  end

  before do
    Chef::Config[:client_fork] = enable_fork
    Chef::Config[:cache_path] = windows? ? 'C:\chef' : "/var/chef"
    Chef::Config[:why_run] = false
    Chef::Config[:chef_guid] = "default-guid"

    stub_rest_clean
    stub_for_register
    stub_for_event_registration
    stub_for_node_load
    stub_for_sync_cookbooks
    stub_for_required_recipe
    stub_for_converge
    stub_for_node_save

    expect_any_instance_of(Chef::RunLock).to receive(:acquire)
    expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
    expect_any_instance_of(Chef::RunLock).to receive(:release)

    # Post conditions: check that node has been filled in correctly
    expect(client).to receive(:run_started)
    stub_for_run
  end
end

shared_context "converge completed" do
  def stub_for_converge
    # --Client#converge
    expect(Chef::Runner).to receive(:new).and_return(runner)
    expect(runner).to receive(:converge).and_return(true)
  end

  def stub_for_node_save
    allow(node).to receive(:data_for_save).and_return(node.for_json)

    # --Client#save_updated_node
    expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], client_name: fqdn,
                                                                                  signing_key_filename: Chef::Config[:client_key], validate_utf8: false).and_return(http_node_save)
    expect(http_node_save).to receive(:put).with("nodes/#{fqdn}", node.for_json).and_return(true)
  end
end

shared_context "converge failed" do
  let(:converge_error) do
    err = Chef::Exceptions::UnsupportedAction.new("Action unsupported")
    err.set_backtrace([ "/path/recipe.rb:15", "/path/recipe.rb:12" ])
    err
  end

  def stub_for_converge
    expect(Chef::Runner).to receive(:new).and_return(runner)
    expect(runner).to receive(:converge).and_raise(converge_error)
  end

  def stub_for_node_save
    expect(client).to_not receive(:save_updated_node)
  end
end

shared_context "run completed" do
  def stub_for_run
    expect(client).to receive(:run_completed_successfully)
  end
end

shared_context "run failed" do
  def stub_for_run
    expect(client).to receive(:run_failed)
  end

  before do
    expect(Chef::Application).to receive(:debug_stacktrace).with(converge_error)
  end
end

#
# SHARED EXAMPLES
#

# requires platform and platform_version be defined
shared_examples "a completed run" do
  include_context "run completed" # should receive run_completed_successfully

  it "runs ohai, sets up authentication, loads node state, synchronizes policy, converges" do
    # This is what we're testing.
    expect(client.run).to be true

    # fork is stubbed, so we can see the outcome of the run
    expect(node.automatic_attrs[:platform]).to eq(platform)
    expect(node.automatic_attrs[:platform_version]).to eq(platform_version)
  end
end

shared_examples "a failed run" do
  include_context "run failed"

  it "skips node save and raises the error in a wrapping error" do
    expect { client.run }.to raise_error(converge_error)
  end
end

describe Chef::Client do
  include_context "client"

  context "when minimal ohai is configured" do
    before do
      Chef::Config[:minimal_ohai] = true
    end

    it "runs ohai with only the minimum required plugins" do
      expected_filter = %w{fqdn machinename hostname platform platform_version ohai_time os os_version init_package}
      expect(ohai_system).to receive(:all_plugins).with(expected_filter)
      client.run_ohai
    end
  end

  context "when Ohai tells us to fail" do
    it "fails" do
      ohai_system = Ohai::System.new
      module Ohai::Exceptions
        class CriticalPluginFailure < Error; end
      end
      expect(ohai_system).to receive(:all_plugins) { raise Ohai::Exceptions::CriticalPluginFailure }
      expect { client.run_ohai }.to raise_error(Ohai::Exceptions::CriticalPluginFailure)
    end
  end

  describe "eol release warning" do
    it "warns when running an EOL release" do
      stub_const("Chef::VERSION", 15)
      allow(Time).to receive(:now).and_return(Time.new(2021, 5, 1, 5))
      expect(logger).to receive(:warn).with(/This release of.*became end of life \(EOL\) on May 1st 2021/)
      client.warn_if_eol
    end

    it "does not warn when running an non-EOL release" do
      stub_const("Chef::VERSION", 15)
      allow(Time).to receive(:now).and_return(Time.new(2021, 4, 31))
      expect(logger).to_not receive(:warn).with(/became end of life/)
      client.warn_if_eol
    end
  end

  describe "authentication protocol selection" do
    context "when FIPS is disabled" do
      before do
        Chef::Config[:fips] = false
      end

      it "defaults to 1.1" do
        expect(Chef::Config[:authentication_protocol_version]).to eq("1.1")
      end
    end
    context "when FIPS is enabled" do
      before do
        Chef::Config[:fips] = true
      end

      it "defaults to 1.3" do
        expect(Chef::Config[:authentication_protocol_version]).to eq("1.3")
      end

      after do
        Chef::Config[:fips] = false
      end
    end
  end

  describe "configuring output formatters" do
    context "when no formatter has been configured" do
      it "configures the :doc formatter" do
        expect(client.formatters_for_run).to eq([[:doc, nil]])
      end

      context "and force_logger is set" do
        before do
          Chef::Config[:force_logger] = true
        end

        it "configures the :null formatter" do
          expect(client.formatters_for_run).to eq([[:null]])
        end
      end

      context "and force_formatter is set" do
        before do
          Chef::Config[:force_formatter] = true
        end

        it "configures the :doc formatter" do
          expect(client.formatters_for_run).to eq([[:doc, nil]])
        end
      end

      context "both are set" do
        before do
          Chef::Config[:force_formatter] = true
          Chef::Config[:force_logger] = true
        end

        it "configures the :doc formatter" do
          expect(client.formatters_for_run).to eq([[:doc, nil]])
        end
      end
    end

    context "when a formatter is configured" do
      context "with no output path" do
        before do
          Chef::Config.add_formatter(:min)
        end

        it "does not configure a default formatter" do
          expect(client.formatters_for_run).to eq([[:min, nil]])
        end

        it "configures the formatter for STDOUT/STDERR" do
          configured_formatters = client.configure_formatters
          min_formatter = configured_formatters[0]
          expect(min_formatter.output.out).to eq(STDOUT)
          expect(min_formatter.output.err).to eq(STDERR)
        end
      end

      context "with an output path" do
        before do
          @tmpout = Tempfile.open("rspec-for-client-formatter-selection-#{Process.pid}")
          Chef::Config.add_formatter(:min, @tmpout.path)
        end

        after do
          @tmpout.close unless @tmpout.closed?
          @tmpout.unlink
        end

        it "configures the formatter for the file path" do
          configured_formatters = client.configure_formatters
          min_formatter = configured_formatters[0]
          expect(min_formatter.output.out.path).to eq(@tmpout.path)
          expect(min_formatter.output.err.path).to eq(@tmpout.path)
        end
      end

    end
  end

  describe "a full client run" do
    shared_examples_for "a successful client run" do
      include_context "a client run"
      include_context "converge completed"

      include_examples "a completed run"
    end

    describe "when running chef-client without fork" do
      include_examples "a successful client run"
    end

    describe "when the client key already exists" do
      include_examples "a successful client run" do
        let(:api_client_exists?) { true }
      end
    end

    context "when an override run list is given" do
      it "permits spaces in overriding run list" do
        Chef::Client.new(nil, override_runlist: "role[a], role[b]")
      end

      describe "calling run" do
        include_examples "a successful client run" do
          let(:client_opts) { { override_runlist: "recipe[override_recipe]" } }

          def stub_for_sync_cookbooks
            # --Client#setup_run_context
            # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
            #
            expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
            expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], version_class: Chef::CookbookManifestVersions).and_return(http_cookbook_sync)
            expect(http_cookbook_sync).to receive(:post)
              .with("environments/_default/cookbook_versions", { run_list: ["override_recipe"] })
              .and_return({})
          end

          def stub_for_node_save
            # Expect NO node save
            expect(node).not_to receive(:save)
          end

          before do
            # Client will try to compile and run override_recipe
            expect_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile)
          end
        end
      end
    end

    describe "when a permanent run list is passed as an option" do
      it "sets the new run list on the node" do
        client.run
        expect(node.run_list).to eq(Chef::RunList.new(new_runlist))
      end

      include_examples "a successful client run" do
        let(:new_runlist) { "recipe[new_run_list_recipe]" }
        let(:client_opts) { { runlist: new_runlist } }

        def stub_for_sync_cookbooks
          # --Client#setup_run_context
          # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
          #
          expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
          expect(Chef::ServerAPI).to receive(:new).with(Chef::Config[:chef_server_url], version_class: Chef::CookbookManifestVersions).and_return(http_cookbook_sync)
          expect(http_cookbook_sync).to receive(:post)
            .with("environments/_default/cookbook_versions", { run_list: ["new_run_list_recipe"] })
            .and_return({})
        end

        before do
          # Client will try to compile and run the new_run_list_recipe, but we
          # do not create a fixture for this.
          expect_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile)
        end
      end
    end

    describe "when converge completes successfully" do
      include_context "a client run"
      include_context "converge completed"
    end

    describe "when converge errors" do
      include_context "a client run"
      include_context "converge failed"
      include_examples "a failed run" do
        let(:run_errors) { [converge_error] }
      end
    end
  end

  describe "when handling run failures" do
    it "should remove the run_lock on failure of #load_node" do
      @run_lock = double("Chef::RunLock", acquire: true)
      allow(Chef::RunLock).to receive(:new).and_return(@run_lock)

      @events = double("Chef::EventDispatch::Dispatcher").as_null_object
      allow(Chef::EventDispatch::Dispatcher).to receive(:new).and_return(@events)
      # @events is created on Chef::Client.new, so we need to recreate it after mocking
      client = Chef::Client.new
      allow(client).to receive(:load_node).and_raise(Exception)
      expect(@run_lock).to receive(:release)
      expect { client.run }.to raise_error(Exception)
    end
  end

  describe "when notifying other objects of the status of the chef run" do
    before do
      Chef::Client.clear_notifications
      allow(Chef::Node).to receive(:find_or_create).and_return(node)
      allow(node).to receive(:save)
      client.load_node
      client.build_node
    end

    it "notifies observers that the run has started" do
      notified = false
      Chef::Client.when_run_starts do |run_status|
        expect(run_status.node).to eq(node)
        notified = true
      end

      client.run_started
      expect(notified).to be_truthy
    end

    it "notifies observers that the run has completed successfully" do
      notified = false
      Chef::Client.when_run_completes_successfully do |run_status|
        expect(run_status.node).to eq(node)
        notified = true
      end

      client.run_completed_successfully
      expect(notified).to be_truthy
    end

    it "notifies observers that the run failed" do
      notified = false
      Chef::Client.when_run_fails do |run_status|
        expect(run_status.node).to eq(node)
        notified = true
      end

      client.run_failed
      expect(notified).to be_truthy
    end
  end

  describe "build_node" do
    it "should expand the roles and recipes for the node" do
      node.run_list << "role[role_containing_cookbook1]"
      role_containing_cookbook1 = Chef::Role.new
      role_containing_cookbook1.name("role_containing_cookbook1")
      role_containing_cookbook1.run_list << "cookbook1"

      # build_node will call Node#expand! with server, which will
      # eventually hit the server to expand the included role.
      mock_chef_rest = double("Chef::ServerAPI")
      expect(mock_chef_rest).to receive(:get).with("roles/role_containing_cookbook1").and_return(role_containing_cookbook1.to_hash)
      expect(Chef::ServerAPI).to receive(:new).and_return(mock_chef_rest)

      # check pre-conditions.
      expect(node[:roles]).to be_nil
      expect(node[:recipes]).to be_nil
      expect(node[:expanded_run_list]).to be_nil

      allow(client.policy_builder).to receive(:node).and_return(node)
      client.policy_builder.select_implementation(node)
      allow(client.policy_builder.implementation).to receive(:node).and_return(node)

      # chefspec and possibly others use the return value of this method
      expect(client.build_node).to eq(node)

      # check post-conditions.
      expect(node[:roles]).not_to be_nil
      expect(node[:roles].length).to eq(1)
      expect(node[:roles]).to include("role_containing_cookbook1")
      expect(node[:recipes]).not_to be_nil
      expect(node[:recipes].length).to eq(2)
      expect(node[:recipes]).to include("cookbook1")
      expect(node[:recipes]).to include("cookbook1::default")
      expect(node[:expanded_run_list]).not_to be_nil
      expect(node[:expanded_run_list].length).to eq(1)
      expect(node[:expanded_run_list]).to include("cookbook1::default")
    end

    it "should set the environment from the specified configuration value" do
      expect(node.chef_environment).to eq("_default")
      Chef::Config[:environment] = "A"

      test_env = { "name" => "A" }

      mock_chef_rest = double("Chef::ServerAPI")
      expect(mock_chef_rest).to receive(:get).with("environments/A").and_return(test_env)
      expect(Chef::ServerAPI).to receive(:new).and_return(mock_chef_rest)
      allow(client.policy_builder).to receive(:node).and_return(node)
      client.policy_builder.select_implementation(node)
      allow(client.policy_builder.implementation).to receive(:node).and_return(node)
      expect(client.build_node).to eq(node)

      expect(node.chef_environment).to eq("A")
    end
  end

  describe "load_required_recipe" do
    let(:rest)        { double("Chef::ServerAPI (required recipe)") }
    let(:run_context) { double("Chef::RunContext") }
    let(:recipe)      { double("Chef::Recipe (required recipe)") }
    let(:required_recipe) do
      <<~EOM
        fake_recipe_variable = "for reals"
      EOM
    end

    context "when required_recipe is configured" do

      before(:each) do
        expect(rest).to receive(:get).with("required_recipe").and_return(required_recipe)
        expect(Chef::Recipe).to receive(:new).with(nil, nil, run_context).and_return(recipe)
        expect(recipe).to receive(:from_file)
      end

      it "fetches the recipe and adds it to the run context" do
        client.load_required_recipe(rest, run_context)
      end

      context "when the required_recipe has bad contents" do
        let(:required_recipe) do
          <<~EOM
            this is not a recipe
          EOM
        end
        it "should not raise an error" do
          expect { client.load_required_recipe(rest, run_context) }.not_to raise_error
        end
      end
    end

    context "when required_recipe returns 404" do
      let(:http_response) { Net::HTTPNotFound.new("1.1", "404", "Not Found") }
      let(:http_exception) { Net::HTTPClientException.new('404 "Not Found"', http_response) }

      before(:each) do
        expect(rest).to receive(:get).with("required_recipe").and_raise(http_exception)
      end

      it "should log and continue on" do
        expect(logger).to receive(:trace)
        client.load_required_recipe(rest, run_context)
      end
    end
  end

  describe "windows_admin_check" do
    context "platform is not windows" do
      before do
        allow(ChefUtils).to receive(:windows?).and_return(false)
      end

      it "shouldn't be called" do
        expect(client).not_to receive(:has_admin_privileges?)
        client.do_windows_admin_check
      end
    end

    context "platform is windows" do
      before do
        allow(ChefUtils).to receive(:windows?).and_return(true)
      end

      it "should be called" do
        expect(client).to receive(:has_admin_privileges?)
        client.do_windows_admin_check
      end

      context "admin privileges exist" do
        before do
          expect(client).to receive(:has_admin_privileges?).and_return(true)
        end

        it "should not log a warning message" do
          expect(logger).not_to receive(:warn)
          client.do_windows_admin_check
        end

        context "fatal admin check is configured" do
          it "should not raise an exception" do
            client.do_windows_admin_check # should not raise
          end
        end
      end

      context "admin privileges doesn't exist" do
        before do
          expect(client).to receive(:has_admin_privileges?).and_return(false)
        end

        it "should log a warning message" do
          expect(logger).to receive(:warn)
          client.do_windows_admin_check
        end

        context "fatal admin check is configured" do
          it "should raise an exception" do
            client.do_windows_admin_check # should not raise
          end
        end
      end
    end
  end

  describe "assert_cookbook_path_not_empty" do
    before do
      Chef::Config[:solo_legacy_mode] = true
      Chef::Config[:cookbook_path] = ["/path/to/invalid/cookbook_path"]
    end

    context "when any directory of cookbook_path contains no cookbook" do
      it "raises CookbookNotFound error" do
        invalid_cookbook_path = windows? ? "C:/path/to/invalid/cookbook_path" : "/path/to/invalid/cookbook_path"
        msg = "None of the cookbook paths set in Chef::Config[:cookbook_path], [\"#{invalid_cookbook_path}\"], contain any cookbooks"

        expect do
          client.send(:assert_cookbook_path_not_empty, nil)
        end.to raise_error(Chef::Exceptions::CookbookNotFound, msg)
      end
    end
  end

  describe "setting node name" do
    context "when machinename, hostname and fqdn are all set" do
      it "favors the fqdn" do
        expect(client.node_name).to eql(fqdn)
      end
    end

    context "when fqdn is missing" do
      # ohai 7 should always have machinename == return of hostname
      let(:fqdn) { nil }
      it "favors the machinename" do
        expect(client.node_name).to eql(machinename)
      end
    end

    context "when fqdn and machinename are missing" do
      # ohai 6 will not have machinename, return the short hostname
      let(:fqdn) { nil }
      let(:machinename) { nil }
      it "falls back to hostname" do
        expect(client.node_name).to eql(hostname)
      end
    end

    context "when they're all missing" do
      let(:machinename) { nil }
      let(:hostname) { nil }
      let(:fqdn) { nil }

      it "throws an exception" do
        expect { client.node_name }.to raise_error(Chef::Exceptions::CannotDetermineNodeName)
      end
    end
  end

  describe "always attempt to run handlers" do
    subject { client }
    before do
      # fail on the first thing in begin block
      allow_any_instance_of(Chef::RunLock).to receive(:save_pid).and_raise(NoMethodError)
    end
  end

  describe "deprecated enforce_path_sanity" do
    include_context "a client run"
    include_context "converge completed"

    it "print a warning, when enforce_path_sanity is passed" do
      Chef::Config[:enforce_path_sanity] = true
      expect(logger).to receive(:warn).with("`enforce_path_sanity` is deprecated, please use `enforce_default_paths` instead!")
      client.run
    end

    it "should not print a warning, when enforce_path_sanity is not passed" do
      expect(logger).not_to receive(:warn).with("`enforce_path_sanity` is deprecated, please use `enforce_default_paths` instead!")
      client.run
    end
  end
end
