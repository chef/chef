module SpecHelpers
  module Provider
    extend ActiveSupport::Concern

    included do
      # Takes a Hash-like object and sets attributes with provided values
      # Example:
      #   Chef::Resource::User.new('adam', run_context).tap(&with_attributes.call({ :comment => 'Adam Jacob' })
      let(:with_attributes) { lambda { |attrs| lambda { |r| attrs.each { |a,v| r.send(a,v) } } } }

      # Useful for setting up node attributes:
      #   Chef::Node.new.tap(&inject_hash.call(node_attributes))
      let(:inject_hash) { lambda { |h| lambda { |x| h.each { |k,v| x[k] = v } } } }

      # Shared setup
      let(:node) { Chef::Node.new }
      let(:run_context) { Chef::RunContext.new(node, {}) }
      let(:provider) { described_class.new(new_resource, run_context) }
      let(:resource_class) { raise 'Must define resource class' }
      let(:new_resource) { resource_class.new(resource_name).tap(&with_attributes.call(new_resource_attributes)) }
      let(:current_resource) { resource_class.new(resource_name).tap(&with_attributes.call(current_resource_attributes)) }

      let(:new_resource_attributes) { { } }
      let(:current_resource_attributes) { { } }

      # shell_out! helpers
      let(:status) { mock("Status", :exitstatus => exitstatus, :stdout => stdout, :stderr => stderr) }
      let(:exitstatus) { 0 }

      let(:stdout) { StringIO.new }
      let(:stderr) { StringIO.new }
      let(:stdin) { StringIO.new }

      let(:should_shell_out!) { provider.should_receive(:shell_out!).and_return(status) }
    end
  end
end
