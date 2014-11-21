
require 'spec_helper'
require 'chef/dsl/audit'

class AuditDSLTester
  include Chef::DSL::Audit
end

describe Chef::DSL::Audit do
  let(:auditor) { AuditDSLTester.new }

  it "raises an error when a block of audits is not provided" do
    expect{ auditor.controls "name" }.to raise_error(Chef::Exceptions::NoAuditsProvided)
  end

  it "raises an error when no audit name is given" do
    expect{ auditor.controls do end }.to raise_error(Chef::Exceptions::AuditNameMissing)
  end

  it "raises an error if the audit name is a duplicate" do
    auditor.controls "unique" do end
    expect { auditor.controls "unique" do end }.to raise_error(Chef::Exceptions::AuditControlGroupDuplicate)
  end
end
