#
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

describe Chef::Resource::MacosUserDefaults do

  let(:resource) { Chef::Resource::MacosUserDefaults.new("foo") }
  let(:provider) { resource.provider_for_action(:write) }

  it "has a resource name of :macos_userdefaults" do
    expect(resource.resource_name).to eq(:macos_userdefaults)
  end

  it "the domain property defaults to NSGlobalDomain" do
    expect(resource.domain).to eq("NSGlobalDomain")
  end

  it "the value property coerces keys in hashes to strings so we can compare them with plist data" do
    resource.value "User": "/Library/Managed Installs/way_fake.log"
    expect(resource.value).to eq({ "User" => "/Library/Managed Installs/way_fake.log" })
  end

  it "the host property defaults to nil" do
    expect(resource.host).to be_nil
  end

  it "the sudo property defaults to false" do
    expect(resource.sudo).to be false
  end

  it "sets the default action as :write" do
    expect(resource.action).to eq([:write])
  end

  it "supports :write action" do
    expect { resource.action :write }.not_to raise_error
  end

  describe "#defaults_export_cmd" do
    it "exports NSGlobalDomain if no domain is set" do
      expect(provider.defaults_export_cmd(resource)).to eq(["/usr/bin/defaults", "export", "NSGlobalDomain", "-"])
    end

    it "exports a provided domain" do
      resource.domain "com.tim"
      expect(provider.defaults_export_cmd(resource)).to eq(["/usr/bin/defaults", "export", "com.tim", "-"])
    end

    it "sets -currentHost if host is 'current'" do
      resource.host "current"
      expect(provider.defaults_export_cmd(resource)).to eq(["/usr/bin/defaults", "-currentHost", "export", "NSGlobalDomain", "-"])
    end

    it "sets -host 'tim-laptop if host is 'tim-laptop'" do
      resource.host "tim-laptop"
      expect(provider.defaults_export_cmd(resource)).to eq(["/usr/bin/defaults", "-host", "tim-laptop", "export", "NSGlobalDomain", "-"])
    end
  end

  describe "#defaults_modify_cmd" do
    # avoid needing to set these required values over and over. We'll overwrite them where necessary
    before do
      resource.key = "foo"
      resource.value = "bar"
    end

    it "writes to NSGlobalDomain if domain isn't specified" do
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-string", "bar"])
    end

    it "uses the domain property if set" do
      resource.domain = "MyCustomDomain"
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "MyCustomDomain", "foo", "-string", "bar"])
    end

    it "sets host specific values using host property" do
      resource.host = "tims_laptop"
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "-host", "tims_laptop", "write", "NSGlobalDomain", "foo", "-string", "bar"])
    end

    it "if host is set to :current it passes CurrentHost" do
      resource.host = :current
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "-currentHost", "write", "NSGlobalDomain", "foo", "-string", "bar"])
    end

    it "raises ArgumentError if bool is specified, but the value can't be made into a bool" do
      resource.type "bool"
      expect { provider.defaults_modify_cmd }.to raise_error(ArgumentError)
    end

    it "autodetects array type and passes individual values" do
      resource.value = %w{one two three}
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-array", "one", "two", "three"])
    end

    it "autodetects string type and passes a single value" do
      resource.value = "one"
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-string", "one"])
    end

    it "autodetects integer type and passes a single value" do
      resource.value = 1
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-int", 1])
    end

    it "autodetects boolean type from TrueClass value and passes a 'TRUE' string" do
      resource.value = true
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-bool", "TRUE"])
    end

    it "autodetects boolean type from FalseClass value and passes a 'FALSE' string" do
      resource.value = false
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-bool", "FALSE"])
    end

    it "autodetects dict type from Hash value and flattens keys & values" do
      resource.value = { "foo" => "bar" }
      expect(provider.defaults_modify_cmd).to eq(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "-dict", "foo", "bar"])
    end
  end
end
