#
# Author:: Marc Paradise <marc@chef.io>
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
require "chef/exceptions"
require "chef/dsl/secret"
require "chef/secret_fetcher/base"

class SecretDSLTester
  include Chef::DSL::Secret

  # Because DSL is invoked in the context of a recipe or attribute file
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
  let(:run_context) { Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new) }

  before do
    allow(dsl).to receive(:run_context).and_return(run_context)
  end

  %w{
      secret
      default_secret_service
      default_secret_config
      with_secret_service
      with_secret_config
    }.each do |m|
      it "responds to ##{m}" do
        expect(dsl.respond_to?(m)).to eq true
      end
    end

  describe "#default_secret_service" do
    let(:service) { :hashi_vault }

    it "persists the service passed in as an argument" do
      expect(dsl.default_secret_service).to eq(nil)
      dsl.default_secret_service(service)
      expect(dsl.default_secret_service).to eq(service)
    end

    it "returns run_context.default_secret_service value when no argument is given" do
      run_context.default_secret_service = :my_thing
      expect(dsl.default_secret_service).to eq(:my_thing)
    end

    it "raises exception when service given is not valid" do
      stub_const("Chef::SecretFetcher::SECRET_FETCHERS", %i{service_a service_b})
      expect { dsl.default_secret_service(:unknown_service) }.to raise_error(Chef::Exceptions::Secret::InvalidFetcherService)
    end
  end

  describe "#with_secret_config" do
    let(:service) { :hashi_vault }

    it "sets the service for the scope of the block only" do
      expect(dsl.default_secret_service).to eq(nil)
      dsl.with_secret_service(service) do
        expect(dsl.default_secret_service).to eq(service)
      end
      expect(dsl.default_secret_service).to eq(nil)
    end

    it "raises exception when block is not given" do
      expect { dsl.with_secret_service(service) }.to raise_error(ArgumentError)
    end
  end

  describe "#default_secret_config" do
    let(:config) { { my_key: "value" } }

    it "persists the config passed in as argument" do
      expect(dsl.default_secret_config).to eq({})
      dsl.default_secret_config(**config)
      expect(dsl.default_secret_config).to eq(config)
    end

    it "returns run_context.default_secret_config value when no argument is given" do
      run_context.default_secret_config = { my_thing: "that" }
      expect(dsl.default_secret_config).to eq({ my_thing: "that" })
    end
  end

  describe "#with_secret_config" do
    let(:config) { { my_key: "value" } }

    it "sets the config for the scope of the block only" do
      expect(dsl.default_secret_config).to eq({})
      dsl.with_secret_config(**config) do
        expect(dsl.default_secret_config).to eq(config)
      end
      expect(dsl.default_secret_config).to eq({})
    end

    it "raises exception when block is not given" do
      expect { dsl.with_secret_config(**config) }.to raise_error(ArgumentError)
    end
  end

  describe "#secret" do
    it "uses SecretFetcher.for_service to find the fetcher" do
      substitute_fetcher = SecretFetcherImpl.new({}, nil)
      expect(Chef::SecretFetcher).to receive(:for_service).with(:example, {}, run_context).and_return(substitute_fetcher)
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

    it "passes default service to SecretFetcher.for_service" do
      service = :example
      dsl.default_secret_service(service)
      substitute_fetcher = SecretFetcherImpl.new({}, nil)
      expect(Chef::SecretFetcher).to receive(:for_service).with(service, {}, run_context).and_return(substitute_fetcher)
      allow(substitute_fetcher).to receive(:fetch).with("key1", nil)
      dsl.secret(name: "key1")
    end

    it "passes default config to SecretFetcher.for_service" do
      config = { my_config: "value" }
      dsl.default_secret_config(**config)
      substitute_fetcher = SecretFetcherImpl.new({}, nil)
      expect(Chef::SecretFetcher).to receive(:for_service).with(:example, config, run_context).and_return(substitute_fetcher)
      allow(substitute_fetcher).to receive(:fetch).with("key1", nil)
      dsl.secret(name: "key1", service: :example)
    end
  end
end
