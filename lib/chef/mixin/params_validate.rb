# 
# Chef::Mixin::ParamsValidate
#
# Because I can't deal with not having named params.  Strongly based on Dave Rolsky's excellent
# Params::Validate module for Perl.  Please don't blame him, though, if you hate this. :)
#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

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
      # :default:: Sets the default value for this parameter.
      # :callbacks:: Takes a hash of Procs, which should return true if the argument is valid.  
      #              The key will be inserted into the error message if the Proc does not return true:
      #                 "Option #{key}'s value #{value} #{message}!"
      # :kind_of:: Ensure that the value is a kind_of?(Whatever)
      # :respond_to:: Esnure that the value has a given method.  Takes one method name or an array of
      #               method names.
      # :required:: Raise an exception if this parameter is missing. Valid values are true or false, 
      #             by default, options are not required.
      # :regex:: Match the value of the paramater against a regular expression.
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
      
      private
      
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
            if opts.has_key?(key.to_s) || opts.has_key?(key.to_sym)
              true
            else
              raise ArgumentError, "Required argument #{key} is missing!"
            end
          end
        end
        
        # Raise an exception if the parameter is not a kind_of?(to_be)
        def _pv_kind_of(opts, key, to_be)
          value = _pv_opts_lookup(opts, key)
          if value != nil
            unless value.kind_of?(to_be)
              raise ArgumentError, "Option #{key} must be a kind of #{to_be}!  You passed #{to_be.inspect}."
            end
          end
        end
        
        # Raise an exception if the parameter does not respond to a given set of methods.
        def _pv_respond_to(opts, key, method_name_list)
          value = _pv_opts_lookup(opts, key)
          if value != nil
            method_name_list.to_a.each do |method_name|
              unless value.respond_to?(method_name)
                raise ArgumentError, "Option #{key} must have a #{method_name} method!"
              end
            end
          end
        end
      
        # Assign a default value to a parameter.
        def _pv_default(opts, key, default_value)
          value = _pv_opts_lookup(opts, key)
          if value == nil
            opts[key] = default_value
          end
        end
        
        # Check a parameter against a regular expression.
        def _pv_regex(opts, key, regex)
          value = _pv_opts_lookup(opts, key)
          if value != nil
            if regex.match(value) == nil
              raise ArgumentError, "Option #{key}'s value #{value} does not match regular expression #{regex.to_s}"
            end
          end
        end
        
        # Check a parameter against a hash of proc's.
        def _pv_callbacks(opts, key, callbacks)
          raise ArgumentError, "Callback list must be a hash!" unless callbacks.kind_of?(Hash)
          value = _pv_opts_lookup(opts, key)
          if value != nil
            callbacks.each do |message, zeproc|
              if zeproc.call(value) != true
                raise ArgumentError, "Option #{key}'s value #{value} #{message}!"
              end
            end
          end
        end
    end
  end
end

