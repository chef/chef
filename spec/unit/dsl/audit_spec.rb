
require "spec_helper"
require "chef/dsl/audit"

class AuditDSLTester < Chef::Recipe
  include Chef::DSL::Audit
end

class BadAuditDSLTester
  include Chef::DSL::Audit
end

describe Chef::DSL::Audit do
  let(:auditor) { AuditDSLTester.new("cookbook_name", "recipe_name", run_context) }
  let(:run_context) { instance_double(Chef::RunContext, :audits => audits, :cookbook_collection => cookbook_collection) }
  let(:audits) { {} }
  let(:cookbook_collection) { {} }

  it "raises an error when a block of audits is not provided" do
    expect { auditor.control_group "name" }.to raise_error(Chef::Exceptions::NoAuditsProvided)
  end

  it "raises an error when no audit name is given" do
    expect { auditor.control_group {} }.to raise_error(Chef::Exceptions::AuditNameMissing)
  end

  context "audits already populated" do
    let(:audits) { { "unique" => {} } }

    it "raises an error if the audit name is a duplicate" do
      expect { auditor.control_group("unique") {} }.to raise_error(Chef::Exceptions::AuditControlGroupDuplicate)
    end
  end

  context "included in a class without recipe DSL" do
    let(:auditor) { BadAuditDSLTester.new }

    it "fails because it relies on the recipe DSL existing" do
      expect { auditor.control_group("unique") {} }.to raise_error(NoMethodError, /undefined method `cookbook_name'/)
    end
  end

end
