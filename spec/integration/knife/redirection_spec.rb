require 'thin'
require 'support/shared/integration/integration_helper'
require 'chef/knife/list'

describe 'redirection' do
  extend IntegrationSupport
  include KnifeSupport

  when_the_chef_server 'has a role' do
    role 'x', {}

    context 'and another server redirects to it with 302' do
      before :each do
        @original_chef_server_url = Chef::Config.chef_server_url
        Chef::Config.chef_server_url = "http://127.0.0.1:9018"
        app = lambda do |env|
          [302, {'Content-Type' => 'text','Location' => "#{@original_chef_server_url}#{env['PATH_INFO']}" }, ['302 found'] ]
        end
        @redirector_server = Thin::Server.new('127.0.0.1', 9018, app, { :signals => false })
        @redirector_thread = Thread.new do
          begin
            @redirector_server.start
          rescue
            @server_error = $!
            Chef::Log.error("#{$!.message}\n#{$!.backtrace.join("\n")}")
          end
        end
        Timeout::timeout(5) do
          until @redirector_server.running? || @server_error
            sleep(0.01)
          end
          raise @server_error if @server_error
        end
      end

      after :each do
        @redirector_server.stop
        @redirector_thread.join(nil)
        @redirector_server = nil
        @redirector_thread = nil
      end

      it 'knife list /roles returns the role' do
        knife('list /roles').should_succeed "/roles/x.json\n"
      end
    end
  end
end
