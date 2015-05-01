#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
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
require 'chef/formatters/error_inspectors/api_error_formatting'

describe Chef::Formatters::APIErrorFormatting do
  let(:class_instance) { (Class.new { include Chef::Formatters::APIErrorFormatting }).new }
  let(:error_description) { instance_double(Chef::Formatters::ErrorDescription) }
  let(:response) { double("response") }
  before do
    allow(response).to receive(:body)
  end


  context "when describe_406_error is called" do
    context "when response.body['error'] == 'invalid-x-ops-server-api-version'" do
      let(:min_version) { "2" }
      let(:max_version) { "5" }
      let(:return_hash) {
        {
          "error" => "invalid-x-ops-server-api-version",
          "min_version" => min_version,
          "max_version" => max_version
        }
      }

      before do
        allow(Chef::JSONCompat).to receive(:from_json).and_return(return_hash)
      end

      it "prints an error about client and server API version incompatibility with a min API version" do
        expect(error_description).to receive(:section).with("Incompatible server API version:",/a min API version of #{min_version}/)
        class_instance.describe_406_error(error_description, response)
      end

      it "prints an error about client and server API version incompatibility with a max API version" do
        expect(error_description).to receive(:section).with("Incompatible server API version:",/a max API version of #{max_version}/)
        class_instance.describe_406_error(error_description, response)
      end
    end

    context "when response.body['error'] != 'invalid-x-ops-server-api-version'" do
      let(:return_hash) {
        {
          "error" => "some-other-error"
        }
      }

      before do
        allow(Chef::JSONCompat).to receive(:from_json).and_return(return_hash)
      end

      it "forwards the error_description to describe_http_error" do
        expect(class_instance).to receive(:describe_http_error).with(error_description)
        class_instance.describe_406_error(error_description, response)
      end
    end
  end
end
