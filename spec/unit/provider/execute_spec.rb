#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
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
#

require 'spec_helper'

describe Chef::Provider::Execute do

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:provider) { Chef::Provider::Execute.new(new_resource, run_context) }
  let(:current_resource) { Chef::Resource::Ifconfig.new("foo_resource", run_context) }

  let(:opts) do
    {
      timeout:      3600,
      returns:      0,
      log_level:    :info,
      log_tag:      new_resource.to_s,
      live_stream:  STDOUT,
    }
  end

  let(:new_resource) { Chef::Resource::Execute.new("foo_resource", run_context) }

  before do
    allow(ChefConfig).to receive(:windows?) { false }
    @original_log_level = Chef::Log.level
    Chef::Log.level = :info
    allow(STDOUT).to receive(:tty?).and_return(true)
  end

  after do
    Chef::Log.level = @original_log_level
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

    it "if you pass a command attribute, it runs the command" do
      new_resource.command "/usr/argelbargle/bin/oogachacka 12345"
      expect(provider).to receive(:shell_out!).with(new_resource.command, opts)
      expect(provider).to receive(:converge_by).with("execute #{new_resource.command}").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "should honor sensitive attribute" do
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

      it "should warn in Chef-12", :chef_lt_13_only do
        expect(Chef::Log).to receive(:warn).with(/relative path/)
        expect(FileTest).to receive(:exist?).with(new_resource.creates).and_return(true)
        expect(provider).not_to receive(:shell_out!)
        provider.run_action(:run)
        expect(new_resource).not_to be_updated
      end

      it "should raise if user specified relative path without cwd for Chef-13", :chef_gte_13_only do
        expect(Chef::Log).to receive(:warn).with(/relative path/)
        expect(FileTest).to receive(:exist?).with(new_resource.creates).and_return(true)
        expect(provider).not_to receive(:shell_out!)
        expect { provider.run_action(:run) }.to raise_error  # @todo: add a real error for Chef-13
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

    it "should unset the live_stream if STDOUT is not a tty" do
      expect(STDOUT).to receive(:tty?).and_return(false)
      opts.delete(:live_stream)
      expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
      expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "should unset the live_stream if chef is running as a daemon" do
      allow(Chef::Config).to receive(:[]).and_call_original
      expect(Chef::Config).to receive(:[]).with(:daemon).and_return(true)
      opts.delete(:live_stream)
      expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
      expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end

    it "should unset the live_stream if we are not running with a log level of at least :info" do
      expect(Chef::Log).to receive(:info?).and_return(false)
      opts.delete(:live_stream)
      expect(provider).to receive(:shell_out!).with(new_resource.name, opts)
      expect(provider).to receive(:converge_by).with("execute foo_resource").and_call_original
      expect(Chef::Log).not_to receive(:warn)
      provider.run_action(:run)
      expect(new_resource).to be_updated
    end
  end
end
