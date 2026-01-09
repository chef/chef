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

describe Chef::Resource::WindowsAuditPolicy do
  let(:resource) { Chef::Resource::WindowsAuditPolicy.new("fakey_fakerton") }

  it "sets resource name as :windows_audit_policy" do
    expect(resource.resource_name).to eql(:windows_audit_policy)
  end

  it "expects crash_on_audit_fail to have a true or false value if entered" do
    expect { resource.crash_on_audit_fail "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects full_privilege_auditing to have a true or false value if entered" do
    expect { resource.full_privilege_auditing "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects audit_base_objects to have a true or false value if entered" do
    expect { resource.audit_base_objects "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects audit_base_directories to have a true or false value if entered" do
    expect { resource.audit_base_directories "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects success property to have a true or false value if entered" do
    expect { resource.success "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "expects failure property to have a true or false value if entered" do
    expect { resource.failure "not_a_true_or_false" }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  Chef::Resource::WindowsAuditPolicy::WIN_AUDIT_SUBCATEGORIES.each do |val|
    it "the subcategory property accepts :#{val}" do
      expect { resource.subcategory val }.not_to raise_error
    end
  end

  it "the resource raises an ArgumentError if invalid subcategory property is set" do
    expect { resource.subcategory "Logount" }.to raise_error(ArgumentError)
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end
end
