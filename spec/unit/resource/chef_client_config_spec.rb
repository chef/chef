#
# Author:: Tim Smith (<tsmith@chef.io>)
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

describe Chef::Resource::ChefClientConfig do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ChefClientConfig.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:create) }

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create and :remove actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "ssl_verify_mode property" do
    it "coerces String to Symbol" do
      resource.ssl_verify_mode "verify_peer"
      expect(resource.ssl_verify_mode).to eql(:verify_peer)
    end

    it "coerces Symbol-like String to Symbol" do
      resource.ssl_verify_mode ":verify_peer"
      expect(resource.ssl_verify_mode).to eql(:verify_peer)
    end

    it "raises an error if it is not an allowed value" do
      expect { resource.ssl_verify_mode("foo") }.to raise_error(Chef::Exceptions::ValidationFailed)
      expect { resource.ssl_verify_mode(:verify_none) }.not_to raise_error
      expect { resource.ssl_verify_mode(:verify_peer) }.not_to raise_error
    end
  end

  describe "no_proxy property" do
    it "coerces Array into comma separated list" do
      resource.no_proxy ["something.com", "example.com"]
      expect(resource.no_proxy).to eql("something.com,example.com")
    end

    it "accepts String of comma separated values" do
      resource.no_proxy "something.com,example.com"
      expect(resource.no_proxy).to eql("something.com,example.com")
    end
  end

  describe "ohai_disabled_plugins property" do
    it "coerces String values into capitalized symbols" do
      resource.ohai_disabled_plugins %w{foo Bar}
      expect(resource.ohai_disabled_plugins).to eql(%i{Foo Bar})
    end

    it "coerces symbol-like string values into capitalized Symbols" do
      resource.ohai_disabled_plugins [":foo", ":Bar"]
      expect(resource.ohai_disabled_plugins).to eql(%i{Foo Bar})
    end

    it "coerces Symbol values into capitalized Symbols" do
      resource.ohai_disabled_plugins %i{foo Bar}
      expect(resource.ohai_disabled_plugins).to eql(%i{Foo Bar})
    end
  end

  describe "ohai_optional_plugins property" do
    it "coerces String values into capitalized symbols" do
      resource.ohai_optional_plugins %w{foo Bar}
      expect(resource.ohai_optional_plugins).to eql(%i{Foo Bar})
    end

    it "coerces symbol-like string values into capitalized Symbols" do
      resource.ohai_optional_plugins [":foo", ":Bar"]
      expect(resource.ohai_optional_plugins).to eql(%i{Foo Bar})
    end

    it "coerces Symbol values into capitalized Symbols" do
      resource.ohai_optional_plugins %i{foo Bar}
      expect(resource.ohai_optional_plugins).to eql(%i{Foo Bar})
    end
  end

  describe "log_level property" do
    it "accepts auto trace debug info warn fatal" do
      expect { resource.log_level(:auto) }.not_to raise_error
      expect { resource.log_level(:trace) }.not_to raise_error
      expect { resource.log_level(:debug) }.not_to raise_error
      expect { resource.log_level(:info) }.not_to raise_error
      expect { resource.log_level(:warn) }.not_to raise_error
    end

    it "raises an error if an invalid value is passed" do
      expect { resource.log_level(":foo") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "log_location property" do
    it "accepts a String logfile location" do
      expect { resource.log_location("/foo/bar/") }.not_to raise_error
    end

    it "accepts a String form of STDOUT/STDERR" do
      expect { resource.log_location("STDOUT") }.not_to raise_error
      expect { resource.log_location("STDERR") }.not_to raise_error
    end

    it "accepts :syslog or :win_evt Symbols" do
      expect { resource.log_location(:syslog) }.not_to raise_error
      expect { resource.log_location(:win_evt) }.not_to raise_error
      expect { resource.log_location(:nope) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "#format_handler" do
    it "provides an array of handler object creation code" do
      expect(provider.format_handler([{ "class" => "Foo", "arguments" => ["'one'", "two", "three"] }])).to eql(["Foo.new('one',two,three)"])
    end
  end

  describe "rubygems_url property" do
    it "accepts nil, a single URL, or an array of URLs" do
      expect { resource.rubygems_url(nil) }.not_to raise_error
      expect { resource.rubygems_url("https://rubygems.internal.example.com") }.not_to raise_error
      expect { resource.rubygems_url(["https://rubygems.east.example.com", "https://rubygems.west.example.com"]) }.not_to raise_error
    end
  end
end
