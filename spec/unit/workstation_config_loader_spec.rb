#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
require 'tempfile'
require 'chef/workstation_config_loader'

describe Chef::WorkstationConfigLoader do

  let(:explicit_config_location) { nil }

  let(:env) { {} }

  let(:config_loader) do
    described_class.new(explicit_config_location).tap do |c|
      allow(c).to receive(:env).and_return(env)
    end
  end

  # Test methods that do I/O or reference external state which are stubbed out
  # elsewhere.
  describe "external dependencies" do
    let(:config_loader) { described_class.new(nil) }

    it "delegates to ENV for env" do
      expect(config_loader.env).to equal(ENV)
    end

    it "tests a path's existence" do
      expect(config_loader.path_exists?('/nope/nope/nope/nope/frab/jab/nab')).to be(false)
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
          env["HOME"] = home
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
              if Chef::Platform.windows?
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

    context "when no explicit config is specifed and no implicit config is found" do

      before do
        allow(config_loader).to receive(:path_exists?).with(an_instance_of(String)).and_return(false)
      end

      it "skips loading" do
        expect(config_loader.config_location).to be(nil)
        expect(config_loader.load).to be(false)
      end

    end

    context "when an explicit config is given but it doesn't exist" do

      let(:explicit_config_location) { "/nope/nope/nope/frab/jab/nab" }

      it "raises a configuration error" do
        expect { config_loader.load }.to raise_error(Chef::Exceptions::ConfigurationError)
      end

    end

    context "when the config file exists" do

      let(:config_content) { "" }

      let(:explicit_config_location) do
        # could use described_class, but remove all ':' from the path if so.
        t = Tempfile.new("Chef-WorkstationConfigLoader-rspec-test")
        t.print(config_content)
        t.close
        t.path
      end

      after { File.unlink(explicit_config_location) if File.exists?(explicit_config_location) }

      context "and is valid" do

        let(:config_content) { "config_file_evaluated(true)" }

        it "loads the config" do
          expect(config_loader.load).to be(true)
          expect(Chef::Config.config_file_evaluated).to be(true)
        end

        it "sets Chef::Config.config_file" do
          config_loader.load
          expect(Chef::Config.config_file).to eq(explicit_config_location)
        end
      end

      context "and has a syntax error" do

        let(:config_content) { "{{{{{:{{" }

        it "raises a ConfigurationError" do
          expect { config_loader.load }.to raise_error(Chef::Exceptions::ConfigurationError)
        end
      end

      context "and raises a ruby exception during evaluation" do

        let(:config_content) { ":foo\n:bar\nraise 'oops'\n:baz\n" }

        it "raises a ConfigurationError" do
          expect { config_loader.load }.to raise_error(Chef::Exceptions::ConfigurationError)
        end
      end

    end

  end

end
