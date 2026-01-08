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

describe Chef::Resource::WindowsUac do
  let(:resource) { Chef::Resource::WindowsUac.new("fakey_fakerton") }

  it "sets resource name as :windows_uac" do
    expect(resource.resource_name).to eql(:windows_uac)
  end

  %i{no_prompt secure_prompt_for_creds secure_prompt_for_consent prompt_for_creds prompt_for_consent prompt_for_consent_non_windows_binaries}.each do |val|
    it "the consent_behavior_admins property accepts :#{val}" do
      expect { resource.consent_behavior_admins val }.not_to raise_error
    end
  end

  it "the resource raises an ArgumentError if invalid consent_behavior_admins is set" do
    expect { resource.consent_behavior_admins :bogus }.to raise_error(ArgumentError)
  end

  %i{auto_deny secure_prompt_for_creds prompt_for_creds}.each do |val|
    it "the consent_behavior_users property accepts :#{val}" do
      expect { resource.consent_behavior_users val }.not_to raise_error
    end
  end

  it "the resource raises an ArgumentError if invalid consent_behavior_users is set" do
    expect { resource.consent_behavior_users :bogus }.to raise_error(ArgumentError)
  end

  it "sets the default action as :configure" do
    expect(resource.action).to eql([:configure])
  end
end
