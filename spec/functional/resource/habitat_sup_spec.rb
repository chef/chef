require 'spec_helper'

describe Chef::Resource::habitat_sup do
  context 'when compiling the sup recipe for chefspec' do
    shared_examples_for 'any platform' do
      it 'runs hab sup' do
        expect(chef_run).to run_hab_sup('tester')
      end

      it 'runs hab sup with a custom org' do
        expect(chef_run).to run_hab_sup('test-options')
          .with(
            listen_http: '0.0.0.0:9999',
            listen_gossip: '0.0.0.0:9998'
          )
      end

      it 'runs hab sup with a auth options' do
        expect(chef_run).to run_hab_sup('test-auth-token')
          .with(
            listen_http: '0.0.0.0:10001',
            listen_gossip: '0.0.0.0:10000',
            auth_token: 'test'
          )
      end

      it 'runs hab sup with a gateway auth token' do
        expect(chef_run).to run_hab_sup('test-gateway-auth-token')
          .with(
            listen_http: '0.0.0.0:10001',
            listen_gossip: '0.0.0.0:10000',
            gateway_auth_token: 'secret'
          )
      end

      it 'run hab sup with a single peer' do
        expect(chef_run).to run_hab_sup('single_peer').with(
          peer: ['127.0.0.2']
        )
      end

      it 'runs hab sup with multiple peers' do
        expect(chef_run).to run_hab_sup('multiple_peers')
          .with(
            peer: ['127.0.0.2', '127.0.0.3']
          )
      end
      # Commenting out 20201030 - test works locally but failing in GitHub delivery
      # it 'handles installing hab for us' do
      #   expect(chef_run).to install_hab_install('tester')
      # end

      it 'installs hab-sup package' do
        expect(chef_run).to install_hab_package('core/hab-sup')
      end

      it 'installs hab-launcher package' do
        expect(chef_run).to install_hab_package('core/hab-launcher')
      end
    end

    context 'a Systemd platform' do
      cached(:chef_run) do
        ChefSpec::ServerRunner.new(
          step_into: ['hab_sup'],
          platform: 'ubuntu',
          version: '16.04'
        ).converge(described_recipe)
      end

      before(:each) do
        allow(Chef::Platform::ServiceHelpers).to receive(:service_resource_providers).and_return([:systemd])
      end

      it_behaves_like 'any platform'

      it 'runs hab sup with a set file limit' do
        expect(chef_run).to run_hab_sup('set_file_limit')
          .with(
            limit_no_files: '65536'
          )
      end

      it 'renders a systemd_unit file with default options' do
        expect(chef_run).to create_systemd_unit('hab-sup.service').with(
          content: {
            Unit: {
              Description: 'The Habitat Supervisor',
            },
            Service: {
              Environment: [],
              ExecStart: '/bin/hab sup run --listen-gossip 0.0.0.0:7998 --listen-http 0.0.0.0:7999 --peer 127.0.0.2 --peer 127.0.0.3',
              ExecStop: '/bin/hab sup term',
              Restart: 'on-failure',
            },
            Install: {
              WantedBy: 'default.target',
            },
          }
        )
      end

      it 'starts the hab-sup service' do
        expect(chef_run).to start_service('hab-sup')
        expect(chef_run.service('hab-sup'))
          .to subscribe_to('systemd_unit[hab-sup.service]')
          .on(:restart).delayed
        expect(chef_run.service('hab-sup'))
          .to subscribe_to('hab_package[core/hab-sup]')
          .on(:restart).delayed
        expect(chef_run.service('hab-sup'))
          .to subscribe_to('hab_package[core/hab-launcher]')
          .on(:restart).delayed
      end
    end
  end
end
