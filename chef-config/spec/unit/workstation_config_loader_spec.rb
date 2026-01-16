#
# Author:: Daniel DeLeo (<dan@chef.io>)
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
#

require "spec_helper"
require "tempfile" unless defined?(Tempfile)

require "chef-config/exceptions"
require "chef-utils"
require "chef-config/workstation_config_loader"

RSpec.describe ChefConfig::WorkstationConfigLoader do

  let(:explicit_config_location) { nil }

  let(:env) { {} }

  let(:config_loader) do
    described_class.new(explicit_config_location).tap do |c|
      allow(c).to receive(:env).and_return(env)
    end
  end

  before do
    # We set this to nil so that a dev workstation will
    # not interfere with the tests.
    ChefConfig::Config.reset
    ChefConfig::Config[:config_d_dir] = nil
  end

  # Test methods that do I/O or reference external state which are stubbed out
  # elsewhere.
  describe "external dependencies" do
    let(:config_loader) { described_class.new(nil) }

    it "delegates to ENV for env" do
      expect(config_loader.env).to equal(ENV)
    end

    it "tests a path's existence" do
      expect(config_loader.path_exists?("/nope/nope/nope/nope/slab/jab/nab")).to be(false)
      expect(config_loader.path_exists?(__FILE__)).to be(true)
    end

  end

  describe "locating the config file" do
    context "without an explicit config" do

      before do
        allow(config_loader).to receive(:path_exists?).with(an_instance_of(String)).and_return(false)
      end

      it "has no config if HOME is not set" do
        expect(config_loader.config_location).to be(nil)
        expect(config_loader.no_config_found?).to be(true)
      end

      context "when HOME is set and contains a knife.rb" do

        let(:home) { "/Users/example.user" }

        before do
          allow(ChefConfig::PathHelper).to receive(:home).with(".chef").and_yield(File.join(home, ".chef"))
          allow(config_loader).to receive(:path_exists?).with("#{home}/.chef/knife.rb").and_return(true)
        end

        it "uses the config in HOME/.chef/knife.rb" do
          expect(config_loader.config_location).to eq("#{home}/.chef/knife.rb")
        end

        context "and has a config.rb" do

          before do
            allow(config_loader).to receive(:path_exists?).with("#{home}/.chef/config.rb").and_return(true)
          end

          it "uses the config in HOME/.chef/config.rb" do
            expect(config_loader.config_location).to eq("#{home}/.chef/config.rb")
          end

          context "and/or a parent dir contains a .chef dir" do

            let(:env_pwd) { "/path/to/cwd" }

            before do
              if ChefUtils.windows?
                env["CD"] = env_pwd
              else
                env["PWD"] = env_pwd
              end

              allow(config_loader).to receive(:path_exists?).with("#{env_pwd}/.chef/knife.rb").and_return(true)
              allow(File).to receive(:exist?).with("#{env_pwd}/.chef").and_return(true)
              allow(File).to receive(:directory?).with("#{env_pwd}/.chef").and_return(true)
            end

            it "prefers the config from parent_dir/.chef" do
              expect(config_loader.config_location).to eq("#{env_pwd}/.chef/knife.rb")
            end

            context "and the parent dir's .chef dir has a config.rb" do

              before do
                allow(config_loader).to receive(:path_exists?).with("#{env_pwd}/.chef/config.rb").and_return(true)
              end

              it "prefers the config from parent_dir/.chef" do
                expect(config_loader.config_location).to eq("#{env_pwd}/.chef/config.rb")
              end

              context "and/or the current working directory contains a .chef dir" do

                let(:cwd) { Dir.pwd }

                before do
                  allow(config_loader).to receive(:path_exists?).with("#{cwd}/knife.rb").and_return(true)
                end

                it "prefers a knife.rb located in the cwd" do
                  expect(config_loader.config_location).to eq("#{cwd}/knife.rb")
                end

                context "and the CWD's .chef dir has a config.rb" do

                  before do
                    allow(config_loader).to receive(:path_exists?).with("#{cwd}/config.rb").and_return(true)
                  end

                  it "prefers a config located in the cwd" do
                    expect(config_loader.config_location).to eq("#{cwd}/config.rb")
                  end

                  context "and/or KNIFE_HOME is set" do

                    let(:knife_home) { "/path/to/knife/home" }

                    before do
                      env["KNIFE_HOME"] = knife_home
                      allow(config_loader).to receive(:path_exists?).with("#{knife_home}/knife.rb").and_return(true)
                    end

                    it "prefers a knife located in KNIFE_HOME" do
                      expect(config_loader.config_location).to eq("/path/to/knife/home/knife.rb")
                    end

                    context "and KNIFE_HOME contains a config.rb" do

                      before do
                        env["KNIFE_HOME"] = knife_home
                        allow(config_loader).to receive(:path_exists?).with("#{knife_home}/config.rb").and_return(true)
                      end

                      it "prefers a config.rb located in KNIFE_HOME" do
                        expect(config_loader.config_location).to eq("/path/to/knife/home/config.rb")
                      end

                    end

                  end
                end
              end
            end
          end
        end
      end

      context "when the current working dir is inside a symlinked directory" do
        before do
          # pwd according to your shell is /home/someuser/prod/chef-repo, but
          # chef-repo is a symlink to /home/someuser/codes/chef-repo
          env["CD"] = "/home/someuser/prod/chef-repo" # windows
          env["PWD"] = "/home/someuser/prod/chef-repo" # unix

          allow(Dir).to receive(:pwd).and_return("/home/someuser/codes/chef-repo")
        end

        it "loads the config from the non-dereferenced directory path" do
          expect(File).to receive(:exist?).with("/home/someuser/prod/chef-repo/.chef").and_return(false)
          expect(File).to receive(:exist?).with("/home/someuser/prod/.chef").and_return(true)
          expect(File).to receive(:directory?).with("/home/someuser/prod/.chef").and_return(true)

          expect(config_loader).to receive(:path_exists?).with("/home/someuser/prod/.chef/knife.rb").and_return(true)

          expect(config_loader.config_location).to eq("/home/someuser/prod/.chef/knife.rb")
        end
      end
    end

    context "when given an explicit config to load" do

      let(:explicit_config_location) { "/path/to/explicit/config.rb" }

      it "prefers the explicit config" do
        expect(config_loader.config_location).to eq(explicit_config_location)
      end

    end
  end

  describe "loading the config file" do

    context "when no explicit config is specified and no implicit config is found" do

      before do
        allow(config_loader).to receive(:path_exists?).with(an_instance_of(String)).and_return(false)
      end

      it "skips loading" do
        expect(config_loader.config_location).to be(nil)
        expect(config_loader).not_to receive(:apply_config)
        config_loader.load
      end

    end

    context "when an explicit config is given but it doesn't exist" do

      let(:explicit_config_location) { "/nope/nope/nope/slab/jab/nab" }

      it "raises a configuration error" do
        expect { config_loader.load }.to raise_error(ChefConfig::ConfigurationError)
      end

    end

    context "when the config file exists" do

      let(:config_content) { "" }

      # We need to keep a reference to the tempfile because while #close does
      # not unlink the file, the object being GC'd will.
      let(:tempfile) do
        Tempfile.new("Chef-WorkstationConfigLoader-rspec-test").tap do |t|
          t.print(config_content)
          t.close
        end
      end

      let(:explicit_config_location) do
        tempfile.path
      end

      after { File.unlink(explicit_config_location) if File.exist?(explicit_config_location) }

      context "and is valid" do

        let(:config_content) { "config_file_evaluated(true)" }

        it "loads the config" do
          expect(config_loader).to receive(:apply_config).and_call_original
          config_loader.load
          expect(ChefConfig::Config.config_file_evaluated).to be(true)
        end

        it "sets ChefConfig::Config.config_file" do
          config_loader.load
          expect(ChefConfig::Config.config_file).to eq(explicit_config_location)
        end

        it "loads a default value for node_name" do
          allow(Etc).to receive(:getlogin).and_return("notauser")
          config_loader.load
          expect(ChefConfig::Config.node_name).to eq("notauser")
        end

        context "with a user.pem" do
          before do
            allow(Etc).to receive(:getlogin).and_return("notauser")
            allow(FileTest).to receive(:exist?).and_call_original
            allow(FileTest).to receive(:exist?).with(File.expand_path("../notauser.pem", explicit_config_location)).and_return(false)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../user.pem", explicit_config_location)).and_return(true)
          end

          it "loads a default value for client_key" do
            config_loader.load
            expect(ChefConfig::Config.client_key).to eq(File.expand_path("../user.pem", explicit_config_location))
          end
        end

        context "with a notauser.pem" do
          before do
            allow(Etc).to receive(:getlogin).and_return("notauser")
            allow(FileTest).to receive(:exist?).and_call_original
            allow(FileTest).to receive(:exist?).with(File.expand_path("../notauser.pem", explicit_config_location)).and_return(true)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../user.pem", explicit_config_location)).and_return(false)
          end

          it "loads a default value for client_key" do
            config_loader.load
            expect(ChefConfig::Config.client_key).to eq(File.expand_path("../notauser.pem", explicit_config_location))
          end
        end

        context "with a valclient.pem" do
          before do
            ChefConfig::Config.validation_client_name = "valclient"
            allow(FileTest).to receive(:exist?).and_call_original
            allow(FileTest).to receive(:exist?).with(File.expand_path("../valclient.pem", explicit_config_location)).and_return(true)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../validator.pem", explicit_config_location)).and_return(false)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../validation.pem", explicit_config_location)).and_return(false)
          end

          it "loads a default value for validation_key" do
            config_loader.load
            expect(ChefConfig::Config.validation_key).to eq(File.expand_path("../valclient.pem", explicit_config_location))
          end
        end

        context "with a validator.pem" do
          before do
            ChefConfig::Config.validation_client_name = "valclient"
            allow(FileTest).to receive(:exist?).and_call_original
            allow(FileTest).to receive(:exist?).with(File.expand_path("../valclient.pem", explicit_config_location)).and_return(false)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../validator.pem", explicit_config_location)).and_return(true)
            allow(FileTest).to receive(:exist?).with(File.expand_path("../validation.pem", explicit_config_location)).and_return(false)
          end

          it "loads a default value for validation_key" do
            config_loader.load
            expect(ChefConfig::Config.validation_key).to eq(File.expand_path("../validator.pem", explicit_config_location))
          end
        end
      end

      context "and has a syntax error" do

        let(:config_content) { "{{{{{:{{" }

        it "raises a ConfigurationError" do
          expect { config_loader.load }.to raise_error(ChefConfig::ConfigurationError)
        end
      end

      context "and raises a ruby exception during evaluation" do

        let(:config_content) { ":foo\n:bar\nraise 'oops'\n:baz\n" }

        it "raises a ConfigurationError" do
          expect { config_loader.load }.to raise_error(ChefConfig::ConfigurationError)
        end
      end

    end

  end

  describe "when loading config.d" do
    context "when the conf.d directory exists" do
      let(:config_content) { "" }

      let(:tempdir) { Dir.mktmpdir("chef-workstation-test") }

      let!(:confd_file) do
        Tempfile.new(["Chef-WorkstationConfigLoader-rspec-test", ".rb"], tempdir).tap do |t|
          t.print(config_content)
          t.close
        end
      end

      before do
        ChefConfig::Config[:config_d_dir] = tempdir
        allow(config_loader).to receive(:path_exists?).with(
          an_instance_of(String)
        ).and_return(false)
      end

      after do
        FileUtils.remove_entry_secure tempdir
      end

      context "and is valid" do
        let(:config_content) { "config_d_file_evaluated(true)" }

        it "loads the config" do
          expect(config_loader).to receive(:apply_config).and_call_original
          config_loader.load
          expect(ChefConfig::Config.config_d_file_evaluated).to be(true)
        end
      end

      context "and has a syntax error" do
        let(:config_content) { "{{{{{:{{" }

        it "raises a ConfigurationError" do
          expect { config_loader.load }.to raise_error(ChefConfig::ConfigurationError)
        end
      end

      context "has a non rb file" do
        let(:syntax_error_content) { "{{{{{:{{" }
        let(:config_content) { "config_d_file_evaluated(true)" }

        let!(:not_confd_file) do
          Tempfile.new(["Chef-WorkstationConfigLoader-rspec-test", ".foorb"], tempdir).tap do |t|
            t.print(syntax_error_content)
            t.close
          end
        end

        it "does not load the non rb file" do
          expect { config_loader.load }.not_to raise_error
          expect(ChefConfig::Config.config_d_file_evaluated).to be(true)
        end
      end
    end

    context "when the conf.d directory does not exist" do
      before do
        ChefConfig::Config[:config_d_dir] = "/nope/nope/nope/nope/notdoingit"
      end

      it "does not load anything" do
        expect(config_loader).not_to receive(:apply_config)
      end
    end
  end

  describe "when loading a credentials file" do
    if ChefUtils.windows?
      let(:home) { "C:/Users/example.user" }
    else
      let(:home) { "/Users/example.user" }
    end
    let(:credentials_file) { "#{home}/.chef/credentials" }
    let(:context_file) { "#{home}/.chef/context" }

    before do
      allow(ChefConfig::PathHelper).to receive(:home).with(".chef").and_return(File.join(home, ".chef"))
      allow(ChefConfig::PathHelper).to receive(:home).with(".chef", "credentials").and_return(credentials_file)
      allow(ChefConfig::PathHelper).to receive(:home).with(".chef", "context").and_return(context_file)
      allow(File).to receive(:file?).with(context_file).and_return false
    end

    context "when the file exists" do
      before do
        expect(File).to receive(:read).with(credentials_file, { encoding: "utf-8" }).and_return(content)
        allow(File).to receive(:file?).with(credentials_file).and_return true
      end

      context "and has a default profile" do
        let(:content) do
          content = <<~EOH
            [default]
            node_name = 'barney'
            client_key = "barney_rubble.pem"
            chef_server_url = "https://api.chef.io/organizations/bedrock"
            invalid_config_option1234 = "foobar"
          EOH
          content
        end

        it "applies the expected config" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.chef_server_url).to eq("https://api.chef.io/organizations/bedrock")
          expect(ChefConfig::Config.client_key.to_s).to eq("#{home}/.chef/barney_rubble.pem")
          expect(ChefConfig::Config.profile.to_s).to eq("default")
          expect(ChefConfig::Config[:invalid_config_option1234]).to eq("foobar")
        end
      end

      context "and has a default profile with knife settings" do
        let(:content) do
          content = <<~EOH
            [default]
            node_name = 'barney'
            client_key = "barney_rubble.pem"
            chef_server_url = "https://api.chef.io/organizations/bedrock"
            knife = {
              secret_file = "/home/barney/.chef/encrypted_data_bag_secret.pem"
            }
            [default.knife]
            ssh_user = "knife_ssh_user"
          EOH
          content
        end

        it "applies the expected knife config" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.chef_server_url).to eq("https://api.chef.io/organizations/bedrock")
          expect(ChefConfig::Config.client_key.to_s).to eq("#{home}/.chef/barney_rubble.pem")
          expect(ChefConfig::Config.knife[:ssh_user].to_s).to eq("knife_ssh_user")
          expect(ChefConfig::Config.knife[:secret_file].to_s).to eq("/home/barney/.chef/encrypted_data_bag_secret.pem")
          expect(ChefConfig::Config.profile.to_s).to eq("default")
        end
      end

      context "and has a profile containing a full key" do
        let(:content) do
          content = <<~EOH
            [default]
            client_key = """
            -----BEGIN RSA PRIVATE KEY-----
            foo
            """
          EOH
          content
        end

        it "applies the expected config" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.client_key_contents).to eq(<<~EOH
            -----BEGIN RSA PRIVATE KEY-----
            foo
          EOH
                                                              )
        end
      end

      context "and has several profiles" do
        let(:content) do
          content = <<~EOH
            [default]
            client_name = "default"
            [environment]
            client_name = "environment"
            [explicit]
            client_name = "explicit"
            [context]
            client_name = "context"
          EOH
          content
        end

        let(:env) { {} }
        before do
          stub_const("ENV", env)
        end

        it "selects the correct profile explicitly" do
          expect { config_loader.load_credentials("explicit") }.not_to raise_error
          expect(ChefConfig::Config.node_name).to eq("explicit")
        end

        context "with an environment variable" do
          let(:env) { { "CHEF_PROFILE" => "environment" } }

          it "selects the correct profile" do
            expect { config_loader.load_credentials }.not_to raise_error
            expect(ChefConfig::Config.node_name).to eq("environment")
          end
        end

        it "selects the correct profile with a context file" do
          allow(File).to receive(:file?).with(context_file).and_return true
          expect(File).to receive(:read).with(context_file).and_return "context"
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.node_name).to eq("context")
        end

        it "falls back to the default" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.node_name).to eq("default")
        end
      end

      context "and contains both node_name and client_name" do
        let(:content) do
          content = <<~EOH
            [default]
            node_name = 'barney'
            client_name = 'barney'
          EOH
          content
        end

        it "raises a ConfigurationError" do
          expect { config_loader.load_credentials }.to raise_error(ChefConfig::ConfigurationError)
        end
      end

      context "and ssl_verify_mode is a symbol string" do
        let(:content) do
          content = <<~EOH
            [default]
            ssl_verify_mode = ":verify_none"
          EOH
          content
        end

        it "raises a ConfigurationError" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.ssl_verify_mode).to eq(:verify_none)
        end
      end

      context "and ssl_verify_mode is a string" do
        let(:content) do
          content = <<~EOH
            [default]
            ssl_verify_mode = "verify_none"
          EOH
          content
        end

        it "raises a ConfigurationError" do
          expect { config_loader.load_credentials }.not_to raise_error
          expect(ChefConfig::Config.ssl_verify_mode).to eq(:verify_none)
        end
      end

      context "and has a syntax error" do
        let(:content) { "<<<<<" }

        it "raises a ConfigurationError" do
          expect { config_loader.load_credentials }.to raise_error(ChefConfig::ConfigurationError)
        end
      end
    end

    context "when the file does not exist" do
      it "does not load anything" do
        allow(File).to receive(:file?).with(credentials_file).and_return false
        expect(Tomlrb).not_to receive(:load_file)
        config_loader.load_credentials
      end
    end
  end
end
