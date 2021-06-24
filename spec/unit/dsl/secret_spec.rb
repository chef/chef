#
# Author:: Marc Paradise <marc@chef.io>
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/dsl/secret"
require "chef/secret_fetcher/base"
class SecretDSLTester
  include Chef::DSL::Secret
end

class SecretFetcherImpl < Chef::SecretFetcher::Base
  def do_fetch(name)
    name
  end
end

describe Chef::DSL::Secret do
  let(:dsl) { SecretDSLTester.new }
  it "responds to 'secret'" do
    expect(dsl.respond_to?(:secret)).to eq true
  end

  it "uses SecretFetcher.for_service to find the fetcher" do
    substitute_fetcher = SecretFetcherImpl.new({})
    expect(Chef::SecretFetcher).to receive(:for_service).with(:example, {}).and_return(substitute_fetcher)
    expect(substitute_fetcher).to receive(:fetch).with "key1"
    dsl.secret(name: "key1", service: :example, config: {})
  end

  it "resolves a secret when using the example fetcher" do
    secret_value = dsl.secret(name: "test1", service: :example,
                              config: { "test1" => "secret value" })
    expect(secret_value).to eq "secret value"
  end
end
