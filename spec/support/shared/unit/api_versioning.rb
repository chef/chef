#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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

require "chef/exceptions"

shared_examples_for "version handling" do
  let(:response_406) { OpenStruct.new(:code => "406") }
  let(:exception_406) { Net::HTTPServerException.new("406 Not Acceptable", response_406) }

  before do
    allow(rest_v1).to receive(http_verb).and_raise(exception_406)
  end

  context "when the server does not support the min or max server API version that Chef::UserV1 supports" do
    before do
      allow(object).to receive(:server_client_api_version_intersection).and_return([])
    end

    it "raises the original exception" do
      expect { object.send(method) }.to raise_error(exception_406)
    end
  end # when the server does not support the min or max server API version that Chef::UserV1 supports
end # version handling

shared_examples_for "user and client reregister" do
  let(:response_406) { OpenStruct.new(:code => "406") }
  let(:exception_406) { Net::HTTPServerException.new("406 Not Acceptable", response_406) }
  let(:generic_exception) { Exception.new }
  let(:min_version) { "2" }
  let(:max_version) { "5" }
  let(:return_hash_406) do
    {
      "min_version" => min_version,
      "max_version" => max_version,
      "request_version" => "30",
    }
  end

  context "when V0 is not supported by the server" do
    context "when the exception is 406 and returns x-ops-server-api-version header" do
      before do
        allow(rest_v0).to receive(:put).and_raise(exception_406)
        allow(response_406).to receive(:[]).with("x-ops-server-api-version").and_return(Chef::JSONCompat.to_json(return_hash_406))
      end

      it "raises an error about only V0 being supported" do
        expect(object).to receive(:reregister_only_v0_supported_error_msg).with(max_version, min_version)
        expect { object.reregister }.to raise_error(Chef::Exceptions::OnlyApiVersion0SupportedForAction)
      end

    end
    context "when the exception is not versioning related" do
      before do
        allow(rest_v0).to receive(:put).and_raise(generic_exception)
      end

      it "raises the original error" do
        expect { object.reregister }.to raise_error(generic_exception)
      end
    end
  end
end
