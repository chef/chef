#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"

describe Chef::Application::Client, "reconfigure" do
  let(:app) do
    a = described_class.new
    a.cli_arguments = []
    a
  end

  before do
    allow(Kernel).to receive(:trap).and_return(:ok)
    allow(::File).to receive(:read).with(Chef::Config.platform_specific_path("/etc/chef/client.rb")).and_return("")

    @original_argv = ARGV.dup
    ARGV.clear

    allow(app).to receive(:trap)
    allow(app).to receive(:configure_logging).and_return(true)
    Chef::Config[:interval] = 10

    Chef::Config[:once] = false

    # protect the unit tests against accidental --delete-entire-chef-repo from firing
    # for real during tests.  DO NOT delete this line.
    expect(FileUtils).not_to receive(:rm_rf)
  end

  after do
    ARGV.replace(@original_argv)
  end

  describe "parse cli_arguments" do
    it "should call set_specific_recipes" do
      expect(app).to receive(:set_specific_recipes).and_return(true)
      app.reconfigure
    end

    context "when given a named_run_list" do

      before do
        ARGV.replace( %w{ --named-run-list arglebargle-example } )
        app.reconfigure
      end

      it "sets named_run_list in Chef::Config" do
        expect(Chef::Config[:named_run_list]).to eq("arglebargle-example")
      end

    end
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
        allow(ChefConfig).to receive(:windows?).and_return(false)
      end

      it "should terminate with message" do
        expect(Chef::Application).to receive(:fatal!).with(
"Unforked chef-client interval runs are disabled in Chef 12.
Configuration settings:
  interval  = 600 seconds
Enable chef-client interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options."
        )
        app.reconfigure
      end
    end

    context "when interval is given on windows" do
      before do
        Chef::Config[:interval] = 600
        allow(ChefConfig).to receive(:windows?).and_return(true)
      end

      it "should not terminate" do
        expect(Chef::Application).not_to receive(:fatal!)
        app.reconfigure
      end
    end

    context "when configured to run once" do
      before do
        Chef::Config[:once] = true
        Chef::Config[:interval] = 1000
      end

      it "should reconfigure chef-client" do
        app.reconfigure
        expect(Chef::Config[:interval]).to be_nil
      end
    end
  end

  describe "when in daemonized mode and no interval has been set" do
    before do
      Chef::Config[:daemonize] = true
      Chef::Config[:interval] = nil
    end

    it "should set the interval to 1800" do
      app.reconfigure
      expect(Chef::Config.interval).to eq(1800)
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
      app.reconfigure
      expect(Chef::Config.splay).to be_nil
    end

    it "forces the interval to nil" do
      app.reconfigure
      expect(Chef::Config.interval).to be_nil
    end

  end

  describe "when --no-listen is set" do

    it "configures listen = false" do
      app.config[:listen] = false
      app.reconfigure
      expect(Chef::Config[:listen]).to eq(false)
    end

  end

  describe "when the json_attribs configuration option is specified" do

    let(:json_attribs) { { "a" => "b" } }
    let(:config_fetcher) { double(Chef::ConfigFetcher, :fetch_json => json_attribs) }
    let(:json_source) { "https://foo.com/foo.json" }

    before do
      allow(app).to receive(:configure_chef).and_return(true)
      Chef::Config[:json_attribs] = json_source
      expect(Chef::ConfigFetcher).to receive(:new).with(json_source).
        and_return(config_fetcher)
    end

    it "reads the JSON attributes from the specified source" do
      app.reconfigure
      expect(app.chef_client_json).to eq(json_attribs)
    end
  end

  describe "audit mode" do
    shared_examples "experimental feature" do
      before do
        allow(Chef::Log).to receive(:warn)
      end
    end

    shared_examples "unrecognized setting" do
      it "fatals with a message including the incorrect setting" do
        expect(Chef::Application).to receive(:fatal!).with(/Unrecognized setting #{mode} for audit mode/)
        app.reconfigure
      end
    end

    shared_context "set via config file" do
      before do
        Chef::Config[:audit_mode] = mode
      end
    end

    shared_context "set via command line" do
      before do
        ARGV.replace(["--audit-mode", mode])
      end
    end

    describe "enabled via config file" do
      include_context "set via config file" do
        let(:mode) { :enabled }
        include_examples "experimental feature"
      end
    end

    describe "enabled via command line" do
      include_context "set via command line" do
        let(:mode) { "enabled" }
        include_examples "experimental feature"
      end
    end

    describe "audit_only via config file" do
      include_context "set via config file" do
        let(:mode) { :audit_only }
        include_examples "experimental feature"
      end
    end

    describe "audit-only via command line" do
      include_context "set via command line" do
        let(:mode) { "audit-only" }
        include_examples "experimental feature"
      end
    end

    describe "unrecognized setting via config file" do
      include_context "set via config file" do
        let(:mode) { :derp }
        include_examples "unrecognized setting"
      end
    end

    describe "unrecognized setting via command line" do
      include_context "set via command line" do
        let(:mode) { "derp" }
        include_examples "unrecognized setting"
      end
    end
  end

  describe "when both the pidfile and lockfile opts are set to the same value" do

    before do
      Chef::Config[:pid_file] = "/path/to/file"
      Chef::Config[:lockfile] = "/path/to/file"
    end

    it "should throw an exception" do
      expect { app.reconfigure }.to raise_error(Chef::Exceptions::PIDFileLockfileMatch)
    end
  end

  describe "client.d" do
    before do
      Chef::Config[:client_d_dir] = client_d_dir
    end

    context "when client_d_dir is set to nil" do
      let(:client_d_dir) { nil }

      it "does not raise an exception" do
        expect { app.reconfigure }.not_to raise_error
      end
    end

    context "when client_d_dir is set to a directory with configuration" do
      # We're not going to mock out globbing the directory. We want to
      # make sure that we are correctly globbing.
      let(:client_d_dir) { Chef::Util::PathHelper.cleanpath(
        File.join(File.dirname(__FILE__), "../../data/client.d_00")) }

      it "loads the configuration in order" do

        expect(::File).to receive(:read).with(Chef::Config.platform_specific_path("#{client_d_dir}/00-foo.rb")).and_return("")
        expect(::File).to receive(:read).with(Chef::Config.platform_specific_path("#{client_d_dir}/01-bar.rb")).and_return("")
        expect(app).to receive(:load_config_d_file).with("#{client_d_dir}/00-foo.rb").and_call_original.ordered
        expect(app).to receive(:load_config_d_file).with("#{client_d_dir}/01-bar.rb").and_call_original.ordered
        app.reconfigure
      end
    end

    context "when client_d_dir is set to a directory without configuration" do
      let(:client_d_dir) { Chef::Util::PathHelper.cleanpath(
        File.join(File.dirname(__FILE__), "../../data/client.d_01")) }

      # client.d_01 has a nested folder with a rb file that if
      # executed, would raise an exception. If it is executed,
      # it means we are loading configs that are deeply nested
      # inside of client.d. For example, client.d/foo/bar.rb
      # should not run, but client.d/foo.rb should.
      it "does not raise an exception" do
        expect { app.reconfigure }.not_to raise_error
      end
    end

    context "when client_d_dir is set to a directory containing a directory named foo.rb" do
      # foo.rb as a directory should be ignored
      let(:client_d_dir) { Chef::Util::PathHelper.cleanpath(
        File.join(File.dirname(__FILE__), "../../data/client.d_02")) }

      it "does not raise an exception" do
        expect { app.reconfigure }.not_to raise_error
      end
    end
  end
end

describe Chef::Application::Client, "setup_application" do
  before do
    @app = Chef::Application::Client.new
    # this is all stuff the reconfigure method needs
    allow(@app).to receive(:configure_opt_parser).and_return(true)
    allow(@app).to receive(:configure_chef).and_return(true)
    allow(@app).to receive(:configure_logging).and_return(true)
  end

  it "should change privileges" do
    expect(Chef::Daemon).to receive(:change_privilege).and_return(true)
    @app.setup_application
  end
  after do
    Chef::Config[:solo] = false
  end
end

describe Chef::Application::Client, "configure_chef" do
  let(:app) { Chef::Application::Client.new }

  before do
    @original_argv = ARGV.dup
    ARGV.clear
    allow(::File).to receive(:read).with(Chef::Config.platform_specific_path("/etc/chef/client.rb")).and_return("")
    app.configure_chef
  end

  after do
    ARGV.replace(@original_argv)
  end

  it "should set the colored output to true by default on windows and true on all other platforms as well" do
    if windows?
      expect(Chef::Config[:color]).to be_truthy
    else
      expect(Chef::Config[:color]).to be_truthy
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
    allow(Chef::Client).to receive(:new).and_return(@client)
    allow(@client).to receive(:run) do
      @pipe[1].puts "started"
      sleep 1
      @pipe[1].puts "finished"
    end
  end

  context "when sent SIGTERM", :volatile_on_solaris do
    context "when converging in forked process" do
      before do
        Chef::Config[:daemonize] = true
        allow(Chef::Daemon).to receive(:daemonize).and_return(true)
      end

      it "should exit hard with exitstatus 3", :volatile do
        pid = fork do
          @app.run_application
        end
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        expect(result.exitstatus).to eq(3)
      end

      it "should allow child to finish converging" do
        pid = fork do
          @app.run_application
        end
        expect(@pipe[0].gets).to eq("started\n")
        Process.kill("TERM", pid)
        Process.wait(pid)
        # The timeout value needs to be large enough for the child process to finish
        expect(IO.select([@pipe[0]], nil, nil, 15)).not_to be_nil
        expect(@pipe[0].gets).to eq("finished\n")
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
        expect(@pipe[0].gets).to eq("started\n")
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        expect(result.exitstatus).to eq(0)
        expect(IO.select([@pipe[0]], nil, nil, 0)).not_to be_nil
        expect(@pipe[0].gets).to eq("finished\n")
      end

      it "should exit hard when sent before converge" do
        pid = fork do
          sleep 3
          @app.run_application
        end
        Process.kill("TERM", pid)
        _pid, result = Process.waitpid2(pid)
        expect(result.exitstatus).to eq(3)
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

      allow(@app).to receive(:run_chef_client) do

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
      allow(@app).to receive(:interval_sleep) do |arg|
        number_of_sleep_calls += 1
        if number_of_sleep_calls > 1
          exit 127
        end
      end
    end

    it "shouldn't sleep when sent USR1" do
      allow(@app).to receive(:interval_sleep).with(0).and_call_original
      pid = fork do
        @app.run_application
      end
      _pid, result = Process.waitpid2(pid)
      expect(result.exitstatus).to eq(0)
    end
  end
end
