module SpecHelpers
  module Providers
    module Service
      extend ActiveSupport::Concern

      included do
        include SpecHelpers::Provider

        let(:node) { Chef::Node.new.tap(&with_attributes.call(node_attributes)) }
        let(:node_attributes) { { :command= => { :ps => ps_command } } }
        let(:ps_command) { 'ps -ef' }
        let(:service_name) { 'chef' }

        let(:new_resource) { current_resource }
        let(:current_resource) { Chef::Resource::Service.new(service_name) }
        let(:provider) { described_class.new(new_resource, run_context) }
        let(:stdout) { ps_without_service_running }

        let(:ps_without_service_running) { StringIO.new(<<-PS) }
aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb
aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash
aj        8119  6041  0 21:34 pts/3    00:00:03 vi Gemfile.rb
PS

        let(:ps_with_service_running) { StringIO.new(<<-RUNNING_PS) }
aj        7842  5057  0 21:26 pts/2    00:00:06 chef
aj        7842  5057  0 21:26 pts/2    00:00:06 poos
RUNNING_PS
      end
    end
  end
end
