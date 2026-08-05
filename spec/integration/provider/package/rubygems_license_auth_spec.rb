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
#

require "spec_helper"
require "rubygems/remote_fetcher"

# Integration coverage for chef_gem/gem_package's `license_id` property:
# drives the real rubygems networking code (Gem::RemoteFetcher) against a
# WebMock-stubbed proprietary gem server to prove the license id is actually
# sent as HTTP Basic Auth, and that the provider's fallback/memoization
# kicks in on an auth failure -- not just that a URL string was built.
describe "gem_package license_id authentication" do
  let(:new_resource) { Chef::Resource::GemPackage.new("rspec-core") }

  let(:provider) do
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
    Chef::Provider::Package::Rubygems.new(new_resource, run_context)
  end

  let(:license_id) { "my-proprietary-license-id" }
  let(:private_source) { "https://gems.example.com/private" }

  before do
    new_resource.source(private_source)
    new_resource.license_id(license_id)
    new_resource.include_default_source(false)
    Chef::Provider::Package::Rubygems.instance_variable_set(:@failed_license_sources, nil)
  end

  after do
    Chef::Provider::Package::Rubygems.instance_variable_set(:@failed_license_sources, nil)
  end

  it "authenticates real requests to the proprietary gem server with the license id" do
    authed_source = provider.gem_sources.first
    expect(authed_source).to eq("https://#{license_id}@gems.example.com/private")

    stub_request(:get, "https://gems.example.com/private")
      .with(basic_auth: [license_id, ""])
      .to_return(status: 200, body: "OK")

    # exercises the same rubygems HTTP client Gem::DependencyInstaller uses
    Gem::RemoteFetcher.fetcher.fetch_path(URI.parse(authed_source))

    expect(WebMock).to have_requested(:get, "https://gems.example.com/private")
      .with(basic_auth: [license_id, ""])
  end

  it "falls back to the remaining sources and remembers the proprietary server as broken for the rest of the run" do
    new_resource.include_default_source(true)
    authed_source = "https://#{license_id}@gems.example.com/private"

    stub_request(:get, "https://gems.example.com/private")
      .with(basic_auth: [license_id, ""])
      .to_return(status: 401, body: "Unauthorized")

    attempts = 0
    remaining_sources = provider.with_license_fallback do
      attempts += 1
      Gem::RemoteFetcher.fetcher.fetch_path(URI.parse(authed_source)) if attempts == 1
      provider.gem_sources
    end

    expect(attempts).to eq(2)
    expect(remaining_sources).to eq(["https://rubygems.org"])
    expect(WebMock).to have_requested(:get, "https://gems.example.com/private").once

    # a later gem_package resource in the same chef-client run should not
    # retry the known-broken proprietary source at all
    later_attempts = 0
    later_sources = provider.with_license_fallback do
      later_attempts += 1
      provider.gem_sources
    end
    expect(later_attempts).to eq(1)
    expect(later_sources).to eq(["https://rubygems.org"])
    expect(WebMock).to have_requested(:get, "https://gems.example.com/private").once
  end
end
