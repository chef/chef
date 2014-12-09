#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'spec_helper'

describe Chef::Application::Client, "reconfigure" do
  before do
    Kernel.stub(:trap).and_return(:ok)

    @original_argv = ARGV.dup
    ARGV.clear

    @app = Chef::Application::Client.new
    @app.stub(:trap)
    @app.stub(:configure_opt_parser).and_return(true)
    @app.stub(:configure_chef).and_return(true)
    @app.stub(:configure_logging).and_return(true)
    @app.cli_arguments = []
    Chef::Config[:interval] = 10

    Chef::Config[:once] = false
  end

  after do
    ARGV.replace(@original_argv)
  end

  describe "when configured to not fork the client process" do
    before do
      Chef::Config[:client_fork] = false
      Chef::Config[:daemonize] = false
      Chef::Config[:interval] = nil
      Chef::Config[:splay] = nil
    end

    context "when interval is given" do
      before do
        Chef::Config[:interval] = 600
      end

      it "should terminate with message" do
        Chef::Application.should_receive(:fatal!).with(
"Unforked chef-client interval runs are disabled in Chef 12.
Configuration settings:
  interval  = 600 seconds
Enable chef-client interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
        )
        @app.reconfigure
      end
    end

    context "when interval is given on windows" do
      before do
        Chef::Config[:interval] = 600
        allow(Chef::Platform).to receive(:windows?).and_return(true)
      end

      it "should not terminate" do
        expect(Chef::Application).not_to receive(:fatal!)
        @app.reconfigure
      end
    end

    context "when configured to run once" do
      before do
        Chef::Config[:once] = true
        Chef::Config[:interval] = 1000
      end

      it "should reconfigure chef-client" do
        @app.reconfigure
        Chef::Config[:interval].should be_nil
      end
    end
  end

  describe "when in daemonized mode and no interval has been set" do
    before do
      Chef::Config[:daemonize] = true
      Chef::Config[:interval] = nil
    end

    it "should set the interval to 1800" do
      @app.reconfigure
      Chef::Config.interval.should == 1800
    end
  end

  describe "when configured to run once" do
    before do
      Chef::Config[:once] = true
      Chef::Config[:daemonize] = false
      Chef::Config[:splay] = 60
      Chef::Config[:interval] = 1800
    end

    it "ignores the splay" do
      @app.reconfigure
      Chef::Config.splay.should be_nil
    end

    it "forces the interval to nil" do
      @app.reconfigure
      Chef::Config.interval.should be_nil
    end

  end

  describe "when the json_attribs configuration option is specified" do

    let(:json_attribs) { {"a" => "b"} }
    let(:config_fetcher) { double(Chef::ConfigFetcher, :fetch_json => json_attribs) }
    let(:json_source) { "https://foo.com/foo.json" }

    before do
      Chef::Config[:json_attribs] = json_source
      Chef::ConfigFetcher.should_receive(:new).with(json_source).
        and_return(config_fetcher)
    end

    it "reads the JSON attributes from the specified source" do
      @app.reconfigure
      @app.chef_client_json.should == json_attribs
    end
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    @app = Chef::Application::Client.new
    # this is all stuff the reconfigure method needs
    @app.stub(:configure_opt_parser).and_return(true)
    @app.stub(:configure_chef).and_return(true)
    @app.stub(:configure_logging).and_return(true)
  end

  it "should change privileges" do
    Chef::Daemon.should_receive(:change_privilege).and_return(true)
    @app.setup_application
  end
  after do
    Chef::Config[:solo] = false
  end
end

describe Chef::Application::Client, "configure_chef" do
  before do
    @original_argv = ARGV.dup
    ARGV.clear
    @app = Chef::Application::Client.new
    @app.configure_chef
  end

  after do
    ARGV.replace(@original_argv)
  end

  it "should set the colored output to false by default on windows and true otherwise" do
    if windows?
      Chef::Config[:color].should be_false
    else
      Chef::Config[:color].should be_true
    end
  end
end

describe Chef::Application::Client, "run_application", :unix_only do
  before(:each) do
    Chef::Config[:specific_recipes] = [] # normally gets set in @app.reconfigure

    @app = Chef::Application::Client.new
    @app.setup_signal_handlers
    # Default logger doesn't work correctly when logging from a trap handler.
    @app.configure_logging

    @pipe = IO.pipe
    @client = Chef::Client.new
    Chef::Client.stub(:new).and_return(@client)
    @client.stub(:run) do
      @pipe[1].puts 'started'
      sleep 1
      @pipe[1].puts 'finished'
    end
  end

  context "when sent SIGTERM", :volatile_on_solaris do
    context "when converging in forked process" do
      before do
        Chef::Config[:daemonize] = true
        Chef::Daemon.stub(:daemonize).and_return(true)
      end

      it "should exit hard with exitstatus 3" do
        pid = fork do
          @app.run_application
        end
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        result.exitstatus.should == 3
      end

      it "should allow child to finish converging" do
        pid = fork do
          @app.run_application
        end
        @pipe[0].gets.should == "started\n"
        Process.kill("TERM", pid)
        Process.wait
        sleep 1 # Make sure we give the converging child process enough time to finish
        IO.select([@pipe[0]], nil, nil, 0).should_not be_nil
        @pipe[0].gets.should == "finished\n"
      end
    end

    context "when running unforked" do
      before(:each) do
        Chef::Config[:client_fork] = false
        Chef::Config[:daemonize] = false
      end

      it "should exit gracefully when sent during converge" do
        pid = fork do
          @app.run_application
        end
        @pipe[0].gets.should == "started\n"
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        result.exitstatus.should == 0
        IO.select([@pipe[0]], nil, nil, 0).should_not be_nil
        @pipe[0].gets.should == "finished\n"
      end

      it "should exit hard when sent before converge" do
        pid = fork do
          sleep 3
          @app.run_application
        end
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        result.exitstatus.should == 3
      end
    end
  end

  describe "when splay is set" do
    before do
      Chef::Config[:splay] = 10
      Chef::Config[:interval] = 10

      run_count = 0

      # uncomment to debug failures...
      # Chef::Log.init($stderr)
      # Chef::Log.level = :debug

      @app.stub(:run_chef_client) do

        run_count += 1
        if run_count > 3
          exit 0
        end

        # If everything is fine, sending USR1 to self should prevent
        # app to go into splay sleep forever.
        Process.kill("USR1", Process.pid)
        # On Ruby < 2.1, we need to give the signal handlers a little
        # more time, otherwise the test will fail because interleavings.
        sleep 1
      end

      number_of_sleep_calls = 0

      # This is a very complicated way of writing
      # @app.should_receive(:sleep).once.
      # We have to do it this way because the main loop of
      # Chef::Application::Client swallows most exceptions, and we need to be
      # able to expose our expectation failures to the parent process in the test.
      @app.stub(:interval_sleep) do |arg|
        number_of_sleep_calls += 1
        if number_of_sleep_calls > 1
          exit 127
        end
      end
    end

    it "shouldn't sleep when sent USR1" do
      @app.stub(:interval_sleep).with(0).and_call_original
      pid = fork do
        @app.run_application
      end
      _pid, result = Process.waitpid2(pid)
      result.exitstatus.should == 0
    end
  end
end
