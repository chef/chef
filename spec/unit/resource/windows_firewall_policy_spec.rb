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

describe Chef::Resource::WindowsFirewallProfile do
  let(:resource) { Chef::Resource::WindowsFirewallProfile.new("fakey_fakerton") }

  it "sets resource name as :windows_firewall_profile" do
    expect(resource.resource_name).to eql(:windows_firewall_profile)
  end

  %w{ Domain Private Public }.each do |this_profile|
    it "The profile accepts values for the \"#{this_profile}\" Profile" do
      expect { resource.profile this_profile }.not_to raise_error
    end
  end

  it "the profile property does not accept bad profile names" do
    expect { resource.profile "Special" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "the resource's default_inbound_action property only strings Block, Allow, or NotConfigured" do
    expect { resource.default_inbound_action "AllowSome" }.to raise_error(ArgumentError)
    expect { resource.default_inbound_action "Block"}.not_to raise_error
  end
  it "the resource's default_outbound_action property only accepts strings Block, Allow, or NotConfigured" do
    expect { resource.default_outbound_action "BlockMost" }.to raise_error(ArgumentError)
    expect { resource.default_outbound_action "Allow"}.not_to raise_error
  end
  it "the resource's allow_inbound_rules property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_inbound_rules "Yes" }.to raise_error(ArgumentError)
    expect { resource.allow_inbound_rules "True"}.not_to raise_error
  end
  it "the resource's allow_local_firewall_rules property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_local_firewall_rules "No" }.to raise_error(ArgumentError)
    expect { resource.allow_local_firewall_rules "False"}.not_to raise_error
  end
  it "the resource's allow_local_ipsec_rules property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_local_ipsec_rules "Yes" }.to raise_error(ArgumentError)
    expect { resource.allow_local_ipsec_rules "True"}.not_to raise_error
  end
  it "the resource's allow_user_apps property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_user_apps "No" }.to raise_error(ArgumentError)
    expect { resource.allow_user_apps "False"}.not_to raise_error
  end
  it "the resource's allow_user_ports property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_user_ports nil }.to raise_error(ArgumentError)
    expect { resource.allow_user_ports "NotConfigured"}.not_to raise_error
  end
  it "the resource's allow_unicast_response property only accepts strings True, False, or NotConfigured" do
    expect { resource.allow_unicast_response true }.to raise_error(ArgumentError)
    expect { resource.allow_unicast_response "True"}.not_to raise_error
  end
  it "the resource's display_notification property only accepts strings True, False, or NotConfigured" do
    expect { resource.display_notification false }.to raise_error(ArgumentError)
    expect { resource.display_notification "False"}.not_to raise_error
  end

  it "sets the default action as :configure" do
    expect(resource.action).to eql([:enable])
  end
end
