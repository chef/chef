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
  # Because DSL is invoked in the context of a recipe,
  # we expect run_context to always be available when SecretFetcher::Base
  # requests it - making it safe to mock here
  def run_context
    nil
  end
end

class SecretFetcherImpl < Chef::SecretFetcher::Base
  def do_fetch(name, version)
    name
  end
end

describe Chef::DSL::Secret do
  let(:dsl) { SecretDSLTester.new }
  it "responds to 'secret'" do
    expect(dsl.respond_to?(:secret)).to eq true
  end

  it "uses SecretFetcher.for_service to find the fetcher" do
    substitute_fetcher = SecretFetcherImpl.new({}, nil)
    expect(Chef::SecretFetcher).to receive(:for_service).with(:example, {}, nil).and_return(substitute_fetcher)
    expect(substitute_fetcher).to receive(:fetch).with("key1", nil)
    dsl.secret(name: "key1", service: :example, config: {})
  end

  it "resolves a secret when using the example fetcher" do
    secret_value = dsl.secret(name: "test1", service: :example, config: { "test1" => "secret value" })
    expect(secret_value).to eq "secret value"
  end

  context "when used within a resource" do
    let(:run_context) {
      Chef::RunContext.new(Chef::Node.new,
                           Chef::CookbookCollection.new(Chef::CookbookLoader.new(File.join(CHEF_SPEC_DATA, "cookbooks"))),
                           Chef::EventDispatch::Dispatcher.new)
    }

    it "marks that resource as 'sensitive'" do
      recipe = Chef::Recipe.new("secrets", "test", run_context)
      recipe.zen_master "secret_test" do
        peace secret(name: "test1", service: :example, config: { "test1" => true })
      end
      expect(run_context.resource_collection.lookup("zen_master[secret_test]").sensitive).to eql(true)
    end
  end
end
