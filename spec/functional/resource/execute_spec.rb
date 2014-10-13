#
# Author:: Serdar Sutay (<serdar@opscode.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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
require 'functional/resource/base'

describe Chef::Resource::Execute do
  let(:execute_resource) {
    exec_resource = Chef::Resource::Execute.new("foo_resource", run_context)

    exec_resource.environment(resource_environment) if resource_environment
    exec_resource.cwd(resource_cwd) if resource_cwd
    exec_resource.command("echo hello")
    if guard
      if guard_options
        exec_resource.only_if(guard, guard_options)
      else
        exec_resource.only_if(guard)
      end
    end
    exec_resource
  }

  let(:resource_environment) { nil }
  let(:resource_cwd) { nil }
  let(:guard) { nil }
  let(:guard_options) { nil }

  describe "when guard is ruby block" do
    it "guard can still run" do
      execute_resource.only_if do
        true
      end
      execute_resource.run_action(:run)
      execute_resource.should be_updated_by_last_action
    end
  end

  describe "when parent resource sets :cwd" do
    let(:resource_cwd) { CHEF_SPEC_DATA }

    let(:guard) { %{ruby -e 'exit 1 unless File.exists?("./big_json_plus_one.json")'} }

    it "guard inherits :cwd from resource" do
      execute_resource.run_action(:run)
      execute_resource.should be_updated_by_last_action
    end
  end

  describe "when parent resource sets :environment" do
    let(:resource_environment) do
      {
        "SAWS_SECRET"  => "supersecret",
        "SAWS_KEY"     => "qwerty"
      }
    end

    # We use ruby command so that we don't need to deal with platform specific
    # commands while testing execute resource. We set it so that the resource
    # will be updated if the ENV variable is set to what we are intending
    let(:guard) { %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] != "supersecret"'} }

    it "guard inherits :environment value from resource" do
      execute_resource.run_action(:run)
      execute_resource.should be_updated_by_last_action
    end

    describe "when guard sets additional values in the :environment" do
      let(:guard) { %{ruby -e 'exit 1 if ENV["SGCE_SECRET"] != "regularsecret"'} }

      let(:guard_options) do
        {
          :environment => { 'SGCE_SECRET' => "regularsecret" }
        }
      end

      it "guard sees merged value for in its ENV" do
        execute_resource.run_action(:run)
        execute_resource.should be_updated_by_last_action
      end
    end

    describe "when guard sets same value in the :environment" do
      let(:guard) { %{ruby -e 'exit 1 if ENV["SAWS_SECRET"] != "regularsecret"'} }

      let(:guard_options) do
        {
          :environment => { 'SAWS_SECRET' => "regularsecret" }
        }
      end

      it "guard sees value from guard options in its ENV" do
        execute_resource.run_action(:run)
        execute_resource.should be_updated_by_last_action
      end
    end
  end
end
