#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2018, Chef Software Inc.
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
require "functional/resource/base"
require "timeout"

describe Chef::Resource::Execute do
  let(:resource) do
    resource = Chef::Resource::Execute.new("foo_resource", run_context)
    resource.command("echo hello")
    resource
  end

  describe "when guard is ruby block" do
    it "guard can still run" do
      resource.only_if { true }
      resource.run_action(:run)
      expect(resource).to be_updated_by_last_action
    end
  end

  describe "when why_run is enabled" do
    before do
      Chef::Config[:why_run] = true
    end

    let(:guard) { "ruby -e 'exit 0'" }
    let!(:guard_resource) do
      interpreter = Chef::GuardInterpreter::ResourceGuardInterpreter.new(resource, guard, nil)
      interpreter.send(:get_interpreter_resource, resource)
    end

    it "executes the guard and not the regular resource" do
      expect_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:get_interpreter_resource).and_return(guard_resource)

      # why_run mode doesn't disable the updated_by_last_action logic, so we really have to look at the provider action
      # to see if why_run correctly disabled the resource.  It should shell_out! for the guard but not the resource.
      expect_any_instance_of(Chef::Provider::Execute).to receive(:shell_out!).once

      resource.only_if guard
      resource.run_action(:run)

      expect(resource).to be_updated_by_last_action
      expect(guard_resource).to be_updated_by_last_action
    end
  end

  describe "when parent resource sets :cwd" do
    let(:guard) { %{ruby -e 'exit 1 unless File.exists?("./nested.json")'} }

    it "guard inherits :cwd from resource and runs" do
      resource.cwd CHEF_SPEC_DATA
      resource.only_if guard
      resource.run_action(:run)
      expect(resource).to be_updated_by_last_action
    end

    it "guard inherits :cwd from resource and does not run" do
      resource.cwd CHEF_SPEC_DATA
      resource.not_if guard
      resource.run_action(:run)
      expect(resource).not_to be_updated_by_last_action
    end
  end

  # We use ruby command so that we don't need to deal with platform specific
  # commands while testing execute resource. We set it so that the resource
  # will be updated if the ENV variable is set to what we are intending
  #
  # FIXME: yeah, but invoking ruby is slow...
  describe "when parent resource sets :environment" do
    before do
      resource.environment({
        "SAWS_SECRET"  => "supersecret",
        "SAWS_KEY"     => "qwerty",
      })
    end

    it "guard inherits :environment value from resource and runs" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] != "supersecret"'}
      resource.run_action(:run)
      expect(resource).to be_updated_by_last_action
    end

    it "guard inherits :environment value from resource and does not run" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] == "supersecret"'}
      resource.run_action(:run)
      expect(resource).not_to be_updated_by_last_action
    end

    it "guard adds additional values in its :environment and runs" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SGCE_SECRET"] != "regularsecret"'}, {
        environment: { "SGCE_SECRET" => "regularsecret" },
      }
      resource.run_action(:run)
      expect(resource).to be_updated_by_last_action
    end

    it "guard adds additional values in its :environment and does not run" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SGCE_SECRET"] == "regularsecret"'}, {
        environment: { "SGCE_SECRET" => "regularsecret" },
      }
      resource.run_action(:run)
      expect(resource).not_to be_updated_by_last_action
    end

    it "guard overwrites value with its :environment and runs" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] != "regularsecret"'}, {
        environment: { "SAWS_SECRET" => "regularsecret" },
      }
      resource.run_action(:run)
      expect(resource).to be_updated_by_last_action
    end

    it "guard overwrites value with its :environment and does not runs" do
      resource.only_if %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] == "regularsecret"'}, {
        environment: { "SAWS_SECRET" => "regularsecret" },
      }
      resource.run_action(:run)
      expect(resource).not_to be_updated_by_last_action
    end
  end

  describe "when a guard is specified" do
    describe "when using the default guard interpreter" do
      let(:guard_interpreter_resource) { nil }
      it_behaves_like "a resource with a guard specifying an alternate user identity"
    end

    describe "when using the execute resource as the guard interpreter" do
      let(:guard_interpreter_resource) { :execute }
      it_behaves_like "a resource with a guard specifying an alternate user identity"
    end
  end

  # Ensure that CommandTimeout is raised, and is caused by resource.timeout really expiring.
  # https://github.com/chef/chef/issues/2985
  #
  # resource.timeout should be short, this is what we're testing
  # resource.command ruby sleep timer should be longer than resource.timeout to give us something to timeout
  # Timeout::timeout should be longer than resource.timeout, but less than the resource.command ruby sleep timer,
  #   so we fail if we finish on resource.command instead of resource.timeout, but raise CommandTimeout anyway (#2175).
  it "times out when a timeout is set on the resource" do
    Timeout.timeout(30) do
      resource.command %{ruby -e 'sleep 300'}
      resource.timeout 0.1
      expect { resource.run_action(:run) }.to raise_error(Mixlib::ShellOut::CommandTimeout)
    end
  end

  describe "when running with an alternate user identity" do
    let(:resource_command_property) { :command }
    it_behaves_like "an execute resource that supports alternate user identity"
  end
end
