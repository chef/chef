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

describe Chef::Resource::WindowsAuditPolicy do
  subcat_opts = ["Security State Change",
                 "Security System Extension",
                 "System Integrity",
                 "IPsec Driver",
                 "Other System Events",
                 "Logon",
                 "Logoff",
                 "Account Lockout",
                 "IPsec Main Mode",
                 "IPsec Quick Mode",
                 "IPsec Extended Mode",
                 "Special Logon",
                 "Other Logon/Logoff Events",
                 "Network Policy Server",
                 "User / Device Claims",
                 "Group Membership",
                 "File System",
                 "Registry",
                 "Kernel Object",
                 "SAM",
                 "Certification Services",
                 "Application Generated",
                 "Handle Manipulation",
                 "File Share",
                 "Filtering Platform Packet Drop",
                 "Filtering Platform Connection",
                 "Other Object Access Events",
                 "Detailed File Share",
                 "Removable Storage",
                 "Central Policy Staging",
                 "Sensitive Privilege Use",
                 "Non Sensitive Privilege Use",
                 "Other Privilege Use Events",
                 "Process Creation",
                 "Process Termination",
                 "DPAPI Activity",
                 "RPC Events",
                 "Plug and Play Events",
                 "Token Right Adjusted Events",
                 "Audit Policy Change",
                 "Authentication Policy Change",
                 "Authorization Policy Change",
                 "MPSSVC Rule-Level Policy Change",
                 "Filtering Platform Policy Change",
                 "Other Policy Change Events",
                 "User Account Management",
                 "Computer Account Management",
                 "Security Group Management",
                 "Distribution Group Management",
                 "Application Group Management",
                 "Other Account Management Events",
                 "Directory Service Access",
                 "Directory Service Changes",
                 "Directory Service Replication",
                 "Detailed Directory Service Replication",
                 "Credential Validation",
                 "Kerberos Service Ticket Operations",
                 "Other Account Logon Events",
                 "Kerberos Authentication Service",
                ]
  let(:resource) { Chef::Resource::WindowsAuditPolicy.new("fakey_fakerton") }

  it "sets resource name as :windows_audit_policy" do
    expect(resource.resource_name).to eql(:windows_audit_policy)
  end

  it "expects crash_on_audit_fail to have a true or false value if entered" do
    expect { resource.crash_on_audit_fail "not_a_true_or_false" }.to raise_error
  end

  it "expects full_privilege_auditing to have a true or false value if entered" do
    expect { resource.full_privilege_auditing "not_a_true_or_false" }.to raise_error
  end

  it "expects audit_base_objects to have a true or false value if entered" do
    expect { resource.audit_base_objects "not_a_true_or_false" }.to raise_error
  end

  it "expects audit_base_directories to have a true or false value if entered" do
    expect { resource.audit_base_directories "not_a_true_or_false" }.to raise_error
  end

  it "expects success property to have a true or false value if entered" do
    expect { resource.success "not_a_true_or_false" }.to raise_error
  end

  it "expects failure property to have a true or false value if entered" do
    expect { resource.failure "not_a_true_or_false" }.to raise_error
  end

  subcat_opts.each do |val|
    it "the subcategory property accepts :#{val}" do
      expect { resource.sub_category val }.not_to raise_error
    end
  end

  %i{Logout subjugate_mortals misfits}.each do |val|
    it "the resource raises an ArgumentError if invalid sub_category property is set" do
      expect { resource.sub_category val }.to raise_error(ArgumentError)
    end
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end
end
