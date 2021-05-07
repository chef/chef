require 'spec_helper'

describe Chef::Resource::HabitatService do

  before(:each) do
    allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return([:systemd])
  end

  context 'when compiling the service recipe for chefspec' do
    it 'loads service' do
      expect(chef_run).to load_habitat_service('core/nginx')
    end

    it 'stops service' do
      expect(chef_run).to stop_habitat_service('core/redis stop')
    end

    it 'unloads service' do
      expect(chef_run).to unload_habitat_service('core/nginx unload')
    end

    it 'loads a service with version' do
      expect(chef_run).to load_habitat_service('core/vault version change').with(
        service_name: 'core/vault/1.1.5'
      )
    end

    it 'loads a service with version and release' do
      expect(chef_run).to load_habitat_service('core/grafana full identifier').with(
        service_name: 'core/grafana/6.4.3/20191105024430'
      )
    end

    it 'loads a service with options' do
      expect(chef_run).to load_habitat_service('core/grafana property change from custom values').with(
        service_group: 'test',
        bldr_url: 'https://bldr-test.habitat.sh',
        channel: :'bldr-1321420393699319808',
        topology: :standalone,
        strategy: :'at-once',
        update_condition: :latest,
        binding_mode: :relaxed,
        shutdown_timeout: 10,
        health_check_interval: 32,
        gateway_auth_token: 'secret'
      )
    end

    it 'loads a service with a single bind' do
      expect(chef_run).to load_habitat_service('core/grafana binding').with(
        bind: [
          'prom:prometheus.default',
        ]
      )
    end

    it 'loads a service with multiple binds' do
      expect(chef_run).to load_habitat_service('core/sensu').with(
        bind: [
          'rabbitmq:rabbitmq.default',
          'redis:redis.default',
        ]
      )
    end

    it 'reloads a service' do
      expect(chef_run).to reload_habitat_service('core/consul reload')
    end

    it 'restarts a service' do
      expect(chef_run).to restart_hab_service('core/consul restart')
    end
  end
end
