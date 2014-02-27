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

describe Chef::Client do

  let(:hostname) { "hostname" }
  let(:fqdn) { "hostname.example.org" }

  let(:ohai_data) do
    { :fqdn             => fqdn,
      :hostname         => hostname,
      :platform         => 'example-platform',
      :platform_version => 'example-platform-1.0',
      :data             => {}
    }
  end

  let(:ohai_system) do
    ohai_system = double( "Ohai::System",
                          :all_plugins => true,
                          :data => ohai_data)
    ohai_system.stub(:[]) do |key|
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
    Chef::Client.new(json_attribs, client_opts).tap do |c|
      c.node = node
    end
  end

  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    # Node/Ohai data
    #Chef::Config[:node_name] = fqdn
    Ohai::System.stub(:new).and_return(ohai_system)
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
        Chef::Config[:authentication_protocol_version].should == "1.0"
      end
    end

    context "when the node name is > 90 bytes" do
      it "sets the authentication protocol to version 1.1" do
        Chef::Config[:node_name] = ("f" * 91)
        # ugly that this happens as a side effect of a getter :(
        client.node_name
        Chef::Config[:authentication_protocol_version].should == "1.1"
      end
    end
  end

  describe "configuring output formatters" do
    context "when no formatter has been configured" do

      context "and STDOUT is a TTY" do
        before do
          STDOUT.stub(:tty?).and_return(true)
        end

        it "configures the :doc formatter" do
          client.formatters_for_run.should == [[:doc]]
        end

        context "and force_logger is set" do
          before do
            Chef::Config[:force_logger] = true
          end

          it "configures the :null formatter" do
            Chef::Config[:force_logger].should be_true
            client.formatters_for_run.should == [[:null]]
          end

        end

      end

      context "and STDOUT is not a TTY" do
        before do
          STDOUT.stub(:tty?).and_return(false)
        end

        it "configures the :null formatter" do
          client.formatters_for_run.should == [[:null]]
        end

        context "and force_formatter is set" do
          before do
            Chef::Config[:force_formatter] = true
          end
          it "it configures the :doc formatter" do
            client.formatters_for_run.should == [[:doc]]
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
          client.formatters_for_run.should == [[:min, nil]]
        end

        it "configures the formatter for STDOUT/STDERR" do
          configured_formatters = client.configure_formatters
          min_formatter = configured_formatters[0]
          min_formatter.output.out.should == STDOUT
          min_formatter.output.err.should == STDERR
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
          min_formatter.output.out.path.should == @tmpout.path
          min_formatter.output.err.path.should == @tmpout.path
        end
      end

    end
  end

  describe "a full client run" do
    shared_examples_for "a successful client run" do
      let(:http_node_load) { double("Chef::REST (node)") }
      let(:http_cookbook_sync) { double("Chef::REST (cookbook sync)") }
      let(:http_node_save) { double("Chef::REST (node save)") }
      let(:runner) { double("Chef::Runner") }

      let(:api_client_exists?) { false }

      let(:stdout) { StringIO.new }
      let(:stderr) { StringIO.new }

      let(:enable_fork) { false }

      def stub_for_register
        # --Client.register
        #   Make sure Client#register thinks the client key doesn't
        #   exist, so it tries to register and create one.
        File.should_receive(:exists?).with(Chef::Config[:client_key]).exactly(1).times.and_return(api_client_exists?)

        unless api_client_exists?
          #   Client.register will register with the validation client name.
          Chef::ApiClient::Registration.any_instance.should_receive(:run)
        end
      end

      def stub_for_node_load
        #   Client.register will then turn around create another
        #   Chef::REST object, this time with the client key it got from the
        #   previous step.
        Chef::REST.should_receive(:new).
          with(Chef::Config[:chef_server_url], fqdn, Chef::Config[:client_key]).
          exactly(1).
          and_return(http_node_load)

        # --Client#build_node
        #   looks up the node, which we will return, then later saves it.
        Chef::Node.should_receive(:find_or_create).with(fqdn).and_return(node)

        # --ResourceReporter#node_load_completed
        #   gets a run id from the server for storing resource history
        #   (has its own tests, so stubbing it here.)
        Chef::ResourceReporter.any_instance.should_receive(:node_load_completed)
      end

      def stub_for_sync_cookbooks
        # --Client#setup_run_context
        # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
        #
        Chef::CookbookSynchronizer.any_instance.should_receive(:sync_cookbooks)
        Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
        http_cookbook_sync.should_receive(:post).
          with("environments/_default/cookbook_versions", {:run_list => []}).
          and_return({})
      end

      def stub_for_converge
        # --Client#converge
        Chef::Runner.should_receive(:new).and_return(runner)
        runner.should_receive(:converge).and_return(true)

        # --ResourceReporter#run_completed
        #   updates the server with the resource history
        #   (has its own tests, so stubbing it here.)
        Chef::ResourceReporter.any_instance.should_receive(:run_completed)
      end

      def stub_for_node_save
        # --Client#save_updated_node
        Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_node_save)
        http_node_save.should_receive(:put_rest).with("nodes/#{fqdn}", node).and_return(true)
      end

      def stub_for_run
        Chef::RunLock.any_instance.should_receive(:acquire)
        Chef::RunLock.any_instance.should_receive(:save_pid)
        Chef::RunLock.any_instance.should_receive(:release)

        # Post conditions: check that node has been filled in correctly
        client.should_receive(:run_started)
        client.should_receive(:run_completed_successfully)
      end

      before do
        Chef::Config[:client_fork] = enable_fork

        stub_const("Chef::Client::STDOUT_FD", stdout)
        stub_const("Chef::Client::STDERR_FD", stderr)

        stub_for_register
        stub_for_node_load
        stub_for_sync_cookbooks
        stub_for_converge
        stub_for_node_save
        stub_for_run
      end

      it "runs ohai, sets up authentication, loads node state, synchronizes policy, and converges" do
        # This is what we're testing.
        client.run

        # fork is stubbed, so we can see the outcome of the run
        node.automatic_attrs[:platform].should == "example-platform"
        node.automatic_attrs[:platform_version].should == "example-platform-1.0"
      end
    end


    describe "when running chef-client without fork" do

      include_examples "a successful client run"
    end

    describe "when running chef-client with forking enabled", :unix_only do
      include_examples "a successful client run" do
        let(:process_status) do
          double("Process::Status")
        end

        let(:enable_fork) { true }

        before do
          Process.should_receive(:waitpid2).and_return([1, process_status])

          process_status.should_receive(:success?).and_return(true)
          client.should_receive(:exit).and_return(nil)
          client.should_receive(:fork).and_yield
        end
      end

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
            Chef::RunContext::CookbookCompiler.any_instance.should_receive(:compile)
          end

          def stub_for_sync_cookbooks
            # --Client#setup_run_context
            # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
            #
            Chef::CookbookSynchronizer.any_instance.should_receive(:sync_cookbooks)
            Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
            http_cookbook_sync.should_receive(:post).
              with("environments/_default/cookbook_versions", {:run_list => ["override_recipe"]}).
              and_return({})
          end

          def stub_for_node_save
            # Expect NO node save
            node.should_not_receive(:save)
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
          Chef::CookbookSynchronizer.any_instance.should_receive(:sync_cookbooks)
          Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(http_cookbook_sync)
          http_cookbook_sync.should_receive(:post).
            with("environments/_default/cookbook_versions", {:run_list => ["new_run_list_recipe"]}).
            and_return({})
        end

        before do
          # Client will try to compile and run the new_run_list_recipe, but we
          # do not create a fixture for this.
          Chef::RunContext::CookbookCompiler.any_instance.should_receive(:compile)
        end

        it "sets the new run list on the node" do
          client.run
          node.run_list.should == Chef::RunList.new(new_runlist)
        end

      end
    end

  end


  describe "when handling run failures" do

    it "should remove the run_lock on failure of #load_node" do
      @run_lock = double("Chef::RunLock", :acquire => true)
      Chef::RunLock.stub(:new).and_return(@run_lock)

      @events = double("Chef::EventDispatch::Dispatcher").as_null_object
      Chef::EventDispatch::Dispatcher.stub(:new).and_return(@events)

      # @events is created on Chef::Client.new, so we need to recreate it after mocking
      client = Chef::Client.new
      client.stub(:load_node).and_raise(Exception)
      @run_lock.should_receive(:release)
      if(Chef::Config[:client_fork] && !windows?)
        client.should_receive(:fork) do |&block|
          block.call
        end
      end
      lambda { client.run }.should raise_error(Exception)
    end
  end

  describe "when notifying other objects of the status of the chef run" do
    before do
      Chef::Client.clear_notifications
      Chef::Node.stub(:find_or_create).and_return(node)
      node.stub(:save)
      client.load_node
      client.build_node
    end

    it "notifies observers that the run has started" do
      notified = false
      Chef::Client.when_run_starts do |run_status|
        run_status.node.should == node
        notified = true
      end

      client.run_started
      notified.should be_true
    end

    it "notifies observers that the run has completed successfully" do
      notified = false
      Chef::Client.when_run_completes_successfully do |run_status|
        run_status.node.should == node
        notified = true
      end

      client.run_completed_successfully
      notified.should be_true
    end

    it "notifies observers that the run failed" do
      notified = false
      Chef::Client.when_run_fails do |run_status|
        run_status.node.should == node
        notified = true
      end

      client.run_failed
      notified.should be_true
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
      mock_chef_rest.should_receive(:get_rest).with("roles/role_containing_cookbook1").and_return(role_containing_cookbook1)
      Chef::REST.should_receive(:new).and_return(mock_chef_rest)

      # check pre-conditions.
      node[:roles].should be_nil
      node[:recipes].should be_nil

      client.policy_builder.stub(:node).and_return(node)

      # chefspec and possibly others use the return value of this method
      client.build_node.should == node

      # check post-conditions.
      node[:roles].should_not be_nil
      node[:roles].length.should == 1
      node[:roles].should include("role_containing_cookbook1")
      node[:recipes].should_not be_nil
      node[:recipes].length.should == 1
      node[:recipes].should include("cookbook1")
    end
  end

  describe "windows_admin_check" do
    context "platform is not windows" do
      before do
        Chef::Platform.stub(:windows?).and_return(false)
      end

      it "shouldn't be called" do
        client.should_not_receive(:has_admin_privileges?)
        client.do_windows_admin_check
      end
    end

    context "platform is windows" do
      before do
        Chef::Platform.stub(:windows?).and_return(true)
      end

      it "should be called" do
        client.should_receive(:has_admin_privileges?)
        client.do_windows_admin_check
      end

      context "admin privileges exist" do
        before do
          client.should_receive(:has_admin_privileges?).and_return(true)
        end

        it "should not log a warning message" do
          Chef::Log.should_not_receive(:warn)
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
          client.should_receive(:has_admin_privileges?).and_return(false)
        end

        it "should log a warning message" do
          Chef::Log.should_receive(:warn)
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

end

