#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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

describe "windows_path provider", :windows_only do
  before(:all) do
    @old_path = ENV["PATH"].dup
  end

  after(:all) do
    ENV["PATH"] = @old_path
  end

  let(:run_context) { Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new) }
  let(:new_resource) { Chef::Resource::WindowsPath.new("some_path", run_context) }
  let(:provider) { new_resource.provider_for_action(:add) }

  describe "#load_current_resource" do
    it "returns a current_resource" do
      expect(provider.load_current_resource).to be_kind_of(Chef::Resource::WindowsPath)
    end

    it "sets the path of current resource as the path of new resource" do
      current_resource = provider.load_current_resource
      expect(current_resource.path).to eq("some_path")
    end
  end

  describe "#action_add" do
    it "uses env resource to add 'path' environment variable" do
      allow(provider).to receive(:expand_env_vars)
      expect(provider).to receive(:declare_resource).with(:env, "path", hash_including)
      provider.run_action(:add)
    end
  end

  describe "#action_remove" do
    it "uses env resource to remove 'path' environment variable" do
      allow(provider).to receive(:expand_env_vars)
      expect(provider).to receive(:declare_resource).with(:env, "path", hash_including)
      provider.run_action(:remove)
    end
  end
end
