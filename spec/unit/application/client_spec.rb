
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

shared_context "with signal handlers" do
  before do
    Chef::Config[:specific_recipes] = [] # normally gets set in @app.reconfigure

    @app = Chef::Application::Client.new
    @app.setup_signal_handlers
    # Default logger doesn't work correctly when logging from a trap handler.
    @app.configure_logging
  end
end

shared_context "with interval_sleep" do
  before do
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
end

describe Chef::Application::Client, "reconfigure" do
  let(:app) do
    a = described_class.new
    a.cli_arguments = []
    a
  end

  before do
    Chef::Config.reset

    allow(Kernel).to receive(:trap).and_return(:ok)
    allow(::File).to receive(:read).and_call_original
    allow(::File).to receive(:read).with(Chef::Config.platform_specific_path("/etc/chef/client.rb")).and_return("")

    @original_argv = ARGV.dup
    ARGV.clear

    allow(app).to receive(:trap)
    allow(app).to receive(:configure_logging).and_return(true)

    Chef::Config[:once] = false

    # protect the unit tests against accidental --delete-entire-chef-repo from firing
    # for real during tests.  DO NOT delete this line.
    allow(FileUtils).to receive(:rm_rf)
  end

  after do
    ARGV.replace(@original_argv)
  end

  describe "parse cli_arguments" do
    it "should call set_specific_recipes" do
      expect(app).to receive(:set_specific_recipes).and_return(true)
      app.reconfigure
    end

    shared_examples "sets the configuration" do |cli_arguments, expected_config|
      describe cli_arguments do
        before do
          cli_arguments ||= ""
          ARGV.replace(cli_arguments.split)
          app.reconfigure
        end

        it "sets #{expected_config}" do
          expect(Chef::Config.configuration).to include expected_config
        end
      end
    end

    describe "--named-run-list" do
      it_behaves_like "sets the configuration",
        "--named-run-list arglebargle-example",
        named_run_list: "arglebargle-example"
    end

    describe "--no-listen" do
      it_behaves_like "sets the configuration", "--no-listen", listen: false
    end

    describe "--daemonize", :unix_only do
      context "with no value" do
        it_behaves_like "sets the configuration", "--daemonize",
          daemonize: true
      end

      context "with an integer value" do
        it_behaves_like "sets the configuration", "--daemonize 5",
          daemonize: 5
      end

      context "with a non-integer value" do
        it_behaves_like "sets the configuration", "--daemonize foo",
          daemonize: true
      end
    end

    describe "--[no]-fork" do
      before do
        Chef::Config[:interval] = nil # FIXME: we're overriding the before block setting this
      end

      context "by default" do
        it_behaves_like "sets the configuration", "", client_fork: false
      end

      context "with --fork" do
        it_behaves_like "sets the configuration", "--fork", client_fork: true
      end

      context "with --no-fork" do
        it_behaves_like "sets the configuration", "--no-fork", client_fork: false
      end

      context "with an interval", :unix_only do
        it_behaves_like "sets the configuration", "--interval 1800", client_fork: true
      end

      context "with once" do
        it_behaves_like "sets the configuration", "--once", client_fork: false
      end

      context "with daemonize", :unix_only do
        it_behaves_like "sets the configuration", "--daemonize", client_fork: true
      end
    end

    describe "--config-option" do
      context "with a single value" do
        it_behaves_like "sets the configuration", "--config-option chef_server_url=http://example",
          chef_server_url: "http://example"
      end

      context "with two values" do
        it_behaves_like "sets the configuration", "--config-option chef_server_url=http://example --config-option policy_name=web",
          chef_server_url: "http://example", policy_name: "web"
      end

      context "with a boolean value" do
        it_behaves_like "sets the configuration", "--config-option minimal_ohai=true",
          minimal_ohai: true
      end

      context "with an empty value" do
        it "should terminate with message" do
          expect(Chef::Application).to receive(:fatal!).with('Unparsable config option ""', ChefConfig::ConfigurationError.new).and_raise("so ded")
          ARGV.replace(["--config-option", ""])
          expect { app.reconfigure }.to raise_error "so ded"
        end
      end

      context "with an invalid value" do
        it "should terminate with message" do
          expect(Chef::Application).to receive(:fatal!).with('Unparsable config option "asdf"', ChefConfig::ConfigurationError.new).and_raise("so ded")
          ARGV.replace(["--config-option", "asdf"])
          expect { app.reconfigure }.to raise_error "so ded"
        end
      end
    end

    describe "--recipe-url and --local-mode" do
      let(:archive) { double }
      let(:config_exists) { false }

      before do
        allow(Chef::Config).to receive(:chef_repo_path).and_return("the_path_to_the_repo")
        allow(FileUtils).to receive(:rm_rf)
        allow(FileUtils).to receive(:mkdir_p)
        allow(app).to receive(:fetch_recipe_tarball)
        allow(Mixlib::Archive).to receive(:new).and_return(archive)
        allow(archive).to receive(:extract)
        allow(Chef::Config).to receive(:from_string)
        allow(IO).to receive(:read).with(File.join("the_path_to_the_repo", ".chef/config.rb")).and_return("new_config")
        allow(File).to receive(:file?).with(File.join("the_path_to_the_repo", ".chef/config.rb")).and_return(config_exists)
      end

      context "local mode not set" do
        it "fails with a message stating local mode required" do
          expect(Chef::Application).to receive(:fatal!).with("recipe-url can be used only in local-mode").and_raise("error occured")
          ARGV.replace(["--recipe-url=test_url"])
          expect { app.reconfigure }.to raise_error "error occured"
        end
      end

      context "local mode set" do
        before do
          ARGV.replace(["--local-mode", "--recipe-url=test_url"])
        end

        context "--delete-entire-chef-repo" do
          before do
            ARGV.replace(["--local-mode", "--recipe-url=test_url", "--delete-entire-chef-repo"])
          end

          it "deletes the repo" do
            expect(FileUtils).to receive(:rm_rf)
              .with("the_path_to_the_repo", secure: true)

            app.reconfigure
          end
        end

        it "does not delete the repo" do
          expect(FileUtils).not_to receive(:rm_rf)

          app.reconfigure
        end

        it "sets { recipe_url: 'test_url' }" do
          app.reconfigure

          expect(Chef::Config.configuration).to include recipe_url: "test_url"
        end

        it "makes the repo path" do
          expect(FileUtils).to receive(:mkdir_p)
            .with("the_path_to_the_repo")

          app.reconfigure
        end

        it "fetches the tarball" do
          expect(app).to receive(:fetch_recipe_tarball)
            .with("test_url", File.join("the_path_to_the_repo", "recipes.tgz"))

          app.reconfigure
        end

        it "extracts the archive" do
          expect(Mixlib::Archive).to receive(:new)
            .with(File.join("the_path_to_the_repo", "recipes.tgz"))
            .and_return(archive)

          expect(archive).to receive(:extract)
            .with("the_path_to_the_repo", perms: false, ignore: /^\.$/)

          app.reconfigure
        end

        context "when there is new config" do
          let(:config_exists) { true }

          it "updates the config from the extracted config" do
            expect(Chef::Config).to receive(:from_string)
              .with(
                "new_config",
                File.join("the_path_to_the_repo", ".chef/config.rb")
              )

            app.reconfigure
          end
        end

        context "when there is no new config" do
          let(:config_exists) { false }

          it "does not update the config" do
            expect(Chef::Config).not_to receive(:from_string)
              .with(
                "new_config",
                File.join("the_path_to_the_repo", ".chef/config.rb")
              )

            app.reconfigure
          end
        end
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

    it "should terminate with message when interval is given" do
      Chef::Config[:interval] = 600
      allow(ChefUtils).to receive(:windows?).and_return(false)
      expect(Chef::Application).to receive(:fatal!).with(
        /Unforked .* interval runs are disabled by default\.
Configuration settings:
  interval  = 600 seconds
Enable .* interval runs by setting `:client_fork = true` in your config file or adding `--fork` to your command line options\./
      )
      app.reconfigure
    end

    context "when interval is given on windows" do
      before do
        Chef::Config[:interval] = 600
        allow(ChefUtils).to receive(:windows?).and_return(true)
      end

      it "should terminate" do
        expect(Chef::Application).to receive(:fatal!)
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

  describe "daemonized mode", :unix_only do
    let(:daemonize) { true }

    before do
      Chef::Config[:daemonize] = daemonize
      allow(Chef::Daemon).to receive(:daemonize)
    end

    context "when no interval has been set" do
      before do
        Chef::Config[:interval] = nil
      end

      it "should set the interval to 1800" do
        app.reconfigure
        expect(Chef::Config.interval).to eq(1800)
      end
    end

    context "when the daemonize option is an integer" do
      include_context "with signal handlers"
      include_context "with interval_sleep"
      include_context "license server stubs"

      let(:wait_secs) { 1 }
      let(:daemonize) { wait_secs }

      before do
        allow(@app).to receive(:interval_sleep).with(wait_secs).and_return true
        allow(@app).to receive(:interval_sleep).with(0).and_call_original
        allow(@app).to receive(:time_to_sleep).and_return(1)
      end

      it "sleeps for the amount of time passed" do
        pid = fork do
          expect(@app).to receive(:interval_sleep).with(wait_secs)
          @app.run_application
        end
        _pid, result = Process.waitpid2(pid)

        expect(result.exitstatus).to eq 0
      end
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

  describe "when the json_attribs configuration option is specified" do

    let(:json_attribs) { { "a" => "b" } }
    let(:config_fetcher) { double(Chef::ConfigFetcher, fetch_json: json_attribs) }
    let(:json_source) { "https://foo.com/foo.json" }

    before do
      allow(app).to receive(:configure_chef).and_return(true)
      Chef::Config[:json_attribs] = json_source
      expect(Chef::ConfigFetcher).to receive(:new).with(json_source)
        .and_return(config_fetcher)
    end

    it "reads the JSON attributes from the specified source" do
      app.reconfigure
      expect(app.chef_client_json).to eq(json_attribs)
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

  it_behaves_like "an application that loads a dot d" do
    let(:dot_d_config_name) { :client_d_dir }
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
    allow(::File).to receive(:read).and_call_original
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
  include_context "with signal handlers"
  include_context "license server stubs"
  before(:each) do
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
    end
  end

  describe "when splay is set" do
    include_context "with interval_sleep"

    before do
      Chef::Config[:splay] = 10
      Chef::Config[:interval] = 10
    end

    it "shouldn't sleep when sent USR1" do
      allow(@app).to receive(:interval_sleep).and_return true
      allow(@app).to receive(:interval_sleep).with(0).and_call_original
      pid = fork do
        @app.run_application
      end
      _pid, result = Process.waitpid2(pid)
      expect(result.exitstatus).to eq(0)
    end
  end
end
