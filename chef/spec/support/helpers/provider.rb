module SpecHelpers
  module Provider
    extend ActiveSupport::Concern

    included do
      # Takes a Hash-like object and sets attributes with provided values
      # Example:
      #   Chef::Resource::User.new('adam', run_context).tap(&with_attributes.call({ :comment => 'Adam Jacob' })
      let(:with_attributes) { lambda { |attrs| lambda { |r| attrs.each { |a,v| r.send(a,v) } } } }

      # Shared setup
      let(:node) { Chef::Node.new }
      let(:run_context) { Chef::RunContext.new(node, {}) }
    end
  end
end
