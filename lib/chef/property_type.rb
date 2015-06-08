require 'chef/exceptions'
require 'chef/delayed_evaluator'

class Chef
  #
  # Type and validation information for a property on a resource.
  #
  # A property named "x" manipulates the "@x" instance variable on a
  # resource.  The *presence* of the variable (`instance_variable_defined?(@x)`)
  # tells whether the variable is defined; it may have any actual value,
  # constrained only by validation.
  #
  # Properties may have validation, defaults, and coercion, and have full
  # support for lazy values.
  #
  # @see Chef::Resource.property
  # @see Chef::DelayedEvaluator
  #
  class PropertyType
    #
    # Create a new property type.
    #
    # @param validation_options [Hash<Symbol,Object>] Validation options.  (See Chef::Mixin::ParamsValidate#validate)
    #
    def initialize(**validation_options)
      @validation_options = validation_options
    end

    #
    # Validation options.  (See Chef::Mixin::ParamsValidate#validate.)
    #
    # @return [Hash<Symbol,Object>]
    #
    attr_reader :validation_options
  end
end
