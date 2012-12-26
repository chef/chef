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

shared_examples_for Chef::Client do
  before do
    Chef::Log.logger = Logger.new(StringIO.new)

    # Node/Ohai data
    @hostname = "hostname"
    @fqdn = "hostname.example.org"
    Chef::Config[:node_name] = @fqdn
    ohai_data = { :fqdn             => @fqdn,
                  :hostname         => @hostname,
                  :platform         => 'example-platform',
                  :platform_version => 'example-platform-1.0',
                  :data             => {} }
    ohai_data.stub!(:all_plugins).and_return(true)
    ohai_data.stub!(:data).and_return(ohai_data)
    Ohai::System.stub!(:new).and_return(ohai_data)

    @node = Chef::Node.new
    @node.name(@fqdn)
    @node.chef_environment("_default")

    @client = Chef::Client.new
    @client.node = @node
  end

  describe "authentication protocol selection" do
    after do
      Chef::Config[:authentication_protocol_version] = "1.0"
    end

    context "when the node name is <= 90 bytes" do
      it "does not force the authentication protocol to 1.1" do
        Chef::Config[:node_name] = ("f" * 90)
        # ugly that this happens as a side effect of a getter :(
        @client.node_name
        Chef::Config[:authentication_protocol_version].should == "1.0"
      end
    end

    context "when the node name is > 90 bytes" do
      it "sets the authentication protocol to version 1.1" do
        Chef::Config[:node_name] = ("f" * 91)
        # ugly that this happens as a side effect of a getter :(
        @client.node_name
        Chef::Config[:authentication_protocol_version].should == "1.1"
      end
    end
  end

  describe "configuring output formatters" do
    before do
      @original_config = Chef::Config.configuration
    end

    after do
      Chef::Config.configuration.replace(@original_config)
    end
    context "when no formatter has been configured" do
      before do
        Chef::Config.formatters.clear
        @client = Chef::Client.new
      end

      context "and STDOUT is a TTY" do
        before do
          Chef::Config[:force_formatter] = false
          Chef::Config[:force_logger] = false
          STDOUT.stub!(:tty?).and_return(true)
        end

        it "configures the :doc formatter" do
          @client.formatters_for_run.should == [[:doc]]
        end

        context "and force_logger is set" do
          before do
            Chef::Config[:force_logger] = true
          end

          it "configures the :null formatter" do
            Chef::Config[:force_logger].should be_true
            @client.formatters_for_run.should == [[:null]]
          end

        end

      end

      context "and STDOUT is not a TTY" do
        before do
          Chef::Config[:force_formatter] = false
          STDOUT.stub!(:tty?).and_return(false)
        end

        it "configures the :null formatter" do
          @client.formatters_for_run.should == [[:null]]
        end

        context "and force_formatter is set" do
          before do
            Chef::Config[:force_formatter] = true
          end
          it "it configures the :doc formatter" do
            @client.formatters_for_run.should == [[:doc]]
          end
        end
      end

    end

    context "when a formatter is configured" do
      context "with no output path" do
        before do
          Chef::Config.formatters.clear
          @client = Chef::Client.new
          Chef::Config.add_formatter(:min)
        end

        it "does not configure a default formatter" do
          @client.formatters_for_run.should == [[:min, nil]]
        end

        it "configures the formatter for STDOUT/STDERR" do
          configured_formatters = @client.configure_formatters
          min_formatter = configured_formatters[0]
          min_formatter.output.out.should == STDOUT
          min_formatter.output.err.should == STDERR
        end
      end

      context "with an output path" do
        before do
          Chef::Config.formatters.clear
          @client = Chef::Client.new
          @tmpout = Tempfile.open("rspec-for-client-formatter-selection-#{Process.pid}")
          Chef::Config.add_formatter(:min, @tmpout.path)
        end

        after do
          @tmpout.close unless @tmpout.closed?
          @tmpout.unlink
        end

        it "configures the formatter for the file path" do
          configured_formatters = @client.configure_formatters
          min_formatter = configured_formatters[0]
          min_formatter.output.out.path.should == @tmpout.path
          min_formatter.output.err.path.should == @tmpout.path
        end
      end

    end
  end

  describe "run" do

    it "should identify the node and run ohai, then register the client" do
      mock_chef_rest_for_node = mock("Chef::REST (node)")
      mock_chef_rest_for_client = mock("Chef::REST (client)")
      mock_chef_rest_for_node_save = mock("Chef::REST (node save)")
      mock_chef_runner = mock("Chef::Runner")

      # --Client.register
      #   Make sure Client#register thinks the client key doesn't
      #   exist, so it tries to register and create one.
      File.should_receive(:exists?).with(Chef::Config[:client_key]).exactly(1).times.and_return(false)

      #   Client.register will register with the validation client name.
      Chef::ApiClient::Registration.any_instance.should_receive(:run)
      #   Client.register will then turn around create another
      #   Chef::REST object, this time with the client key it got from the
      #   previous step.
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url], @fqdn, Chef::Config[:client_key]).exactly(1).and_return(mock_chef_rest_for_node)

      # --Client#build_node
      #   looks up the node, which we will return, then later saves it.
      Chef::Node.should_receive(:find_or_create).with(@fqdn).and_return(@node)

      # --ResourceReporter#node_load_completed
      #   gets a run id from the server for storing resource history
      #   (has its own tests, so stubbing it here.)
      Chef::ResourceReporter.any_instance.should_receive(:node_load_completed)

      # --ResourceReporter#run_completed
      #   updates the server with the resource history
      #   (has its own tests, so stubbing it here.)
      Chef::ResourceReporter.any_instance.should_receive(:run_completed)
      # --Client#setup_run_context
      # ---Client#sync_cookbooks -- downloads the list of cookbooks to sync
      #
      Chef::CookbookSynchronizer.any_instance.should_receive(:sync_cookbooks)
      mock_chef_rest_for_node.should_receive(:post_rest).with("environments/_default/cookbook_versions", {:run_list => []}).and_return({})

      # --Client#converge
      Chef::Runner.should_receive(:new).and_return(mock_chef_runner)
      mock_chef_runner.should_receive(:converge).and_return(true)

      # --Client#save_updated_node
      Chef::REST.should_receive(:new).with(Chef::Config[:chef_server_url]).and_return(mock_chef_rest_for_node_save)
      mock_chef_rest_for_node_save.should_receive(:put_rest).with("nodes/#{@fqdn}", @node).and_return(true)

      Chef::RunLock.any_instance.should_receive(:acquire)
      Chef::RunLock.any_instance.should_receive(:release)

      # Post conditions: check that node has been filled in correctly
      @client.should_receive(:run_started)
      @client.should_receive(:run_completed_successfully)

      if(Chef::Config[:client_fork])
        require 'stringio'
        if(Chef::Config[:pipe_node])
          pipe_sim = StringIO.new
          pipe_sim.should_receive(:close).exactly(4).and_return(nil)
          res = ''
          pipe_sim.should_receive(:puts) do |string|
            res.replace(string)
          end
          pipe_sim.should_receive(:gets).and_return(res)
          IO.should_receive(:pipe).and_return([pipe_sim, pipe_sim])
          IO.should_receive(:select).and_return(true)
        end
        proc_ret = Class.new.new
        proc_ret.should_receive(:success?).and_return(true)
        Process.should_receive(:waitpid2).and_return([1, proc_ret])
        @client.should_receive(:exit).and_return(nil)
        @client.should_receive(:fork) do |&block|
          block.call
        end
      end

      # This is what we're testing.
      @client.run

      if(!Chef::Config[:client_fork] || Chef::Config[:pipe_node])
        @node.automatic_attrs[:platform].should == "example-platform"
        @node.automatic_attrs[:platform_version].should == "example-platform-1.0"
      end
    end

    describe "when notifying other objects of the status of the chef run" do
      before do
        Chef::Client.clear_notifications
        Chef::Node.stub!(:find_or_create).and_return(@node)
        @node.stub!(:save)
        @client.build_node
      end

      it "notifies observers that the run has started" do
        notified = false
        Chef::Client.when_run_starts do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_started
        notified.should be_true
      end

      it "notifies observers that the run has completed successfully" do
        notified = false
        Chef::Client.when_run_completes_successfully do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_completed_successfully
        notified.should be_true
      end

      it "notifies observers that the run failed" do
        notified = false
        Chef::Client.when_run_fails do |run_status|
          run_status.node.should == @node
          notified = true
        end

        @client.run_failed
        notified.should be_true
      end
    end
  end

  describe "build_node" do
    it "should expand the roles and recipes for the node" do
      @node.run_list << "role[role_containing_cookbook1]"
      role_containing_cookbook1 = Chef::Role.new
      role_containing_cookbook1.name("role_containing_cookbook1")
      role_containing_cookbook1.run_list << "cookbook1"

      # build_node will call Node#expand! with server, which will
      # eventually hit the server to expand the included role.
      mock_chef_rest = mock("Chef::REST")
      mock_chef_rest.should_receive(:get_rest).with("roles/role_containing_cookbook1").and_return(role_containing_cookbook1)
      Chef::REST.should_receive(:new).and_return(mock_chef_rest)

      # check pre-conditions.
      @node[:roles].should be_nil
      @node[:recipes].should be_nil

      @client.build_node

      # check post-conditions.
      @node[:roles].should_not be_nil
      @node[:roles].length.should == 1
      @node[:roles].should include("role_containing_cookbook1")
      @node[:recipes].should_not be_nil
      @node[:recipes].length.should == 1
      @node[:recipes].should include("cookbook1")
    end
  end

  describe "when a run list override is provided" do
    before do
      @node = Chef::Node.new
      @node.name(@fqdn)
      @node.chef_environment("_default")
      @node.automatic_attrs[:platform] = "example-platform"
      @node.automatic_attrs[:platform_version] = "example-platform-1.0"
    end

    it "should permit spaces in overriding run list" do
      @client = Chef::Client.new(nil, :override_runlist => 'role[a], role[b]')
    end

    it "should override the run list and save original runlist" do
      @client = Chef::Client.new(nil, :override_runlist => 'role[test_role]')
      @client.node = @node

      @node.run_list << "role[role_containing_cookbook1]"

      override_role = Chef::Role.new
      override_role.name 'test_role'
      override_role.run_list << 'cookbook1'

      original_runlist = @node.run_list.dup

      mock_chef_rest = mock("Chef::REST")
      mock_chef_rest.should_receive(:get_rest).with("roles/test_role").and_return(override_role)
      Chef::REST.should_receive(:new).and_return(mock_chef_rest)

      @node.should_receive(:save).and_return(nil)

      @client.build_node

      @node[:roles].should_not be_nil
      @node[:roles].should eql(['test_role'])
      @node[:recipes].should eql(['cookbook1'])

      @client.save_updated_node

      @node.run_list.should == original_runlist

    end
  end

end

describe Chef::Client do
  it_behaves_like Chef::Client
end

describe "Chef::Client Forked" do
  before do
    @original_config = Chef::Config.configuration
    Chef::Config[:client_fork] = true
  end

  after do
    Chef::Config.configuration.replace(@original_config)
  end

  it_behaves_like Chef::Client

end
