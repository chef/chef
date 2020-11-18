require "spec_helper"

describe Chef::Audit::Runner do
  let(:logger) { double(:logger).as_null_object }
  let(:node) { Chef::Node.new(logger: logger) }

  let(:runner) do
    described_class.new.tap do |r|
      r.node = node
      r.run_id = "my_run_id"
      r.recipes = []
    end
  end

  describe "#enabled?" do
    it "is true if the node attributes have audit profiles and the audit cookbook is not present" do
      node.default["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      runner.recipes = %w{ fancy_cookbook::fanciness tacobell::nachos }

      expect(runner).to be_enabled
    end

    it "is false if the node attributes have audit profiles and the audit cookbook is present" do
      node.default["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      runner.recipes = %w{ audit::default fancy_cookbook::fanciness tacobell::nachos }

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is not present" do
      node.default["audit"]["profiles"] = {}
      runner.recipes = %w{ fancy_cookbook::fanciness tacobell::nachos }

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is present" do
      node.default["audit"]["profiles"] = {}
      runner.recipes = %w{ audit::default fancy_cookbook::fanciness tacobell::nachos }

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit attributes and the audit cookbook is not present" do
      runner.recipes = %w{ fancy_cookbook::fanciness tacobell::nachos }
      expect(runner).not_to be_enabled
    end
  end
end
