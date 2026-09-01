#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

# spec_helper loads the shared examples already.
# require 'support/shared/unit/api_error_inspector_spec'

describe Chef::Formatters::ErrorInspectors::RegistrationErrorInspector do
  it_behaves_like "an api error inspector"

  describe "when explaining an error type not otherwise matched" do
    let(:exception) { RuntimeError.new("(exception) something went wrong") }
    let(:config) { { validation_client_name: "testorg-validator", validation_key: "/etc/chef/testorg-validator.pem", chef_server_url: "https://chef-api.example.com" } }
    let(:inspector) { described_class.new("test-node.example.com", exception, config) }
    let(:error_description) { Chef::Formatters::ErrorDescription.new("Error registering the node:") }

    it "adds a section describing the exception instead of silently discarding it" do
      inspector.add_explanation(error_description)
      expect(error_description.sections).to include("Unexpected Error:" => "RuntimeError: (exception) something went wrong")
    end
  end
end
