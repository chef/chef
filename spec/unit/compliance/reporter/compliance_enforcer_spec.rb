require "spec_helper"
require "chef/compliance/reporter/compliance_enforcer"

describe Chef::Compliance::Reporter::AuditEnforcer do
  let(:reporter) { Chef::Compliance::Reporter::AuditEnforcer.new }

  it "does not raise error for a successful InSpec report" do
    report = {
      "profiles": [
        {
          "controls": [
            { "id": "c1", "results": [{ "status": "passed" }] },
            { "id": "c2", "results": [{ "status": "passed" }] },
          ],
        },
      ],
    }

    expect(reporter.send_report(report)).to eq(true)
  end

  it "does not raise error for an InSpec report with no controls" do
    report = { "profiles": [{ "name": "empty" }] }

    expect(reporter.send_report(report)).to eq(true)
  end

  it "does not raise error for an InSpec report with controls but no results" do
    report = { "profiles": [{ "controls": [{ "id": "empty" }] }] }
    expect(reporter.send_report(report)).to eq(true)
  end

  it "raises an error for a failed InSpec report" do
    report = {
      "profiles": [
        {
          "controls": [
            { "id": "c1", "results": [{ "status": "passed" }] },
            { "id": "c2", "results": [{ "status": "failed" }] },
          ],
        },
      ],
    }

    expect {
      reporter.send_report(report)
    }.to raise_error(Chef::Compliance::Reporter::AuditEnforcer::ControlFailure, "Audit c2 has failed. Aborting chef-client run.")
  end
end
