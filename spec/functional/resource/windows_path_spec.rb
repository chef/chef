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

describe Chef::Resource::WindowsPath, :windows_only do
  let(:path) { "test_path" }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  before(:all) do
    @old_path = ENV["PATH"].dup
  end

  after(:all) do
    ENV["PATH"] = @old_path
  end

  subject do
    new_resource = Chef::Resource::WindowsPath.new(path, run_context)
    new_resource
  end

  describe "adding path" do
    after { remove_path }

    it "appends the user given path in the Environment variable Path" do
      subject.run_action(:add)
      expect(ENV["PATH"]).to include(path)
    end
  end

  describe "removing path" do
    before { add_path }

    it "removes the user given path from the Environment variable Path" do
      subject.run_action(:remove)
      expect(ENV["PATH"]).not_to include(path)
    end
  end

  def remove_path
    new_resource = Chef::Resource::WindowsPath.new(path, run_context)
    new_resource.run_action(:remove)
  end

  def add_path
    new_resource = Chef::Resource::WindowsPath.new(path, run_context)
    new_resource.run_action(:add)
  end
end
