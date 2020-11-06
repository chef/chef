require "spec_helper"

describe Chef::Audit::Runner do
  let(:test_class) do
    Class.new(Chef::Audit::Runner) do
      def initialize(run_status = nil)
        @run_status = run_status
      end
    end
  end

  describe "#enabled?" do
    let(:cookbook_collection) { Chef::CookbookCollection.new }
    let(:event_dispatcher) { Chef::EventDispatch::Dispatcher.new }
    let(:node) { Chef::Node.new(logger: double(:logger).as_null_object) }
    let(:run_context) { Chef::RunContext.new(node, cookbook_collection, event_dispatcher) }
    let(:run_status) do
      Chef::RunStatus.new(node, event_dispatcher).tap do |rs|
        rs.run_context = run_context
      end
    end

    let(:runner) { test_class.new(run_status) }

    it "is true if the node attributes have audit profiles and the audit cookbook is not present" do
      node.default["audit"] = {}
      node.default["audit"]["profiles"] = {}
      node.default["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }

      expect(runner).to be_enabled
    end

    it "is false if the node attributes have audit profiles and the audit cookbook is present" do
      node.default["audit"] = {}
      node.default["audit"]["profiles"] = {}
      node.default["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }

      cookbook_collection["audit"] = double(:audit_cookbook, version: "1.2.3")

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is not present" do
      node.default["audit"] = {}
      node.default["audit"]["profiles"] = {}

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is present" do
      node.default["audit"] = {}
      node.default["audit"]["profiles"] = {}

      cookbook_collection["audit"] = double(:audit_cookbook, version: "1.2.3")

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit attributes and the audit cookbook is not present" do
      expect(runner).not_to be_enabled
    end
  end
end
