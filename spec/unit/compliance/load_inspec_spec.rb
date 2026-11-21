require "spec_helper"
require "chef/compliance/load_inspec"
require "chef-licensing"

describe "Chef::Compliance.load_inspec!" do
  let(:config) { ChefLicensing::Config }

  # Snapshot the real configuration so this spec cannot leak into others.
  around do |example|
    saved = config.instance_variables.to_h { |iv| [iv, config.instance_variable_get(iv)] }
    example.run
  ensure
    (config.instance_variables - saved.keys).each { |iv| config.remove_instance_variable(iv) }
    saved.each { |iv, value| config.instance_variable_set(iv, value) }
  end

  before do
    # Pretend InSpec has not been loaded yet, whatever other specs have done.
    hide_const("Inspec::Runner")
    allow(Chef::Compliance).to receive(:require).and_call_original
  end

  # Loading InSpec runs inspec/utils/licensing_config.rb, which reconfigures
  # ChefLicensing for InSpec. Simulate that side effect.
  def stub_inspec_require
    allow(Chef::Compliance).to receive(:require).with("inspec") do
      ChefLicensing.configure do |c|
        c.chef_product_name = "InSpec"
        c.chef_entitlement_id = "inspec-entitlement"
        c.chef_executable_name = "inspec"
        c.license_server_url = "https://inspec.example/licensing"
        c.logger = :inspec_logger
      end
      config.instance_variable_set(:@set_only_by_inspec, true)
      true
    end
  end

  it "requires inspec" do
    stub_inspec_require
    Chef::Compliance.load_inspec!
    expect(Chef::Compliance).to have_received(:require).with("inspec")
  end

  it "keeps the client's licensing configuration that InSpec overwrites" do
    config.chef_product_name = "Infra"
    config.chef_entitlement_id = Chef::LicensingConfig::INFRA_ENTITLEMENT_ID
    config.chef_executable_name = "chef-client"
    config.license_server_url = "https://licensing.example/from-env"
    config.logger = Chef::Log
    stub_inspec_require

    Chef::Compliance.load_inspec!

    expect(config.chef_product_name).to eq("Infra")
    expect(config.chef_entitlement_id).to eq(Chef::LicensingConfig::INFRA_ENTITLEMENT_ID)
    expect(config.chef_executable_name).to eq("chef-client")
    expect(config.instance_variable_get(:@license_server_url)).to eq("https://licensing.example/from-env")
    expect(config.logger).to eq(Chef::Log)
    expect(config.instance_variable_defined?(:@set_only_by_inspec)).to be false
  end

  it "restores the configuration when requiring inspec raises" do
    config.chef_product_name = "Infra"
    allow(Chef::Compliance).to receive(:require).with("inspec") do
      config.chef_product_name = "InSpec"
      raise LoadError, "cannot load such file -- inspec"
    end

    expect { Chef::Compliance.load_inspec! }.to raise_error(LoadError)
    expect(config.chef_product_name).to eq("Infra")
  end

  it "does nothing once InSpec is loaded" do
    stub_const("Inspec::Runner", Class.new)
    Chef::Compliance.load_inspec!
    expect(Chef::Compliance).not_to have_received(:require).with("inspec")
  end
end
