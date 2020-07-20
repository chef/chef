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
    expect(resource.resource_name).to eql(:macos_userdefaults)
  end

  it "the domain property defaults to NSGlobalDomain" do
    expect(resource.domain).to eql("NSGlobalDomain")
  end

  it "the host property defaults to nil" do
    expect(resource.host).to be_nil
  end

  it "the sudo property defaults to false" do
    expect(resource.sudo).to be false
  end

  it "sets the default action as :write" do
    expect(resource.action).to eql([:write])
  end

  it "supports :write action" do
    expect { resource.action :write }.not_to raise_error
  end

  describe "#defaults_export_cmd" do
    it "exports NSGlobalDomain if no domain is set" do
      expect(provider.defaults_export_cmd(resource)).to eql(["/usr/bin/defaults", "export", "NSGlobalDomain", "-"])
    end

    it "exports a provided domain" do
      resource.domain "com.tim"
      expect(provider.defaults_export_cmd(resource)).to eql(["/usr/bin/defaults", "export", "com.tim", "-"])
    end

    it "sets -currentHost if host is 'current'" do
      resource.host "current"
      expect(provider.defaults_export_cmd(resource)).to eql(["/usr/bin/defaults", "-currentHost", "export", "NSGlobalDomain", "-"])
    end

    it "sets -host 'tim-laptop if host is 'tim-laptop'" do
      resource.host "tim-laptop"
      expect(provider.defaults_export_cmd(resource)).to eql(["/usr/bin/defaults", "-host", "tim-laptop", "export", "NSGlobalDomain", "-"])
    end
  end

  describe "#defaults_modify_cmd" do
    # avoid needing to set these required values over and over. We'll overwrite them where necessary
    before do
      resource.key = "foo"
      resource.value = "bar"
    end

    it "writes to NSGlobalDomain if domain isn't specified" do
      expect(provider.defaults_modify_cmd).to eql(["/usr/bin/defaults", "write", "NSGlobalDomain", "foo", "bar"])
    end

    it "uses the domain property if set" do
      resource.domain = "MyCustomDomain"
      expect(provider.defaults_modify_cmd).to eql(["/usr/bin/defaults", "write", "MyCustomDomain", "foo", "bar"])
    end

    it "sets host specific values using host property" do
      resource.host = "tims_laptop"
      expect(provider.defaults_modify_cmd).to eql(["/usr/bin/defaults", "-host", "tims_laptop", "write", "NSGlobalDomain", "foo", "bar"])
    end

    it "if host is set to :current it passes CurrentHost" do
      resource.host = :current
      expect(provider.defaults_modify_cmd).to eql(["/usr/bin/defaults", "-currentHost", "write", "NSGlobalDomain", "foo", "bar"])
    end

    it "if host is set to :current it passes CurrentHost" do
      resource.host = :current
      expect(provider.defaults_modify_cmd).to eql(["/usr/bin/defaults", "-currentHost", "write", "NSGlobalDomain", "foo", "bar"])
    end
  end
end
