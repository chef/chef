#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

class Chef
  NOT_PASSED = Object.new

  class DelayedEvaluator < Proc
  end
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
      # :default:: Sets the default value for this parameter.
      # :callbacks:: Takes a hash of Procs, which should return true if the argument is valid.
      #              The key will be inserted into the error message if the Proc does not return true:
      #                 "Option #{key}'s value #{value} #{message}!"
      # :kind_of:: Ensure that the value is a kind_of?(Whatever).  If passed an array, it will ensure
      #            that the value is one of those types.
      # :respond_to:: Ensure that the value has a given method.  Takes one method name or an array of
      #               method names.
      # :required:: Raise an exception if this parameter is missing. Valid values are true or false,
      #             by default, options are not required.
      # :regex:: Match the value of the parameter against a regular expression.
      # :equal_to:: Match the value of the parameter with ==.  An array means it can be equal to any
      #             of the values.
      def validate(opts, map)
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
              check_method = "_pv_#{check.to_s}"
              if self.respond_to?(check_method, true)
                self.send(check_method, opts, key, carg)
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
        symbol = symbol.to_sym
        iv_symbol = :"@#{symbol}"

        # If the user passed NOT_PASSED, or passed nil, then this is a get.
        if value == NOT_PASSED || (value.nil? && !explicitly_allows_nil?(symbol, validation))

          # Get the value if there is one
          if self.instance_variable_defined?(iv_symbol)
            value = self.instance_variable_get(iv_symbol)
            if value.is_a?(DelayedEvaluator)
              # Pass optional first parameter of self
              value = value.call(self)
              value = validate({ symbol => value }, { symbol => validation })[symbol]
            end

          # Get the default value
          else
            validated = validate({}, { symbol => validation })
            if validated.has_key?(symbol)
              value = validated[symbol]

              # Handle the case where the "default" was a DelayedEvaluator. In
              # this case, the block yields an optional parameter of +self+,
              # which is the equivalent of "new_resource"
              if value.is_a?(DelayedEvaluator)
                if value.arity >= 1
                  value = value.call(self)
                else
                  value = instance_eval(&value)
                end
              end

              # Defaults are presently "stickily" set on the instance
              self.instance_variable_set(iv_symbol, value)
            else
              value = nil
            end
          end

        # Set the value
        else
          unless value.is_a?(DelayedEvaluator)
            value = validate({ symbol => value }, { symbol => validation })[symbol]
          end

          self.instance_variable_set(iv_symbol, value)
        end

        value
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
      def _pv_required(opts, key, is_required=true)
        if is_required
          if (opts.has_key?(key.to_s) && !opts[key.to_s].nil?) ||
              (opts.has_key?(key.to_sym) && !opts[key.to_sym].nil?)
            true
          else
            raise Exceptions::ValidationFailed, "Required argument #{key} is missing!"
          end
        end
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
          Array(regex).each do |r|
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
            if zeproc.call(value) != true
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
      def _pv_name_property(opts, key, is_name_property=true)
        if is_name_property
          if opts[key].nil?
            opts[key] = self.instance_variable_get("@name")
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
      # @example PropertyType
      #   ```ruby
      #   type = PropertyType.new(is: String)
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
        to_be.each do |tb|
          if tb.is_a?(Proc)
            return true if instance_exec(value, &tb)
          else
            return true if tb === value
          end
        end

        if raise_error
          raise Exceptions::ValidationFailed, "Option #{key} must be one of: #{to_be.join(", ")}!  You passed #{value.inspect}."
        else
          false
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
          opts[key.to_s] = instance_exec(opts[key], &coercer)
        elsif opts.has_key?(key.to_sym)
          opts[key.to_sym] = instance_exec(opts[key], &coercer)
        end
      end
    end
  end
end
