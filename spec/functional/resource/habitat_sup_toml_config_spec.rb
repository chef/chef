require 'spec_helper'

describe Chef::Resource::habitat_sup do
  context 'When toml_config flag is set to true for hab_sup' do
    cached(:chef_run) do
      ChefSpec::ServerRunner.new(
        step_into: ['hab_sup'],
        platform: 'ubuntu',
        version: '16.04'
      ).converge(described_recipe)
    end

    before(:each) do
      allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return([:systemd])
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with('/hab').and_return(true)
      allow(Dir).to receive(:exist?).with('/hab/sup/default/config').and_return(true)
    end

    it 'Creates Supervisor toml configuration file' do
      expect(chef_run).to create_directory('/hab/sup/default/config')
      expect(chef_run).to create_template('/hab/sup/default/config/sup.toml')
    end
  end
end
