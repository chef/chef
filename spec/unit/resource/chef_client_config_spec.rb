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

  describe "directory_specs property" do
    it "has defaults for all managed directory specs" do
      expect(resource.directory_specs).to eql(
        config: { mode: "0750", inherits: :auto },
        client_d: { mode: "0750", inherits: :auto },
        logs: { mode: "0755", inherits: :auto },
        cache: { mode: "0750", inherits: :auto },
        backups: { mode: "0750", inherits: :auto }
      )
    end

    it "merges overrides with defaults" do
      resource.directory_specs(config: { owner: "chefuser", mode: "0700" })

      expect(resource.directory_specs[:config]).to eql(mode: "0700", inherits: :auto, owner: "chefuser")
      expect(resource.directory_specs[:client_d]).to eql(mode: "0750", inherits: :auto)
      expect(resource.directory_specs[:logs]).to eql(mode: "0755", inherits: :auto)
      expect(resource.directory_specs[:cache]).to eql(mode: "0750", inherits: :auto)
      expect(resource.directory_specs[:backups]).to eql(mode: "0750", inherits: :auto)
    end

    it "raises if a nested override key is not supported" do
      expect { resource.directory_specs(config: { inherit: true }) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "raises if a nested override value is not a hash" do
      expect { resource.directory_specs(config: "0750") }.to raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "accepts supported nested override keys" do
      expect {
        resource.directory_specs(
          config: {
            owner: "root",
            group: "root",
            mode: "0700",
            rights: { "Administrators" => :full_control },
            inherits: false
          }
        )
      }.not_to raise_error
    end
  end

  describe "create action directory behavior" do
    before do
      resource.chef_server_url("https://chef.example.dmz")
    end

    def stub_template_resource
      allow(provider).to receive(:template) do |_path, &block|
        template_resource = double("template").as_null_object
        block.call(template_resource) if block
      end
    end

    def capture_directory_specs
      captured = {}

      allow(provider).to receive(:directory) do |path, &block|
        dir_resource = double("directory")
        allow(dir_resource).to receive(:owner) { |value| captured[path] ||= {}; captured[path][:owner] = value }
        allow(dir_resource).to receive(:group) { |value| captured[path] ||= {}; captured[path][:group] = value }
        allow(dir_resource).to receive(:mode) { |value| captured[path] ||= {}; captured[path][:mode] = value }
        allow(dir_resource).to receive(:inherits) { |value| captured[path] ||= {}; captured[path][:inherits] = value }
        allow(dir_resource).to receive(:rights) do |permission, principal|
          captured[path] ||= {}
          captured[path][:rights] ||= []
          captured[path][:rights] << [ permission, principal ]
        end

        block.call(dir_resource) if block
      end

      captured
    end

    it "keeps default directory behavior when directory_specs is not provided" do
      resource.config_directory("/etc/chef")
      stub_template_resource
      captured = capture_directory_specs

      provider.run_action(:create)

      expect(captured).to include("/etc/chef")
      expect(captured).to include("/etc/chef/client.d")
      expect(captured).not_to include("/var/chef/cache")
      expect(captured).not_to include("/var/chef/backups")
      expect(captured["/etc/chef"][:mode]).to eql("0750")
      expect(captured["/etc/chef/client.d"][:mode]).to eql("0750")
    end

    it "keeps default directory behavior when directory_specs is explicitly empty" do
      resource.config_directory("/etc/chef")
      resource.directory_specs({})
      stub_template_resource
      captured = capture_directory_specs

      provider.run_action(:create)

      expect(captured).to include("/etc/chef")
      expect(captured).to include("/etc/chef/client.d")
      expect(captured).not_to include("/var/chef/cache")
      expect(captured).not_to include("/var/chef/backups")
      expect(captured["/etc/chef"][:mode]).to eql("0750")
      expect(captured["/etc/chef/client.d"][:mode]).to eql("0750")
    end

    it "applies directory_specs overrides for mode, owner, and group" do
      resource.user("chefuser")
      resource.group("chefgroup")
      resource.config_directory("/etc/chef")
      resource.file_cache_path("/var/chef/cache")
      resource.file_backup_path("/var/chef/backups")
      resource.log_location("/var/log/chef/client.log")
      resource.directory_specs(
        config: { mode: "0700" },
        cache: { owner: "cache_user", group: "cache_group", mode: "0710" }
      )

      stub_template_resource
      captured = capture_directory_specs

      provider.run_action(:create)

      expect(captured["/etc/chef"][:mode]).to eql("0700")
      expect(captured["/etc/chef"][:owner]).to eql("chefuser")
      expect(captured["/etc/chef"][:group]).to eql("chefgroup")

      expect(captured["/var/chef/cache"][:mode]).to eql("0710")
      expect(captured["/var/chef/cache"][:owner]).to eql("cache_user")
      expect(captured["/var/chef/cache"][:group]).to eql("cache_group")

      expect(captured["/var/chef/backups"][:mode]).to eql("0750")
      expect(captured["/var/log/chef"][:mode]).to eql("0755")
    end

    it "applies inherits override on windows" do
      resource.config_directory("C:/chef")
      resource.directory_specs(config: { inherits: false })
      stub_template_resource
      captured = capture_directory_specs
      allow(Chef::Platform).to receive(:windows?).and_return(true)

      provider.run_action(:create)

      expect(captured["C:/chef"][:inherits]).to eql(false)
      expect(captured["C:/chef/client.d"][:inherits]).to eql(true)
    end

    it "raises when overriding cache without file_cache_path" do
      resource.directory_specs(cache: { mode: "0700" })

      expect { provider.run_action(:create) }
        .to raise_error(ArgumentError, "Invalid directory_specs: cache requires :cache")
    end

    it "raises when overriding backups without file_backup_path" do
      resource.directory_specs(backups: { mode: "0700" })

      expect { provider.run_action(:create) }
        .to raise_error(ArgumentError, "Invalid directory_specs: backups requires :backups")
    end

    it "raises when overriding logs without log_location file path" do
      resource.directory_specs(logs: { mode: "0700" })

      expect { provider.run_action(:create) }
        .to raise_error(ArgumentError, "Invalid directory_specs: logs requires :logs (file path)")
    end
  end
end
