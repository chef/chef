#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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
#

class Chef
  module Mixin


      def self.deprecated_constants
        @deprecated_constants ||= {}
      end

      # Add a deprecated constant to the Chef::Mixin namespace.
      # === Arguments
      # * name: the constant name, as a relative symbol.
      # * replacement: the constant to return instead.
      # * message: A message telling the user what to do instead.
      # === Example:
      #   deprecate_constant(:RecipeDefinitionDSLCore, Chef::DSL::Recipe, <<-EOM)
      #     Chef::Mixin::RecipeDefinitionDSLCore is deprecated, use Chef::DSL::Recipe instead.
      #   EOM
      def self.deprecate_constant(name, replacement, message)
        deprecated_constants[name] = {:replacement => replacement, :message => message}
      end

      # Const missing hook to look up deprecated constants defined with
      # deprecate_constant. Emits a warning to the logger and returns the
      # replacement constant. Will call super, most likely causing an exception
      # for the missing constant, if +name+ is not found in the
      # deprecated_constants collection.
      def self.const_missing(name)
        if new_const = deprecated_constants[name]
          Chef::Log.warn(new_const[:message])
          Chef::Log.warn("Called from: \n#{caller[0...3].map {|l| "\t#{l}"}.join("\n")}")
          new_const[:replacement]
        else
          super
        end
      end

    module Deprecation

      class DeprecatedObjectProxyBase
        KEEPERS = %w{__id__ __send__ instance_eval == equal? initialize object_id}
        instance_methods.each { |method_name| undef_method(method_name) unless KEEPERS.include?(method_name.to_s)}
      end

      class DeprecatedInstanceVariable < DeprecatedObjectProxyBase
        def initialize(target, ivar_name, level=nil)
          @target, @ivar_name = target, ivar_name
          @level ||= :warn
        end

        def method_missing(method_name, *args, &block)
          log_deprecation_msg(caller[0..3])
          @target.send(method_name, *args, &block)
        end

        def inspect
          @target.inspect
        end

        private

        def log_deprecation_msg(*called_from)
          called_from = called_from.flatten
          log("Accessing #{@ivar_name} by the variable @#{@ivar_name} is deprecated. Support will be removed in a future release.")
          log("Please update your cookbooks to use #{@ivar_name} in place of @#{@ivar_name}. Accessed from:")
          called_from.each {|l| log(l)}
        end

        def log(msg)
          # WTF: I don't get the log prefix (i.e., "[timestamp] LEVEL:") if I
          # send to Chef::Log. No one but me should use method_missing, ever.
          Chef::Log.logger.send(@level, msg)
        end

      end

      def deprecated_ivar(obj, name, level=nil)
        DeprecatedInstanceVariable.new(obj, name, level)
      end

    end
  end
end
