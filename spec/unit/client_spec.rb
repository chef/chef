#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright 2008-2010 Opscode, Inc.
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

require 'chef/run_context'
require 'chef/rest'
require 'rbconfig'

class FooError < RuntimeError
end

describe Chef::Client do

  let(:hostname) { "hostname" }
  let(:machinename) { "machinename.example.org" }
  let(:fqdn) { "hostname.example.org" }

  let(:ohai_data) do
    { :fqdn             => fqdn,
      :hostname         => hostname,
      :machinename      => machinename,
      :platform         => 'example-platform',
      :platform_version => 'example-platform-1.0',
      :data             => {}
    }
  end

  let(:ohai_system) do
    ohai_system = double( "Ohai::System",
                          :all_plugins => true,
                          :data => ohai_data)
    allow(ohai_system).to receive(:[]) do |key|
      ohai_data[key]
    end
    ohai_system
  end

  let(:node) do
    Chef::Node.new.tap do |n|
      n.name(fqdn)
      n.chef_environment("_default")
    end
  end

  let(:json_attribs) { nil }
  let(:client_opts) { {} }

  let(:client) do
    Chef::Config[:event_loggers] = []
    Chef::Client.new(json_attribs, client_opts).tap do |c|
      c.node = node
    end
  end

  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    # Node/Ohai data
    #Chef::Config[:node_name] = fqdn
    allow(Ohai::System).to receive(:new).and_return(ohai_system)
  end

  context "when minimal ohai is configured" do
    before do
      Chef::Config[:minimal_ohai] = true
    end

    it "runs ohai with only the minimum required plugins" do
      expected_filter = %w[fqdn machinename hostname platform platform_version os os_version]
      expect(ohai_system).to receive(:all_plugins).with(expected_filter)
      client.run_ohai
    end

  end

  describe "authentication protocol selection" do
    after do
      Chef::Config[:authentication_protocol_version] = "1.0"
    end

    context "when the node name is <= 90 bytes" do
      it "does not force the authentication protocol to 1.1" do
        Chef::Config[:node_name] = ("f" * 90)
        # ugly that this happens as a side effect of a getter :(
        client.node_name
        expect(Chef::Config[:authentication_protocol_version]).to eq("1.0")
      end
    end

    context "when the node name is > 90 bytes" do
      it "sets the authentication protocol to version 1.1" do
        Chef::Config[:node_name] = ("f" * 91)
        # ugly that this happens as a side effect of a getter :(
        client.node_name
        expect(Chef::Config[:authentication_protocol_version]).to eq("1.1")
      end
    end
  end

  describe "configuring output formatters" do
    context "when no formatter has been configured" do

      context "and STDOUT is a TTY" do
        before do
          allow(STDOUT).to receive(:tty?).and_return(true)
        end

        it "configures the :doc formatter" do
          expect(client.formatters_for_run).to eq([[:doc]])
        end

        context "and force_logger is set" do
          before do
            Chef::Config[:force_logger] = true
          end

          it "configures the :null formatter" do
            expect(Chef::Config[:force_logger]).to be_truthy
            expect(client.formatters_for_run).to eq([[:null]])
          end

        end

      end

      context "and STDOUT is not a TTY" do
        before do
          allow(STDOUT).to receive(:tty?).and_return(false)
        end

        it "configures the :null formatter" do
          expect(client.formatters_for_run).to eq([[:null]])
        end

        context "and force_formatter is set" do
          before do
            Chef::Config[:force_formatter] = true
          end
          it "it configures the :doc formatter" do
            expect(client.formatters_for_run).to eq([[:doc]])
          end
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
    shared_context "a client run" do
      let(:http_node_load) { double("Chef::REST (node)") }
      let(:http_cookbook_sync) { double("Chef::REST (cookbook sync)") }
      let(:http_node_save) { double("Chef::REST (node save)") }
      let(:runner) { double("Chef::Runner") }
      let(:audit_runner) { instance_double("Chef::Audit::Runner", :failed? => false) }

      let(:api_client_exists?) { false }

      let(:stdout) { StringIO.new }
      let(:stderr) { StringIO.new }

      let(:enable_fork) { false }

      def stub_for_register
        # --Client.register
        #   Make sure Client#register thinks the client key doesn't
        #   exist, so it tries to register and create one.
        allow(File).to receive(:exists?).and_call_original
        expect(File).to receive(:exists?).
          with(Chef::Config[:client_key]).
          exactly(:once).
          and_return(api_client_exists?)

        unless api_client_exists?
          #   Client.register will register with the validation client name.
          expect_any_instance_of(Chef::ApiClient::Registration).to receive(:run)
        end
      end

      def stub_for_node_load
        #   Client.register will then turn around create another
        #   Chef::REST object, this time with the client key it got from the
        #   previous step.
        expect(Chef::REST).to receive(:new).
          with(Chef::Config[:chef_server_url], fqdn, Chef::Config[:client_key]).
          exactly(:once).
          and_return(http_node_load)

        # --Client#build_node
        #   looks up the node, which we will return, then later saves it.
        expect(Chef::Node).to receive(:find_or_create).with(fqdn).and_return(node)

        # --ResourceReporter#node_load_completed
        #   gets a run id from the server for storing resource history
        #   (has its own tests, so stubbing it here.)
        expect_any_instance_of(Chef::ResourceReporter).to receive(:node_load_completed)
      end

      def stub_for_sync_cookbooks
        # --Client#setup_run_context
        # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
        #
        expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
        expect(Chef::REST).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
        expect(http_cookbook_sync).to receive(:post).
          with("environments/_default/cookbook_versions", {:run_list => []}).
          and_return({})
      end

      def stub_for_converge
        # --Client#converge
        expect(Chef::Runner).to receive(:new).and_return(runner)
        expect(runner).to receive(:converge).and_return(true)
      end

      def stub_for_audit
        # -- Client#run_audits
        expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
        expect(audit_runner).to receive(:run).and_return(true)
      end

      def stub_for_node_save
        allow(node).to receive(:data_for_save).and_return(node.for_json)

        # --Client#save_updated_node
        expect(Chef::REST).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_node_save)
        expect(http_node_save).to receive(:put_rest).with("nodes/#{fqdn}", node.for_json).and_return(true)
      end

      def stub_for_run
        expect_any_instance_of(Chef::RunLock).to receive(:acquire)
        expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
        expect_any_instance_of(Chef::RunLock).to receive(:release)

        # Post conditions: check that node has been filled in correctly
        expect(client).to receive(:run_started)
        expect(client).to receive(:run_completed_successfully)

        # --ResourceReporter#run_completed
        #   updates the server with the resource history
        #   (has its own tests, so stubbing it here.)
        expect_any_instance_of(Chef::ResourceReporter).to receive(:run_completed)
        # --AuditReporter#run_completed
        #   posts the audit data to server.
        #   (has its own tests, so stubbing it here.)
        expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_completed)
      end

      before do
        Chef::Config[:client_fork] = enable_fork
        Chef::Config[:cache_path] = windows? ? 'C:\chef' : '/var/chef'
        Chef::Config[:why_run] = false
        Chef::Config[:audit_mode] = :enabled

        stub_const("Chef::Client::STDOUT_FD", stdout)
        stub_const("Chef::Client::STDERR_FD", stderr)

        stub_for_register
        stub_for_node_load
        stub_for_sync_cookbooks
        stub_for_converge
        stub_for_audit
        stub_for_node_save
        stub_for_run
      end
    end

    shared_examples_for "a successful client run" do
      include_context "a client run"

      it "runs ohai, sets up authentication, loads node state, synchronizes policy, converges, and runs audits" do
        # This is what we're testing.
        client.run

        # fork is stubbed, so we can see the outcome of the run
        expect(node.automatic_attrs[:platform]).to eq("example-platform")
        expect(node.automatic_attrs[:platform_version]).to eq("example-platform-1.0")
      end
    end

    describe "when running chef-client without fork" do
      include_examples "a successful client run"
    end

    describe "when the client key already exists" do
      let(:api_client_exists?) { true }
      include_examples "a successful client run"
    end

    describe "when an override run list is given" do
      let(:client_opts) { {:override_runlist => "recipe[override_recipe]"} }

      it "should permit spaces in overriding run list" do
        Chef::Client.new(nil, :override_runlist => 'role[a], role[b]')
      end

      describe "when running the client" do
        include_examples "a successful client run" do

          before do
            # Client will try to compile and run override_recipe
            expect_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile)
          end

          def stub_for_sync_cookbooks
            # --Client#setup_run_context
            # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
            #
            expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
            expect(Chef::REST).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
            expect(http_cookbook_sync).to receive(:post).
              with("environments/_default/cookbook_versions", {:run_list => ["override_recipe"]}).
              and_return({})
          end

          def stub_for_node_save
            # Expect NO node save
            expect(node).not_to receive(:save)
          end
        end
      end
    end

    describe "when a permanent run list is passed as an option" do
      include_examples "a successful client run" do

        let(:new_runlist) { "recipe[new_run_list_recipe]" }
        let(:client_opts) { {:runlist => new_runlist} }

        def stub_for_sync_cookbooks
          # --Client#setup_run_context
          # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
          #
          expect_any_instance_of(Chef::CookbookSynchronizer).to receive(:sync_cookbooks)
          expect(Chef::REST).to receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
          expect(http_cookbook_sync).to receive(:post).
            with("environments/_default/cookbook_versions", {:run_list => ["new_run_list_recipe"]}).
            and_return({})
        end

        before do
          # Client will try to compile and run the new_run_list_recipe, but we
          # do not create a fixture for this.
          expect_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile)
        end

        it "sets the new run list on the node" do
          client.run
          expect(node.run_list).to eq(Chef::RunList.new(new_runlist))
        end
      end
    end

    describe "when converge fails" do
      include_context "a client run" do
        let(:e) { Exception.new }
        def stub_for_converge
          expect(Chef::Runner).to receive(:new).and_return(runner)
          expect(runner).to receive(:converge).and_raise(e)
          expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(Chef::Exceptions::RunFailedWrappingError)
        end

        def stub_for_node_save
          expect(client).to_not receive(:save_updated_node)
        end

        def stub_for_run
          expect_any_instance_of(Chef::RunLock).to receive(:acquire)
          expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
          expect_any_instance_of(Chef::RunLock).to receive(:release)

          # Post conditions: check that node has been filled in correctly
          expect(client).to receive(:run_started)
          expect(client).to receive(:run_failed)

          expect_any_instance_of(Chef::ResourceReporter).to receive(:run_failed)
          expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_failed)
        end
      end

      it "runs the audits and raises the error" do
        expect{ client.run }.to raise_error(Chef::Exceptions::RunFailedWrappingError) do |error|
          expect(error.wrapped_errors.size).to eq(1)
          expect(error.wrapped_errors[0]).to eq(e)
        end
      end
    end

    describe "when the audit phase fails" do
      context "with an exception" do
        context "when audit mode is enabled" do
          include_context "a client run" do
            let(:e) { Exception.new }
            def stub_for_audit
              expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
              expect(audit_runner).to receive(:run).and_raise(e)
              expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(Chef::Exceptions::RunFailedWrappingError)
            end

            def stub_for_run
              expect_any_instance_of(Chef::RunLock).to receive(:acquire)
              expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
              expect_any_instance_of(Chef::RunLock).to receive(:release)

              # Post conditions: check that node has been filled in correctly
              expect(client).to receive(:run_started)
              expect(client).to receive(:run_failed)

              expect_any_instance_of(Chef::ResourceReporter).to receive(:run_failed)
              expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_failed)
            end
          end

          it "should save the node after converge and raise exception" do
            expect{ client.run }.to raise_error(Chef::Exceptions::RunFailedWrappingError) do |error|
              expect(error.wrapped_errors.size).to eq(1)
              expect(error.wrapped_errors[0]).to eq(e)
            end
          end
        end

        context "when audit mode is disabled" do
          include_context "a client run" do
            before do
              Chef::Config[:audit_mode] = :disabled
            end

            let(:e) { FooError.new }

            def stub_for_audit
              expect(Chef::Audit::Runner).to_not receive(:new)
            end

            def stub_for_converge
              expect(Chef::Runner).to receive(:new).and_return(runner)
              expect(runner).to receive(:converge).and_raise(e)
              expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(FooError)
            end

            def stub_for_node_save
              expect(client).to_not receive(:save_updated_node)
            end

            def stub_for_run
              expect_any_instance_of(Chef::RunLock).to receive(:acquire)
              expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
              expect_any_instance_of(Chef::RunLock).to receive(:release)


              # Post conditions: check that node has been filled in correctly
              expect(client).to receive(:run_started)
              expect(client).to receive(:run_failed)

              expect_any_instance_of(Chef::ResourceReporter).to receive(:run_failed)

            end

            it "re-raises an unwrapped exception" do
              expect { client.run }.to raise_error(FooError)
            end
          end
        end


      end

      context "with failed audits" do
        include_context "a client run" do
          let(:audit_runner) do
            instance_double("Chef::Audit::Runner", :run => true, :failed? => true, :num_failed => 1, :num_total => 1)
          end

          def stub_for_audit
            expect(Chef::Audit::Runner).to receive(:new).and_return(audit_runner)
            expect(Chef::Application).to receive(:debug_stacktrace).with an_instance_of(Chef::Exceptions::RunFailedWrappingError)
          end

          def stub_for_run
            expect_any_instance_of(Chef::RunLock).to receive(:acquire)
            expect_any_instance_of(Chef::RunLock).to receive(:save_pid)
            expect_any_instance_of(Chef::RunLock).to receive(:release)

            # Post conditions: check that node has been filled in correctly
            expect(client).to receive(:run_started)
            expect(client).to receive(:run_failed)

            expect_any_instance_of(Chef::ResourceReporter).to receive(:run_failed)
            expect_any_instance_of(Chef::Audit::AuditReporter).to receive(:run_failed)
          end
        end

        it "should save the node after converge and raise exception" do
          expect{ client.run }.to raise_error(Chef::Exceptions::RunFailedWrappingError) do |error|
            expect(error.wrapped_errors.size).to eq(1)
            expect(error.wrapped_errors[0]).to be_instance_of(Chef::Exceptions::AuditsFailed)
          end
        end
      end
    end

    describe "when why_run mode is enabled" do
      include_context "a client run" do

        before do
          Chef::Config[:why_run] = true
        end

        def stub_for_audit
          expect(Chef::Audit::Runner).to_not receive(:new)
        end

        def stub_for_node_save
          # This is how we should be mocking external calls - not letting it fall all the way through to the
          # REST call
          expect(node).to receive(:save)
        end

        it "runs successfully without enabling the audit runner" do
          client.run

          # fork is stubbed, so we can see the outcome of the run
          expect(node.automatic_attrs[:platform]).to eq("example-platform")
          expect(node.automatic_attrs[:platform_version]).to eq("example-platform-1.0")
        end
      end
    end

    describe "when audits are disabled" do
      include_context "a client run" do

        before do
          Chef::Config[:audit_mode] = :disabled
        end

        def stub_for_audit
          expect(Chef::Audit::Runner).to_not receive(:new)
        end

        it "runs successfully without enabling the audit runner" do
          client.run

          # fork is stubbed, so we can see the outcome of the run
          expect(node.automatic_attrs[:platform]).to eq("example-platform")
          expect(node.automatic_attrs[:platform_version]).to eq("example-platform-1.0")
        end
      end
    end

  end


  describe "when handling run failures" do

    it "should remove the run_lock on failure of #load_node" do
      @run_lock = double("Chef::RunLock", :acquire => true)
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
      mock_chef_rest = double("Chef::REST")
      expect(mock_chef_rest).to receive(:get_rest).with("roles/role_containing_cookbook1").and_return(role_containing_cookbook1)
      expect(Chef::REST).to receive(:new).and_return(mock_chef_rest)

      # check pre-conditions.
      expect(node[:roles]).to be_nil
      expect(node[:recipes]).to be_nil

      allow(client.policy_builder).to receive(:node).and_return(node)

      # chefspec and possibly others use the return value of this method
      expect(client.build_node).to eq(node)

      # check post-conditions.
      expect(node[:roles]).not_to be_nil
      expect(node[:roles].length).to eq(1)
      expect(node[:roles]).to include("role_containing_cookbook1")
      expect(node[:recipes]).not_to be_nil
      expect(node[:recipes].length).to eq(1)
      expect(node[:recipes]).to include("cookbook1")
    end

    it "should set the environment from the specified configuration value" do
      expect(node.chef_environment).to eq("_default")
      Chef::Config[:environment] = "A"

      test_env = Chef::Environment.new
      test_env.name("A")

      mock_chef_rest = double("Chef::REST")
      expect(mock_chef_rest).to receive(:get_rest).with("environments/A").and_return(test_env)
      expect(Chef::REST).to receive(:new).and_return(mock_chef_rest)
      allow(client.policy_builder).to receive(:node).and_return(node)
      expect(client.build_node).to eq(node)

      expect(node.chef_environment).to eq("A")
    end
  end

  describe "windows_admin_check" do
    context "platform is not windows" do
      before do
        allow(Chef::Platform).to receive(:windows?).and_return(false)
      end

      it "shouldn't be called" do
        expect(client).not_to receive(:has_admin_privileges?)
        client.do_windows_admin_check
      end
    end

    context "platform is windows" do
      before do
        allow(Chef::Platform).to receive(:windows?).and_return(true)
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
          expect(Chef::Log).not_to receive(:warn)
          client.do_windows_admin_check
        end

        context "fatal admin check is configured" do
          it "should not raise an exception" do
            client.do_windows_admin_check #should not raise
          end
        end
      end

      context "admin privileges doesn't exist" do
        before do
          expect(client).to receive(:has_admin_privileges?).and_return(false)
        end

        it "should log a warning message" do
          expect(Chef::Log).to receive(:warn)
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
      Chef::Config[:solo] = true
      Chef::Config[:cookbook_path] = ["/path/to/invalid/cookbook_path"]
    end
    context "when any directory of cookbook_path contains no cookbook" do
      it "raises CookbookNotFound error" do
        expect do
          client.send(:assert_cookbook_path_not_empty, nil)
        end.to raise_error(Chef::Exceptions::CookbookNotFound, 'None of the cookbook paths set in Chef::Config[:cookbook_path], ["/path/to/invalid/cookbook_path"], contain any cookbooks')
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

    it "should run exception handlers on early fail" do
      expect(subject).to receive(:run_failed)
      expect { subject.run }.to raise_error(NoMethodError)
    end
  end
end
