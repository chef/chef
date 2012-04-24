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
        let(:stdout) { StringIO.new }
        let(:status) { mock("Status", :exitstatus => exitstatus, :stdout => stdout) }
        let(:exitstatus) { 0 }
      end
    end
  end
end
