#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

describe Chef::Resource::Env, :windows_only do
  context "when running on Windows" do
    let(:chef_env_test_lower_case) { "chefenvtest" }
    let(:chef_env_test_mixed_case) { "chefENVtest" }
    let(:env_dne_key) { "env_dne_key" }
    let(:env_value1) { "value1" }
    let(:env_value2) { "value2" }

    let(:env_value_expandable) { "%SystemRoot%" }
    let(:test_run_context) do
      node = Chef::Node.new
      node.default["os"] = "windows"
      node.default["platform"] = "windows"
      node.default["platform_version"] = "6.1"
      empty_events = Chef::EventDispatch::Dispatcher.new
      Chef::RunContext.new(node, {}, empty_events)
    end
    let(:test_resource) do
      Chef::Resource::Env.new("unknown", test_run_context)
    end

    before(:each) do
      resource_lower = Chef::Resource::Env.new(chef_env_test_lower_case, test_run_context)
      resource_lower.run_action(:delete)
      resource_mixed = Chef::Resource::Env.new(chef_env_test_mixed_case, test_run_context)
      resource_mixed.run_action(:delete)
    end

    context "when the create action is invoked" do
      it "should create an environment variable for action create" do
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
      end

      it "should modify an existing variable's value to a new value" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.value(env_value2)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value2)
      end

      it "should modify an existing variable's value to a new value if the variable name case differs from the existing variable" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.key_name(chef_env_test_mixed_case)
        test_resource.value(env_value2)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value2)
      end

      it "should not expand environment variables if the variable is not PATH" do
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value_expandable)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value_expandable)
      end
    end

    context "when the modify action is invoked" do
      it "should raise an exception for modify if the variable doesn't exist" do
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        expect { test_resource.run_action(:modify) }.to raise_error(Chef::Exceptions::Env)
      end

      it "should modify an existing variable's value to a new value" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.value(env_value2)
        test_resource.run_action(:modify)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value2)
      end

      # This examlpe covers Chef Issue #1754
      it "should modify an existing variable's value to a new value if the variable name case differs from the existing variable" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.key_name(chef_env_test_mixed_case)
        test_resource.value(env_value2)
        test_resource.run_action(:modify)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value2)
      end

      it "should not expand environment variables if the variable is not PATH" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.value(env_value_expandable)
        test_resource.run_action(:modify)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value_expandable)
      end

      context "when using PATH" do
        let(:random_name) { Time.now.to_i }
        let(:env_val) { "#{env_value_expandable}_#{random_name}" }
        let!(:path_before) { test_resource.provider_for_action(test_resource.action).env_value("PATH") || "" }
        let!(:env_path_before) { ENV["PATH"] }

        it "should expand PATH" do
          expect(path_before).not_to include(env_val)
          test_resource.key_name("PATH")
          test_resource.value("#{path_before};#{env_val}")
          test_resource.run_action(:create)
          expect(ENV["PATH"]).not_to include(env_val)
          expect(ENV["PATH"]).to include("#{random_name}")
        end

        after(:each) do
          # cleanup so we don't flood the path
          test_resource.key_name("PATH")
          test_resource.value(path_before)
          test_resource.run_action(:create)
          ENV["PATH"] = env_path_before
        end
      end

    end

    context "when the delete action is invoked" do
      it "should delete an environment variable" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.run_action(:delete)
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
      end

      it "should not raise an exception when a non-existent environment variable is deleted" do
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        expect { test_resource.run_action(:delete) }.not_to raise_error
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
      end

      it "should delete an existing variable's value to a new value if the specified variable name case differs from the existing variable" do
        test_resource.key_name(chef_env_test_lower_case)
        test_resource.value(env_value1)
        test_resource.run_action(:create)
        expect(ENV[chef_env_test_lower_case]).to eq(env_value1)
        test_resource.key_name(chef_env_test_mixed_case)
        test_resource.run_action(:delete)
        expect(ENV[chef_env_test_lower_case]).to eq(nil)
        expect(ENV[chef_env_test_mixed_case]).to eq(nil)
      end

      it "should delete a value from the current process even if it is not in the registry" do
        expect(ENV[env_dne_key]).to eq(nil)
        ENV[env_dne_key] = env_value1
        test_resource.key_name(env_dne_key)
        test_resource.run_action(:delete)
        expect(ENV[env_dne_key]).to eq(nil)
      end
    end
  end
end
