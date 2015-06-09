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
  class Property
    #
    # Create a new property type.
    #
    # @param options [Hash<Symbol,Object>] Property options, including
    #   control options here, as well as validation options (see
    #   Chef::Mixin::ParamsValidate#validate for a description of validation
    #   options).
    #   @option options [Symbol] name The name of this property.
    #   @option options [Class] declared_in The class this property comes from.
    #   @option options [Boolean] desired_state `true` if this property is part of desired
    #     state. Defaults to `true`. If `identity` is true, `desired_state` will
    #     also be true.
    #   @option options [Boolean] identity `true` if this property is part of object
    #     identity. Defaults to `false`.
    #   @option options [Symbol] instance_variable_name The instance variable
    #     tied to this property. Must include a leading `@`. Defaults to `@<name>`.
    #     `nil` means the property is opaque and not tied to a specific instance
    #     variable.
    #
    def initialize(**options)
      @options = options

      options[:name] = options[:name].to_sym if options[:name]
      options[:instance_variable_name] = options[:instance_variable_name].to_sym if options[:instance_variable_name]
    end

    #
    # The name of this property.
    #
    # @return [String]
    #
    def name
      options[:name]
    end

    #
    # The class this property was defined in.
    #
    # @return [Class]
    #
    def declared_in
      options[:declared_in]
    end

    #
    # The instance variable associated with this property.
    #
    # Defaults to `@<name>`
    #
    # @return [Symbol]
    #
    def instance_variable_name
      if options.has_key?(:instance_variable_name)
        options[:instance_variable_name]
      elsif name
        :"@#{name}"
      end
    end

    #
    # Whether this is part of the resource's natural identity or not.
    #
    # @return [Boolean]
    #
    def identity?
      options[:identity]
    end

    #
    # Whether this is part of desired state or not.
    #
    # Defaults to true.
    #
    # identity implies desired state: if identity? is true, desired_state? will
    # be true as well.
    #
    # @return [Boolean]
    #
    def desired_state?
      return true if !options.has_key?(:desired_state)
      options[:desired_state] || identity?
    end

    #
    # Whether this is name_property or not.
    #
    # @return [Boolean]
    #
    def name_property?
      options[:name_property]
    end

    #
    # Validation options.  (See Chef::Mixin::ParamsValidate#validate.)
    #
    # @return [Hash<Symbol,Object>]
    #
    def validation_options
      options.reject { |k,v| [:declared_in,:name,:desired_state,:identity,:instance_variable_name].include?(k) }
    end

    #
    # Specialize this Property by making a duplicate with some added or
    # changed options.
    #
    # @param options [Hash<Symbol,Object>] List of options that would be passed
    #   to #initialize.
    #
    # @return [Property] The new property type.
    #
    def specialize(**modified_options)
      Property.new(**options, **modified_options)
    end

    #
    # Find out whether this property has been set.
    #
    # This will be true if:
    # - The user explicitly set the value
    # - The property has a default, and the value was retrieved.
    #
    # From this point of view, it is worth looking at this as "what does the
    # user think this value should be." In order words, if the user grabbed
    # the value, even if it was a default, they probably based calculations on
    # it. If they based calculations on it and the value changes, the rest of
    # the world gets inconsistent.
    #
    # @param resource [Chef::Resource] The resource to get the property from.
    #
    # @return [Boolean]
    #
    def is_set?(resource)
      return true if !instance_variable_name
      resource.instance_variable_defined?(instance_variable_name)
    end

    protected

    attr_reader :options
  end
end
