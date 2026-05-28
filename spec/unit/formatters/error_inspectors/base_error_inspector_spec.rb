#
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

require "spec_helper"

describe Chef::Formatters::ErrorInspectors::BaseErrorInspector do
  let(:inspector_class) do
    Class.new do
      include Chef::Formatters::ErrorInspectors::BaseErrorInspector
    end
  end

  let(:node_name) { "test-node.example.com" }
  let(:exception) { RuntimeError.new("test error") }
  let(:config) { { chef_server_url: "https://chef.example.com" } }

  subject(:inspector) { inspector_class.new(node_name, exception, config) }

  it "stores constructor arguments" do
    expect(inspector.node_name).to eq(node_name)
    expect(inspector.exception).to eq(exception)
    expect(inspector.config).to eq(config)
  end
end
