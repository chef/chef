#
# Author:: Prajakta Purohit (<prajakta@chef.io>)
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

describe Chef::Provider::Execute do

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:provider) { Chef::Provider::Execute.new(new_resource, run_context) }
  let(:current_resource) { Chef::Resource::Ifconfig.new("foo_resource", run_context) }
  # You will be the same object, I promise.
  @live_stream = Chef::EventDispatch::EventsOutputStream.new(Chef::EventDispatch::Dispatcher.new, name: :execute)

  let(:opts) do
    {
      timeout: 3600,
      returns: 0,
      log_level: :info,
      default_env: false,
      log_tag: new_resource.to_s,
    }
  end

  let(:new_resource) { Chef::Resource::Execute.new("foo_resource", run_context) }

  before do
    allow(Chef::EventDispatch::EventsOutputStream).to receive(:new) { @live_stream }
    allow(ChefUtils).to receive(:windows?) { false }
    Chef::Log.level = :info
    allow(STDOUT).to receive(:tty?).and_return(false)
  end

  describe "#initialize" do
    it "should return a Chef::Provider::Execute provider" do
      expect(provider.class).to eql(Chef::Provider::Execute)
    end
  end

  describe "#load_current_resource" do
    before do
      expect(Chef::Resource::Execute).to receive(:new).with(new_resource.name).and_return(current_resource)
    end

    it "should return the current resource" do
      expect(provider.load_current_resource).to eql(current_resource)
    end

    it "our timeout should default to 3600" do
      provider.load_current_resource
      expect(provider.timeout).to eql(3600)
    end
  end

  describe "#action_run" do
    it "runs shell_out with the default options" do
      expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
      expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    # this next test is tightly coupled to the implementation of the underlying shell_out mixin that we're using
    # but the point is to ensure that we are not picking up the PATH mangling and locale-variable mangling that the internal
    # shell_out API uses.  we are asserting that we emulate `ls -la` when the user does `execute "ls -la"`, and to
    # do that we get dirty and start mocking the implementation of the shell_out mixin itself.  while arguments like
    # "timeout", "returns", "log_level" and "log_tag" appear here, we MUST NOT have an "environment" or "env" argument
    # that we are passing to Mixlib::ShellOut by default -- ever.  you might have to add some other argument here from
    # time to time, but you MUST NOT change the environment.
    it "does not use shell_out in such a way as to insert extra environment variables" do
      mock = instance_double(Mixlib::ShellOut)
      expect(Mixlib::ShellOut).to receive(:new).with("foo_resource", { timeout: 3600, returns: 0, log_level: :info, log_tag: "execute[foo_resource]" }).and_return(mock)
      expect(mock).to receive(:live_stream=).with(nil)
      allow(mock).to receive(:live_stream)
      expect(mock).to receive(:run_command)
      expect(mock).to receive(:error!)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "if you pass a command property, it runs the command" do
      new_resource.command "/usr/argelbargle/bin/oogachacka 12345"
      expect(provider).to receive(:shell_out!).with(new_resource.command, opts)
      expect(provider).to receive(:converge_by).with("execute #{new_resource.command}").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "should honor sensitive property" do
      new_resource.sensitive true
      # Since the resource is sensitive, it should not have :live_stream set
      opts.delete(:live_stream)
      expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
      expect(provider).to receive(:converge_by).with("execute sensitive resource").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "should do nothing if the sentinel file exists" do
      new_resource.creates "/foo_resource"
      expect(FileTest).to receive(:exist?).with(new_resource.creates).and_return(true)
      expect(provider).not_to receive(:shell_out!)
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).not_to be_updated
    end

    describe "when the user specifies a relative path without cwd" do
      before do
        expect(new_resource.cwd).to be_falsey
        new_resource.creates "foo_resource"
      end

      it "should raise if user specified relative path without cwd for Chef-13" do
        expect(provider).not_to receive(:shell_out!)
        expect { provider.run_action(:run) }.to raise_error(Chef::Exceptions::Execute)
      end
    end

    it "should respect cwd options for 'creates'" do
      new_resource.cwd "/tmp"
      new_resource.creates "foo_resource"
      expect(FileTest).not_to receive(:exist?).with(new_resource.creates)
      expect(FileTest).to receive(:exist?).with(File.join("/tmp", new_resource.creates)).and_return(true)
      expect(Chef::Log).not_to receive(:warn)
      expect(provider).not_to receive(:shell_out!)

      provider.run_action(:run)
      expect(new_resource).not_to be_updated
    end

    it "should not include stdout/stderr in failure exception for sensitive resource" do
      opts.delete(:live_stream)
      new_resource.sensitive true
      expect(provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect do
        provider.run_action(:run)
      end.to raise_error(Mixlib::ShellOut::ShellCommandFailed, /suppressed for sensitive resource/)
    end

    describe "streaming output" do
      it "should not set the live_stream if sensitive is on" do
        new_resource.sensitive true
        expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
        expect(provider).to receive(:converge_by).with("execute sensitive resource").and_call_original
        expect(Chef::Log).not_to receive(:warn)
        provider.run_action(:run)
        expect(new_resource).to be_updated
      end

      describe "with an output formatter listening" do
        let(:events) { d = Chef::EventDispatch::Dispatcher.new; d.register(Chef::Formatters::Doc.new(StringIO.new, StringIO.new)); d }

        before do
          Chef::Config[:stream_execute_output] = true
        end

        it "should set the live_stream if the log level is info or above" do
          nopts = opts
          nopts[:live_stream] = @live_stream
          expect(provider).to receive(:shell_out!).with(new_resource.name, nopts)
          expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end

        it "should set the live_stream if the resource requests live streaming" do
          Chef::Log.level = :warn
          new_resource.live_stream true
          nopts = opts
          nopts[:live_stream] = @live_stream
          expect(provider).to receive(:shell_out!).with(new_resource.name, nopts)
          expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end

        it "should not set the live_stream if the resource is sensitive" do
          new_resource.sensitive true
          expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
          expect(provider).to receive(:converge_by).with("execute sensitive resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end
      end

      describe "with only logging enabled" do
        it "should set the live_stream to STDOUT if we are a TTY, not daemonized, not sensitive, and info is enabled" do
          nopts = opts
          nopts[:live_stream] = STDOUT
          allow(STDOUT).to receive(:tty?).and_return(true)
          expect(provider).to receive(:shell_out!).with(new_resource.name, nopts)
          expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end

        it "should not set the live_stream to STDOUT if we are a TTY, not daemonized, but sensitive" do
          new_resource.sensitive true
          allow(STDOUT).to receive(:tty?).and_return(true)
          expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
          expect(provider).to receive(:converge_by).with("execute sensitive resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end

        it "should not set the live_stream to STDOUT if we are a TTY, but daemonized" do
          Chef::Config[:daemon] = true
          allow(STDOUT).to receive(:tty?).and_return(true)
          expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
          expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
          expect(Chef::Log).not_to receive(:warn)
          provider.run_action(:run)
          expect(new_resource).to be_updated
        end

      end
    end
  end
end
