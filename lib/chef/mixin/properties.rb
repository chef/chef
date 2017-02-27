require "chef/delayed_evaluator"
require "chef/mixin/params_validate"
require "chef/property"

class Chef
  module Mixin
    module Properties
      module ClassMethods
        #
        # The list of properties defined on this resource.
        #
        # Everything defined with `property` is in this list.
        #
        # @param include_superclass [Boolean] `true` to include properties defined
        #   on superclasses; `false` or `nil` to return the list of properties
        #   directly on this class.
        #
        # @return [Hash<Symbol,Property>] The list of property names and types.
        #
        def properties(include_superclass = true)
          if include_superclass
            result = {}
            ancestors.reverse_each { |c| result.merge!(c.properties(false)) if c.respond_to?(:properties) }
            result
          else
            @properties ||= {}
          end
        end

        #
        # Create a property on this resource class.
        #
        # If a superclass has this property, or if this property has already been
        # defined by this resource, this will *override* the previous value.
        #
        # @param name [Symbol] The name of the property.
        # @param type [Object,Array<Object>] The type(s) of this property.
        #   If present, this is prepended to the `is` validation option.
        # @param options [Hash<Symbol,Object>] Validation options.
        #   @option options [Object,Array] :is An object, or list of
        #     objects, that must match the value using Ruby's `===` operator
        #     (`options[:is].any? { |v| v === value }`).
        #   @option options [Object,Array] :equal_to An object, or list
        #     of objects, that must be equal to the value using Ruby's `==`
        #     operator (`options[:is].any? { |v| v == value }`)
        #   @option options [Regexp,Array<Regexp>] :regex An object, or
        #     list of objects, that must match the value with `regex.match(value)`.
        #   @option options [Class,Array<Class>] :kind_of A class, or
        #     list of classes, that the value must be an instance of.
        #   @option options [Hash<String,Proc>] :callbacks A hash of
        #     messages -> procs, all of which match the value. The proc must
        #     return a truthy or falsey value (true means it matches).
        #   @option options [Symbol,Array<Symbol>] :respond_to A method
        #     name, or list of method names, the value must respond to.
        #   @option options [Symbol,Array<Symbol>] :cannot_be A property,
        #     or a list of properties, that the value cannot have (such as `:nil` or
        #     `:empty`). The method with a questionmark at the end is called on the
        #     value (e.g. `value.empty?`). If the value does not have this method,
        #     it is considered valid (i.e. if you don't respond to `empty?` we
        #     assume you are not empty).
        #   @option options [Proc] :coerce A proc which will be called to
        #     transform the user input to canonical form. The value is passed in,
        #     and the transformed value returned as output. Lazy values will *not*
        #     be passed to this method until after they are evaluated. Called in the
        #     context of the resource (meaning you can access other properties).
        #   @option options [Boolean] :required `true` if this property
        #     must be present; `false` otherwise. This is checked after the resource
        #     is fully initialized.
        #   @option options [Boolean] :name_property `true` if this
        #     property defaults to the same value as `name`. Equivalent to
        #     `default: lazy { name }`, except that #property_is_set? will
        #     return `true` if the property is set *or* if `name` is set.
        #   @option options [Boolean] :name_attribute Same as `name_property`.
        #   @option options [Object] :default The value this property
        #     will return if the user does not set one. If this is `lazy`, it will
        #     be run in the context of the instance (and able to access other
        #     properties).
        #   @option options [Boolean] :desired_state `true` if this property is
        #     part of desired state. Defaults to `true`.
        #   @option options [Boolean] :identity `true` if this property
        #     is part of object identity. Defaults to `false`.
        #   @option options [Boolean] :sensitive `true` if this property could
        #     contain sensitive information and whose value should be redacted
        #     in any resource reporting / auditing output. Defaults to `false`.
        #
        # @example Bare property
        #   property :x
        #
        # @example With just a type
        #   property :x, String
        #
        # @example With just options
        #   property :x, default: 'hi'
        #
        # @example With type and options
        #   property :x, String, default: 'hi'
        #
        def property(name, type = NOT_PASSED, **options)
          name = name.to_sym

          options = options.inject({}) { |memo, (key, value)| memo[key.to_sym] = value; memo }

          options[:instance_variable_name] = :"@#{name}" if !options.has_key?(:instance_variable_name)
          options[:name] = name
          options[:declared_in] = self

          if type == NOT_PASSED
            # If a type is not passed, the property derives from the
            # superclass property (if any)
            if properties.has_key?(name)
              property = properties[name].derive(**options)
            else
              property = property_type(**options)
            end

          # If a Property is specified, derive a new one from that.
          elsif type.is_a?(Property) || (type.is_a?(Class) && type <= Property)
            property = type.derive(**options)

          # If a primitive type was passed, combine it with "is"
          else
            if options[:is]
              options[:is] = ([ type ] + [ options[:is] ]).flatten(1)
            else
              options[:is] = type
            end
            property = property_type(**options)
          end

          local_properties = properties(false)
          local_properties[name] = property

          property.emit_dsl
        end

        #
        # Create a reusable property type that can be used in multiple properties
        # in different resources.
        #
        # @param options [Hash<Symbol,Object>] Validation options. see #property for
        #   the list of options.
        #
        # @example
        #   property_type(default: 'hi')
        #
        def property_type(**options)
          Property.derive(**options)
        end

        #
        # Create a lazy value for assignment to a default value.
        #
        # @param block The block to run when the value is retrieved.
        #
        # @return [Chef::DelayedEvaluator] The lazy value
        #
        def lazy(&block)
          DelayedEvaluator.new(&block)
        end

        #
        # Get or set the list of desired state properties for this resource.
        #
        # State properties are properties that describe the desired state
        # of the system, such as file permissions or ownership.
        # In general, state properties are properties that could be populated by
        # examining the state of the system (e.g., File.stat can tell you the
        # permissions on an existing file). Contrarily, properties that are not
        # "state properties" usually modify the way Chef itself behaves, for example
        # by providing additional options for a package manager to use when
        # installing a package.
        #
        # This list is used by the Chef client auditing system to extract
        # information from resources to describe changes made to the system.
        #
        # This method is unnecessary when declaring properties with `property`;
        # properties are added to state_properties by default, and can be turned off
        # with `desired_state: false`.
        #
        # ```ruby
        # property :x # part of desired state
        # property :y, desired_state: false # not part of desired state
        # ```
        #
        # @param names [Array<Symbol>] A list of property names to set as desired
        #   state.
        #
        # @return [Array<Property>] All properties in desired state.
        #
        def state_properties(*names)
          if !names.empty?
            names = names.map { |name| name.to_sym }.uniq

            local_properties = properties(false)
            # Add new properties to the list.
            names.each do |name|
              property = properties[name]
              if !property
                self.property name, instance_variable_name: false, desired_state: true
              elsif !property.desired_state?
                self.property name, desired_state: true
              end
            end

            # If state_attrs *excludes* something which is currently desired state,
            # mark it as desired_state: false.
            local_properties.each do |name, property|
              if property.desired_state? && !names.include?(name)
                self.property name, desired_state: false
              end
            end
          end

          properties.values.select { |property| property.desired_state? }
        end

        #
        # Set the identity of this resource to a particular set of properties.
        #
        # This drives #identity, which returns data that uniquely refers to a given
        # resource on the given node (in such a way that it can be correlated
        # across Chef runs).
        #
        # This method is unnecessary when declaring properties with `property`;
        # properties can be added to identity during declaration with
        # `identity: true`.
        #
        # ```ruby
        # property :x, identity: true # part of identity
        # property :y # not part of identity
        # ```
        #
        # If no properties are marked as identity, "name" is considered the identity.
        #
        # @param names [Array<Symbol>] A list of property names to set as the identity.
        #
        # @return [Array<Property>] All identity properties.
        #
        def identity_properties(*names)
          if !names.empty?
            names = names.map { |name| name.to_sym }

            # Add or change properties that are not part of the identity.
            names.each do |name|
              property = properties[name]
              if !property
                self.property name, instance_variable_name: false, identity: true
              elsif !property.identity?
                self.property name, identity: true
              end
            end

            # If identity_properties *excludes* something which is currently part of
            # the identity, mark it as identity: false.
            properties.each do |name, property|
              if property.identity? && !names.include?(name)

                self.property name, identity: false
              end
            end
          end

          result = properties.values.select { |property| property.identity? }
          result = [ properties[:name] ] if result.empty?
          result
        end

        def included(other)
          other.extend ClassMethods
        end
      end

      def self.included(other)
        other.extend ClassMethods
      end

      include Chef::Mixin::ParamsValidate

      #
      # Whether this property has been set (or whether it has a default that has
      # been retrieved).
      #
      # @param name [Symbol] The name of the property.
      # @return [Boolean] `true` if the property has been set.
      #
      def property_is_set?(name)
        property = self.class.properties[name.to_sym]
        raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
        property.is_set?(self)
      end

      #
      # Clear this property as if it had never been set. It will thereafter return
      # the default.
      # been retrieved).
      #
      # @param name [Symbol] The name of the property.
      #
      def reset_property(name)
        property = self.class.properties[name.to_sym]
        raise ArgumentError, "Property #{name} is not defined in class #{self}" if !property
        property.reset(self)
      end
    end
  end
end
