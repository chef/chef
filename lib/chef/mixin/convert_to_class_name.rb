#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
    module ConvertToClassName
      extend self

      def convert_to_class_name(str)
        str = normalize_snake_case_name(str)
        rname = nil
        regexp = %r{^(.+?)(_(.+))?$}

        mn = str.match(regexp)
        if mn
          rname = mn[1].capitalize

          while mn && mn[3]
            mn = mn[3].match(regexp)
            rname << mn[1].capitalize if mn
          end
        end

        rname
      end

      def convert_to_snake_case(str, namespace = nil)
        str = str.dup
        str.sub!(/^#{namespace}(\:\:)?/, "") if namespace
        str.gsub!(/[A-Z]/) { |s| "_" + s }
        str.downcase!
        str.sub!(/^\_/, "")
        str
      end

      def normalize_snake_case_name(str)
        str = str.dup
        str.gsub!(/[^A-Za-z0-9_]/, "_")
        str.gsub!(/^(_+)?/, "")
        str
      end

      def snake_case_basename(str)
        with_namespace = convert_to_snake_case(str)
        with_namespace.split("::").last.sub(/^_/, "")
      end

      def filename_to_qualified_string(base, filename)
        file_base = File.basename(filename, ".rb")
        str = base.to_s + (file_base == "default" ? "" : "_#{file_base}")
        normalize_snake_case_name(str)
      end

      # Copied from rails activesupport.  In ruby >= 2.0 const_get will just do this, so this can
      # be deprecated and removed.
      #
      # MIT LICENSE is here: https://github.com/rails/rails/blob/master/activesupport/MIT-LICENSE

      # Tries to find a constant with the name specified in the argument string.
      #
      #   'Module'.constantize     # => Module
      #   'Test::Unit'.constantize # => Test::Unit
      #
      # The name is assumed to be the one of a top-level constant, no matter
      # whether it starts with "::" or not. No lexical context is taken into
      # account:
      #
      #   C = 'outside'
      #   module M
      #     C = 'inside'
      #     C               # => 'inside'
      #     'C'.constantize # => 'outside', same as ::C
      #   end
      #
      # NameError is raised when the name is not in CamelCase or the constant is
      # unknown.
      def constantize(camel_cased_word)
        names = camel_cased_word.split("::")

        # Trigger a built-in NameError exception including the ill-formed constant in the message.
        Object.const_get(camel_cased_word) if names.empty?

        # Remove the first blank element in case of '::ClassName' notation.
        names.shift if names.size > 1 && names.first.empty?

        names.inject(Object) do |constant, name|
          if constant == Object
            constant.const_get(name)
          else
            candidate = constant.const_get(name)
            next candidate if constant.const_defined?(name, false)
            next candidate unless Object.const_defined?(name)

            # Go down the ancestors to check if it is owned directly. The check
            # stops when we reach Object or the end of ancestors tree.
            constant = constant.ancestors.inject do |const, ancestor|
              break const    if ancestor == Object
              break ancestor if ancestor.const_defined?(name, false)
              const
            end

            # owner is in Object, so raise
            constant.const_get(name, false)
          end
        end
      end

    end
  end
end
