#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "chef/constants"
require "chef/property"
require "chef/delayed_evaluator"
require "chef/exceptions"

class Chef
  module Mixin
    module ParamsValidate
      # Takes a hash of options, along with a map to validate them.  Returns the original
      # options hash, plus any changes that might have been made (through things like setting
      # default values in the validation map)
      #
      # For example:
      #
      #   validate({ :one => "neat" }, { :one => { :kind_of => String }})
      #
      # Would raise an exception if the value of :one above is not a kind_of? string.  Valid
      # map options are:
      #
      # @param opts [Hash<Symbol,Object>] Validation opts.
      #   @option opts [Object,Array] :is An object, or list of
      #     objects, that must match the value using Ruby's `===` operator
      #     (`opts[:is].any? { |v| v === value }`). (See #_pv_is.)
      #   @option opts [Object,Array] :equal_to An object, or list
      #     of objects, that must be equal to the value using Ruby's `==`
      #     operator (`opts[:is].any? { |v| v == value }`)  (See #_pv_equal_to.)
      #   @option opts [Regexp,Array<Regexp>] :regex An object, or
      #     list of objects, that must match the value with `regex.match(value)`.
      #     (See #_pv_regex)
      #   @option opts [Class,Array<Class>] :kind_of A class, or
      #     list of classes, that the value must be an instance of.  (See
      #     #_pv_kind_of.)
      #   @option opts [Hash<String,Proc>] :callbacks A hash of
      #     messages -> procs, all of which match the value. The proc must
      #     return a truthy or falsey value (true means it matches).  (See
      #     #_pv_callbacks.)
      #   @option opts [Symbol,Array<Symbol>] :respond_to A method
      #     name, or list of method names, the value must respond to.  (See
      #     #_pv_respond_to.)
      #   @option opts [Symbol,Array<Symbol>] :cannot_be A property,
      #     or a list of properties, that the value cannot have (such as `:nil` or
      #     `:empty`). The method with a questionmark at the end is called on the
      #     value (e.g. `value.empty?`). If the value does not have this method,
      #     it is considered valid (i.e. if you don't respond to `empty?` we
      #     assume you are not empty).  (See #_pv_cannot_be.)
      #   @option opts [Proc] :coerce A proc which will be called to
      #     transform the user input to canonical form. The value is passed in,
      #     and the transformed value returned as output. Lazy values will *not*
      #     be passed to this method until after they are evaluated. Called in the
      #     context of the resource (meaning you can access other properties).
      #     (See #_pv_coerce.) (See #_pv_coerce.)
      #   @option opts [Boolean] :required `true` if this property
      #     must be present and not `nil`; `false` otherwise. This is checked
      #     after the resource is fully initialized. (See #_pv_required.)
      #   @option opts [Boolean] :name_property `true` if this
      #     property defaults to the same value as `name`. Equivalent to
      #     `default: lazy { name }`, except that #property_is_set? will
      #     return `true` if the property is set *or* if `name` is set. (See
      #     #_pv_name_property.)
      #   @option opts [Boolean] :name_attribute Same as `name_property`.
      #   @option opts [Object] :default The value this property
      #     will return if the user does not set one. If this is `lazy`, it will
      #     be run in the context of the instance (and able to access other
      #     properties).  (See #_pv_default.)
      #
      def validate(opts, map)
        map = map.validation_options if map.is_a?(Property)

        #--
        # validate works by taking the keys in the validation map, assuming it's a hash, and
        # looking for _pv_:symbol as methods.  Assuming it find them, it calls the right
        # one.
        #++
        raise ArgumentError, "Options must be a hash" unless opts.kind_of?(Hash)
        raise ArgumentError, "Validation Map must be a hash" unless map.kind_of?(Hash)

        map.each do |key, validation|
          unless key.kind_of?(Symbol) || key.kind_of?(String)
            raise ArgumentError, "Validation map keys must be symbols or strings!"
          end
          case validation
          when true
            _pv_required(opts, key)
          when false
            true
          when Hash
            validation.each do |check, carg|
              check_method = "_pv_#{check}"
              if respond_to?(check_method, true)
                send(check_method, opts, key, carg)
              else
                raise ArgumentError, "Validation map has unknown check: #{check}"
              end
            end
          end
        end
        opts
      end

      def lazy(&block)
        DelayedEvaluator.new(&block)
      end

      def set_or_return(symbol, value, validation)
        property = SetOrReturnProperty.new(name: symbol, **validation)
        property.call(self, value)
      end

      private

      def explicitly_allows_nil?(key, validation)
        validation.has_key?(:is) && _pv_is({ key => nil }, key, validation[:is], raise_error: false)
      end

      # Return the value of a parameter, or nil if it doesn't exist.
      def _pv_opts_lookup(opts, key)
        if opts.has_key?(key.to_s)
          opts[key.to_s]
        elsif opts.has_key?(key.to_sym)
          opts[key.to_sym]
        else
          nil
        end
      end

      # Raise an exception if the parameter is not found.
      def _pv_required(opts, key, is_required = true, explicitly_allows_nil = false)
        if is_required
          return true if opts.has_key?(key.to_s) && (explicitly_allows_nil || !opts[key.to_s].nil?)
          return true if opts.has_key?(key.to_sym) && (explicitly_allows_nil || !opts[key.to_sym].nil?)
          raise Exceptions::ValidationFailed, "Required argument #{key.inspect} is missing!"
        end
        true
      end

      #
      # List of things values must be equal to.
      #
      # Uses Ruby's `==` to evaluate (equal_to == value).  At least one must
      # match for the value to be valid.
      #
      # `nil` passes this validation automatically.
      #
      # @return [Array,nil] List of things values must be equal to, or nil if
      #   equal_to is unspecified.
      #
      def _pv_equal_to(opts, key, to_be)
        value = _pv_opts_lookup(opts, key)
        unless value.nil?
          to_be = Array(to_be)
          to_be.each do |tb|
            return true if value == tb
          end
          raise Exceptions::ValidationFailed, "Option #{key} must be equal to one of: #{to_be.join(", ")}!  You passed #{value.inspect}."
        end
      end

      #
      # List of things values must be instances of.
      #
      # Uses value.kind_of?(kind_of) to evaluate. At least one must match for
      # the value to be valid.
      #
      # `nil` automatically passes this validation.
      #
      def _pv_kind_of(opts, key, to_be)
        value = _pv_opts_lookup(opts, key)
        unless value.nil?
          to_be = Array(to_be)
          to_be.each do |tb|
            return true if value.kind_of?(tb)
          end
          raise Exceptions::ValidationFailed, "Option #{key} must be a kind of #{to_be}!  You passed #{value.inspect}."
        end
      end

      #
      # List of method names values must respond to.
      #
      # Uses value.respond_to?(respond_to) to evaluate. At least one must match
      # for the value to be valid.
      #
      def _pv_respond_to(opts, key, method_name_list)
        value = _pv_opts_lookup(opts, key)
        unless value.nil?
          Array(method_name_list).each do |method_name|
            unless value.respond_to?(method_name)
              raise Exceptions::ValidationFailed, "Option #{key} must have a #{method_name} method!"
            end
          end
        end
      end

      #
      # List of things that must not be true about the value.
      #
      # Calls `value.<thing>?` All responses must be false for the value to be
      # valid.
      # Values which do not respond to <thing>? are considered valid (because if
      # a value doesn't respond to `:readable?`, then it probably isn't
      # readable.)
      #
      # @example
      #   ```ruby
      #   property :x, cannot_be: [ :nil, :empty ]
      #   x [ 1, 2 ] #=> valid
      #   x 1        #=> valid
      #   x []       #=> invalid
      #   x nil      #=> invalid
      #   ```
      #
      def _pv_cannot_be(opts, key, predicate_method_base_name)
        value = _pv_opts_lookup(opts, key)
        if !value.nil?
          Array(predicate_method_base_name).each do |method_name|
            predicate_method = :"#{method_name}?"

            if value.respond_to?(predicate_method)
              if value.send(predicate_method)
                raise Exceptions::ValidationFailed, "Option #{key} cannot be #{predicate_method_base_name}"
              end
            end
          end
        end
      end

      #
      # The default value for a property.
      #
      # When the property is not assigned, this will be used.
      #
      # If this is a lazy value, it will either be passed the resource as a value,
      # or if the lazy proc does not take parameters, it will be run in the
      # context of the instance with instance_eval.
      #
      # @example
      #   ```ruby
      #   property :x, default: 10
      #   ```
      #
      # @example
      #   ```ruby
      #   property :x
      #   property :y, default: lazy { x+2 }
      #   ```
      #
      # @example
      #   ```ruby
      #   property :x
      #   property :y, default: lazy { |r| r.x+2 }
      #   ```
      #
      def _pv_default(opts, key, default_value)
        value = _pv_opts_lookup(opts, key)
        if value.nil?
          default_value = default_value.freeze if !default_value.is_a?(DelayedEvaluator)
          opts[key] = default_value
        end
      end

      #
      # List of regexes values that must match.
      #
      # Uses regex.match() to evaluate. At least one must match for the value to
      # be valid.
      #
      # `nil` passes regex validation automatically.
      #
      # @example
      #   ```ruby
      #   property :x, regex: [ /abc/, /xyz/ ]
      #   ```
      #
      def _pv_regex(opts, key, regex)
        value = _pv_opts_lookup(opts, key)
        if !value.nil?
          Array(regex).flatten.each do |r|
            return true if r.match(value.to_s)
          end
          raise Exceptions::ValidationFailed, "Option #{key}'s value #{value} does not match regular expression #{regex.inspect}"
        end
      end

      #
      # List of procs we pass the value to.
      #
      # All procs must return true for the value to be valid. If any procs do
      # not return true, the key will be used for the message: `"Property x's
      # value :y <message>"`.
      #
      # @example
      #   ```ruby
      #   property :x, callbacks: { "is bigger than 10" => proc { |v| v <= 10 }, "is not awesome" => proc { |v| !v.awesome }}
      #   ```
      #
      def _pv_callbacks(opts, key, callbacks)
        raise ArgumentError, "Callback list must be a hash!" unless callbacks.kind_of?(Hash)
        value = _pv_opts_lookup(opts, key)
        if !value.nil?
          callbacks.each do |message, zeproc|
            unless zeproc.call(value)
              raise Exceptions::ValidationFailed, "Option #{key}'s value #{value} #{message}!"
            end
          end
        end
      end

      #
      # Allows a parameter to default to the value of the resource name.
      #
      # @example
      #   ```ruby
      #    property :x, name_property: true
      #   ```
      #
      def _pv_name_property(opts, key, is_name_property = true)
        if is_name_property
          if opts[key].nil?
            raise Exceptions::CannotValidateStaticallyError, "name_property cannot be evaluated without a resource." if self == Chef::Mixin::ParamsValidate
            opts[key] = instance_variable_get(:"@name")
          end
        end
      end
      alias :_pv_name_attribute :_pv_name_property

      #
      # List of valid things values can be.
      #
      # Uses Ruby's `===` to evaluate (is === value).  At least one must match
      # for the value to be valid.
      #
      # If a proc is passed, it is instance_eval'd in the resource, passed the
      # value, and must return a truthy or falsey value.
      #
      # @example Class
      #   ```ruby
      #   property :x, String
      #   x 'valid' #=> valid
      #   x 1       #=> invalid
      #   x nil     #=> invalid
      #
      # @example Value
      #   ```ruby
      #   property :x, [ :a, :b, :c, nil ]
      #   x :a  #=> valid
      #   x nil #=> valid
      #   ```
      #
      # @example Regex
      #   ```ruby
      #   property :x, /bar/
      #   x 'foobar' #=> valid
      #   x 'foo'    #=> invalid
      #   x nil      #=> invalid
      #   ```
      #
      # @example Proc
      #   ```ruby
      #   property :x, proc { |x| x > y }
      #   property :y, default: 2
      #   x 3 #=> valid
      #   x 1 #=> invalid
      #   ```
      #
      # @example Property
      #   ```ruby
      #   type = Property.new(is: String)
      #   property :x, type
      #   x 'foo' #=> valid
      #   x 1     #=> invalid
      #   x nil   #=> invalid
      #   ```
      #
      # @example RSpec Matcher
      #   ```ruby
      #   include RSpec::Matchers
      #   property :x, a_string_matching /bar/
      #   x 'foobar' #=> valid
      #   x 'foo'    #=> invalid
      #   x nil      #=> invalid
      #   ```
      #
      def _pv_is(opts, key, to_be, raise_error: true)
        return true if !opts.has_key?(key.to_s) && !opts.has_key?(key.to_sym)
        value = _pv_opts_lookup(opts, key)
        to_be = [ to_be ].flatten(1)
        errors = []
        passed = to_be.any? do |tb|
          case tb
          when Proc
            raise Exceptions::CannotValidateStaticallyError, "is: proc { } must be evaluated once for each resource" if self == Chef::Mixin::ParamsValidate
            instance_exec(value, &tb)
          when Property
            begin
              validate(opts, { key => tb.validation_options })
              true
            rescue Exceptions::ValidationFailed
              # re-raise immediately if there is only one "is" so we get a better stack
              raise if to_be.size == 1
              errors << $!
              false
            end
          else
            tb === value
          end
        end
        if passed
          true
        else
          message = "Property #{key} must be one of: #{to_be.map { |v| v.inspect }.join(", ")}!  You passed #{value.inspect}."
          unless errors.empty?
            message << " Errors:\n#{errors.map { |m| "- #{m}" }.join("\n")}"
          end
          raise Exceptions::ValidationFailed, message
        end
      end

      #
      # Method to mess with a value before it is validated and stored.
      #
      # Allows you to transform values into a canonical form that is easy to
      # work with.
      #
      # This is passed the value to transform, and is run in the context of the
      # instance (so it has access to other resource properties). It must return
      # the value that will be stored in the instance.
      #
      # @example
      #   ```ruby
      #   property :x, Integer, coerce: { |v| v.to_i }
      #   ```
      #
      def _pv_coerce(opts, key, coercer)
        if opts.has_key?(key.to_s)
          raise Exceptions::CannotValidateStaticallyError, "coerce must be evaluated for each resource." if self == Chef::Mixin::ParamsValidate
          opts[key.to_s] = instance_exec(opts[key], &coercer)
        elsif opts.has_key?(key.to_sym)
          raise Exceptions::CannotValidateStaticallyError, "coerce must be evaluated for each resource." if self == Chef::Mixin::ParamsValidate
          opts[key.to_sym] = instance_exec(opts[key], &coercer)
        end
      end

      # We allow Chef::Mixin::ParamsValidate.validate(), but we will raise an
      # error if you try to do anything requiring there to be an actual resource.
      # This way, you can statically validate things if you have constant validation
      # (which is the norm).
      extend self

      # Used by #set_or_return to avoid emitting a deprecation warning for
      # "value nil" and to keep default stickiness working exactly the same
      # @api private
      class SetOrReturnProperty < Chef::Property
        def get(resource, nil_set: false)
          value = super
          # All values are sticky, frozen or not
          if !is_set?(resource)
            set_value(resource, value)
          end
          value
        end

        def call(resource, value = NOT_PASSED)
          # setting to nil does a get
          if value.nil? && !explicitly_accepts_nil?(resource)
            get(resource, nil_set: true)
          else
            super
          end
        end
      end
    end
  end
end
