#
# Author:: Ho-Sheng Hsiao (hosh@chef.io)
# Code derived from spec/unit/mixin/command_spec.rb
#
# Original header:
# Author:: Hongli Lai (hongli@phusion.nl)
# Copyright:: Copyright 2009-2016, Phusion
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
require "chef/mixin/path_sanity"

describe Chef::Mixin::ShellOut do
  include Chef::Mixin::PathSanity

  let(:shell_out_class) { Class.new { include Chef::Mixin::ShellOut } }
  subject(:shell_out_obj) { shell_out_class.new }

  def env_path
    if Chef::Platform.windows?
      "Path"
    else
      "PATH"
    end
  end

  context "when testing individual methods" do
    before(:each) do
      @original_env = ENV.to_hash
      ENV.clear
    end

    after(:each) do
      ENV.clear
      ENV.update(@original_env)
    end

    let(:retobj) { instance_double(Mixlib::ShellOut, "error!" => false) }
    let(:cmd) { "echo '#{rand(1000)}'" }

    %i{shell_out shell_out!}.each do |method|
      describe "##{method}" do

        describe "when the last argument is a Hash" do
          describe "and environment is an option" do
            it "should not change environment language settings when they are set to nil" do
              options = { environment: { "LC_ALL" => nil, "LANGUAGE" => nil, "LANG" => nil, env_path => nil } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should not change environment language settings when they are set to non-nil" do
              options = { environment: { "LC_ALL" => "en_US.UTF-8", "LANGUAGE" => "en_US.UTF-8", "LANG" => "en_US.UTF-8", env_path => "foo:bar:baz" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should set environment language settings to the configured internal locale when they are not present" do
              options = { environment: { "HOME" => "/Users/morty" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
                environment: {
                  "HOME" => "/Users/morty",
                  "LC_ALL" => Chef::Config[:internal_locale],
                  "LANG" => Chef::Config[:internal_locale],
                  "LANGUAGE" => Chef::Config[:internal_locale],
                  env_path => sanitized_path,
                },
              }).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should not mutate the options hash when it adds language settings" do
              options = { environment: { "HOME" => "/Users/morty" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
                environment: {
                  "HOME" => "/Users/morty",
                  "LC_ALL" => Chef::Config[:internal_locale],
                  "LANG" => Chef::Config[:internal_locale],
                  "LANGUAGE" => Chef::Config[:internal_locale],
                  env_path => sanitized_path,
                },
              }).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
              expect(options[:environment].key?("LC_ALL")).to be false
            end
          end

          describe "and env is an option" do
            it "should not change env when langauge options are set to nil" do
              options = { env: { "LC_ALL" => nil, "LANG" => nil, "LANGUAGE" => nil, env_path => nil } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should not change env when language options are set to non-nil" do
              options = { env: { "LC_ALL" => "de_DE.UTF-8", "LANG" => "de_DE.UTF-8", "LANGUAGE" => "de_DE.UTF-8", env_path => "foo:bar:baz" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should set environment language settings to the configured internal locale when they are not present" do
              options = { env: { "HOME" => "/Users/morty" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
                env: {
                  "HOME" => "/Users/morty",
                  "LC_ALL" => Chef::Config[:internal_locale],
                  "LANG" => Chef::Config[:internal_locale],
                  "LANGUAGE" => Chef::Config[:internal_locale],
                  env_path => sanitized_path,
                },
              }).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end

            it "should not mutate the options hash when it adds language settings" do
              options = { env: { "HOME" => "/Users/morty" } }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
                env: {
                  "HOME" => "/Users/morty",
                  "LC_ALL" => Chef::Config[:internal_locale],
                  "LANG" => Chef::Config[:internal_locale],
                  "LANGUAGE" => Chef::Config[:internal_locale],
                  env_path => sanitized_path,
                },
              }).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
              expect(options[:env].key?("LC_ALL")).to be false
            end
          end

          describe "and no env/environment option is present" do
            it "should set environment language settings to the configured internal locale" do
              options = { user: "morty" }
              expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
                user: "morty",
                environment: {
                  "LC_ALL" => Chef::Config[:internal_locale],
                  "LANG" => Chef::Config[:internal_locale],
                  "LANGUAGE" => Chef::Config[:internal_locale],
                  env_path => sanitized_path,
                },
              }).and_return(retobj)
              shell_out_obj.send(method, cmd, options)
            end
          end
        end

        describe "when the last argument is not a Hash" do
          it "should set environment language settings to the configured internal locale" do
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, {
              environment: {
                "LC_ALL" => Chef::Config[:internal_locale],
                "LANG" => Chef::Config[:internal_locale],
                "LANGUAGE" => Chef::Config[:internal_locale],
                env_path => sanitized_path,
              },
            }).and_return(retobj)
            shell_out_obj.send(method, cmd)
          end
        end
      end
    end

    describe "#shell_out default_env: false" do

      describe "when the last argument is a Hash" do
        describe "and environment is an option" do
          it "should not change environment['LC_ALL'] when set to nil" do
            options = { environment: { "LC_ALL" => nil } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end

          it "should not change environment['LC_ALL'] when set to non-nil" do
            options = { environment: { "LC_ALL" => "en_US.UTF-8" } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end

          it "should no longer set environment['LC_ALL'] to nil when 'LC_ALL' not present" do
            options = { environment: { "HOME" => "/Users/morty" } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end
        end

        describe "and env is an option" do
          it "should not change env when set to nil" do
            options = { env: { "LC_ALL" => nil } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end

          it "should not change env when set to non-nil" do
            options = { env: { "LC_ALL" => "en_US.UTF-8" } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end

          it "should no longer set env['LC_ALL'] to nil when 'LC_ALL' not present" do
            options = { env: { "HOME" => "/Users/morty" } }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end
        end

        describe "and no env/environment option is present" do
          it "should no longer add environment option and set environment['LC_ALL'] to nil" do
            options = { user: "morty" }
            expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out_obj.shell_out(cmd, **options, default_env: false)
          end
        end
      end

      describe "when the last argument is not a Hash" do
        it "should no longer add environment options and set environment['LC_ALL'] to nil" do
          expect(Chef::Mixin::ShellOut).to receive(:shell_out_command).with(cmd).and_return(true)
          shell_out_obj.shell_out(cmd, default_env: false)
        end
      end
    end

    describe "Custom Resource timeouts" do
      class CustomResource < Chef::Resource
        provides :whatever

        property :timeout, Numeric

        action :install do
        end
      end

      let(:new_resource) { CustomResource.new("foo") }
      let(:provider) { new_resource.provider_for_action(:install) }

      describe "on Chef-15", chef: ">= 15" do
        %i{shell_out shell_out!}.each do |method|
          stubbed_method = (method == :shell_out) ? :shell_out_compacted : :shell_out_compacted!
          it "#{method} defaults to 900 seconds" do
            expect(provider).to receive(stubbed_method).with("foo", timeout: 900)
            provider.send(method, "foo")
          end
          it "#{method} overrides the default timeout with its options" do
            expect(provider).to receive(stubbed_method).with("foo", timeout: 1)
            provider.send(method, "foo", timeout: 1)
          end
          it "#{method} overrides the new_resource.timeout with the timeout option" do
            new_resource.timeout(99)
            expect(provider).to receive(stubbed_method).with("foo", timeout: 1)
            provider.send(method, "foo", timeout: 1)
          end
          it "#{method} defaults to 900 seconds and preserves options" do
            expect(provider).to receive(stubbed_method).with("foo", env: nil, timeout: 900)
            provider.send(method, "foo", env: nil)
          end
          it "#{method} overrides the default timeout with its options and preserves options" do
            expect(provider).to receive(stubbed_method).with("foo", timeout: 1, env: nil)
            provider.send(method, "foo", timeout: 1, env: nil)
          end
          it "#{method} overrides the new_resource.timeout with the timeout option and preseves options" do
            new_resource.timeout(99)
            expect(provider).to receive(stubbed_method).with("foo", timeout: 1, env: nil)
            provider.send(method, "foo", timeout: 1, env: nil)
          end
        end
      end
    end

    describe "timeouts" do
      let(:new_resource) { Chef::Resource::Package.new("foo") }
      let(:provider) { new_resource.provider_for_action(:install) }

      %i{shell_out shell_out!}.each do |method|
        stubbed_method = (method == :shell_out) ? :shell_out_compacted : :shell_out_compacted!
        it "#{method} defaults to 900 seconds" do
          expect(provider).to receive(stubbed_method).with("foo", timeout: 900)
          provider.send(method, "foo")
        end
        it "#{method} overrides the default timeout with its options" do
          expect(provider).to receive(stubbed_method).with("foo", timeout: 1)
          provider.send(method, "foo", timeout: 1)
        end
        it "#{method} overrides the new_resource.timeout with the timeout option" do
          new_resource.timeout(99)
          expect(provider).to receive(stubbed_method).with("foo", timeout: 1)
          provider.send(method, "foo", timeout: 1)
        end
        it "#{method} defaults to 900 seconds and preserves options" do
          expect(provider).to receive(stubbed_method).with("foo", env: nil, timeout: 900)
          provider.send(method, "foo", env: nil)
        end
        it "#{method} overrides the default timeout with its options and preserves options" do
          expect(provider).to receive(stubbed_method).with("foo", timeout: 1, env: nil)
          provider.send(method, "foo", timeout: 1, env: nil)
        end
        it "#{method} overrides the new_resource.timeout with the timeout option and preseves options" do
          new_resource.timeout(99)
          expect(provider).to receive(stubbed_method).with("foo", timeout: 1, env: nil)
          provider.send(method, "foo", timeout: 1, env: nil)
        end
      end
    end
  end
end
