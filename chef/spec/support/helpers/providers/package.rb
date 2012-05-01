module SpecHelpers
  module Providers
    module Package
      extend ActiveSupport::Concern

      included do
        include SpecHelpers::Provider

        let(:package_name) { 'chef' }

        let(:new_resource) { Chef::Resource::Package.new(package_name) }
        let(:current_resource) { Chef::Resource::Package.new(package_name) }
        let(:provider) { described_class.new(new_resource, run_context) }

        let(:assume_new_resource) { provider.new_resource = new_resource }
        let(:assume_current_resource) { provider.current_resource = current_resource }

        let(:status) { mock("Status", :exitstatus => exitstatus, :stdout => stdout) }
        let(:exitstatus) { 0 }

        let(:stdout) { StringIO.new }
        let(:stderr) { StringIO.new }
        let(:stdin) { StringIO.new }

        let(:should_shell_out!) { provider.should_receive(:shell_out!).and_return(status) }
      end
    end
  end
end
