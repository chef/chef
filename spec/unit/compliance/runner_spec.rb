require "spec_helper"

describe Chef::Compliance::Runner do
  let(:logger) { double(:logger).as_null_object }
  let(:node) { Chef::Node.new(logger: logger) }

  let(:runner) do
    described_class.new.tap do |r|
      r.node = node
      r.run_id = "my_run_id"
    end
  end

  describe "#enabled?" do
    context "when the node is not available" do
      let(:runner) { described_class.new }
      it "is false because it needs the node to answer that question" do
        expect(runner).not_to be_enabled
      end
    end

    it "is true if the node attributes have audit profiles and the audit cookbook is not present, and the compliance mode attribute is nil" do
      node.normal["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      node.normal["audit"]["compliance_phase"] = nil

      expect(runner).to be_enabled
    end

    it "is true if the node attributes have audit profiles and the audit cookbook is not present, and the compliance mode attribute is true" do
      node.normal["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      node.normal["audit"]["compliance_phase"] = true

      expect(runner).to be_enabled
    end

    it "is false if the node attributes have audit profiles and the audit cookbook is not present, and the compliance mode attribute is false" do
      node.normal["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      node.normal["audit"]["compliance_phase"] = false

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes have audit profiles and the audit cookbook is present, and the complince mode attribute is nil" do
      stub_const("::Reporter::ChefAutomate", true)
      node.normal["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      node.normal["audit"]["compliance_phase"] = nil

      expect(runner).not_to be_enabled
    end

    it "is true if the node attributes have audit profiles and the audit cookbook is present, and the complince mode attribute is true" do
      stub_const("::Reporter::ChefAutomate", true)
      node.normal["audit"]["profiles"]["ssh"] = { 'compliance': "base/ssh" }
      node.normal["audit"]["compliance_phase"] = true

      expect(runner).to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is not present, and the complince mode attribute is nil" do
      node.normal["audit"]["profiles"] = {}
      node.normal["audit"]["compliance_phase"] = nil

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit profiles and the audit cookbook is present, and the complince mode attribute is nil" do
      stub_const("::Reporter::ChefAutomate", true)
      node.automatic["recipes"] = %w{ audit::default fancy_cookbook::fanciness tacobell::nachos }
      node.normal["audit"]["compliance_phase"] = nil

      expect(runner).not_to be_enabled
    end

    it "is false if the node attributes do not have audit attributes and the audit cookbook is not present, and the complince mode attribute is nil" do
      node.automatic["recipes"] = %w{ fancy_cookbook::fanciness tacobell::nachos }
      node.normal["audit"]["compliance_phase"] = nil

      expect(runner).not_to be_enabled
    end

    it "is true if the node attributes do not have audit profiles and the audit cookbook is not present, and the complince mode attribute is true" do
      node.normal["audit"]["profiles"] = {}
      node.normal["audit"]["compliance_phase"] = true

      expect(runner).to be_enabled
    end

    it "is true if the node attributes do not have audit profiles and the audit cookbook is present, and the complince mode attribute is true" do
      stub_const("::Reporter::ChefAutomate", true)
      node.automatic["recipes"] = %w{ audit::default fancy_cookbook::fanciness tacobell::nachos }
      node.normal["audit"]["compliance_phase"] = true

      expect(runner).to be_enabled
    end

    it "is true if the node attributes do not have audit attributes and the audit cookbook is not present, and the complince mode attribute is true" do
      node.automatic["recipes"] = %w{ fancy_cookbook::fanciness tacobell::nachos }
      node.normal["audit"]["compliance_phase"] = true
      expect(runner).to be_enabled
    end
  end

  describe "#inspec_profiles" do
    it "returns an empty list with no profiles defined" do
      expect(runner.inspec_profiles).to eq([])
    end

    it "converts from the attribute format to the format Inspec expects" do
      node.normal["audit"]["profiles"]["linux-baseline"] = {
        'compliance': "user/linux-baseline",
        'version': "2.1.0",
      }

      node.normal["audit"]["profiles"]["ssh"] = {
        'supermarket': "hardening/ssh-hardening",
      }

      expected = [
        {
          compliance: "user/linux-baseline",
          name: "linux-baseline",
          version: "2.1.0",
        },
        {
          name: "ssh",
          supermarket: "hardening/ssh-hardening",
        },
      ]

      expect(runner.inspec_profiles).to eq(expected)
    end

    it "raises a CMPL010 message when the profiles are in the old audit-cookbook format" do
      node.normal["audit"]["profiles"] = [
        {
          name: "Windows 2019 Baseline",
          compliance: "admin/windows-2019-baseline",
        },
      ]

      expect { runner.inspec_profiles }.to raise_error(/CMPL010:/)
    end
  end

  describe "#warn_for_deprecated_config_values!" do
    it "logs a warning when deprecated config values are present" do
      node.normal["audit"]["owner"] = "my_org"
      node.normal["audit"]["inspec_version"] = "90210"

      expect(logger).to receive(:warn).with(/config values 'inspec_version', 'owner' are not supported/)

      runner.warn_for_deprecated_config_values!
    end

    it "does not log a warning with no deprecated config values" do
      node.normal["audit"]["profiles"]["linux-baseline"] = {
        'compliance': "user/linux-baseline",
        'version': "2.1.0",
      }

      expect(logger).not_to receive(:warn)

      runner.warn_for_deprecated_config_values!
    end
  end

  describe "#reporter" do
    context "chef-server-automate reporter" do
      it "uses the correct URL when 'server' attribute is set" do
        Chef::Config[:chef_server_url] = "https://chef_config_url.example.com/my_org"
        node.normal["audit"]["server"] = "https://server_attribute_url.example.com/application/sub_application"

        reporter = runner.reporter("chef-server-automate")

        expect(reporter).to be_kind_of(Chef::Compliance::Reporter::ChefServerAutomate)
        expect(reporter.url).to eq(URI("https://server_attribute_url.example.com/application/sub_application/organizations/my_org/data-collector"))
      end

      it "falls back to chef_server_url for URL when 'server' attribute is not set" do
        Chef::Config[:chef_server_url] = "https://chef_config_url.example.com/my_org"

        reporter = runner.reporter("chef-server-automate")

        expect(reporter).to be_kind_of(Chef::Compliance::Reporter::ChefServerAutomate)
        expect(reporter.url).to eq(URI("https://chef_config_url.example.com/organizations/my_org/data-collector"))
      end
    end

  end

  describe "#load_and_validate! when compliance is enabled" do
    before do
      allow(runner).to receive(:enabled?).and_return(true)
    end

    it "raises CMPL003 when the reporter is not a supported reporter type" do
      node.normal["audit"]["reporter"] = [ "invalid" ]
      expect { runner.load_and_validate! }.to raise_error(/^CMPL003:/)
    end
    it "raises CMPL002 if the configured fetcher is not supported" do
      node.normal["audit"]["fetcher"] = "invalid"
      expect { runner.load_and_validate! }.to raise_error(/^CMPL002:/)
    end

    it "validates configured reporters" do
      node.normal["audit"]["reporter"] = [ "chef-automate" ]
      reporter_double = double("reporter", validate_config!: nil)
      expect(runner).to receive(:reporter).with("chef-automate").and_return(reporter_double)
      runner.load_and_validate!
    end

  end

  describe "#inspec_opts" do
    it "does not include chef_node in inputs by default" do
      node.normal["audit"]["attributes"] = {
        "tacos" => "lunch",
        "nachos" => "dinner",
      }

      inputs = runner.inspec_opts[:inputs]

      expect(inputs["tacos"]).to eq("lunch")
      expect(inputs.key?("chef_node")).to eq(false)
    end

    it "includes chef_node in inputs with chef_node_attribute_enabled set" do
      node.normal["audit"]["chef_node_attribute_enabled"] = true
      node.normal["audit"]["attributes"] = {
        "tacos" => "lunch",
        "nachos" => "dinner",
      }

      inputs = runner.inspec_opts[:inputs]

      expect(inputs["tacos"]).to eq("lunch")
      expect(inputs["chef_node"]["audit"]["reporter"]).to eq(%w{json-file cli})
      expect(inputs["chef_node"]["chef_environment"]).to eq("_default")
    end
  end
end
