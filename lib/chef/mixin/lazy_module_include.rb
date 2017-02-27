#
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
    # If you have:
    #
    # module A
    #   extend LazyModuleInclude
    # end
    #
    # module B
    #   include A
    # end
    #
    # module C
    #   include B
    # end
    #
    # module Monkeypatches
    #   def monkey
    #     puts "monkey!"
    #   end
    # end
    #
    # A.send(:include, Monkeypatches)
    #
    # Then B and C and any classes that they're included in will also get the #monkey method patched into them.
    #
    module LazyModuleInclude

      # Most of the magick is in this hook which creates a closure over the parent class and then builds an
      # "infector" module which infects all descendants and which is responsible for updating the list of
      # descendants in the parent class.
      def included(klass)
        super
        parent_klass = self
        infector = Module.new do
          define_method(:included) do |subklass|
            super(subklass)
            subklass.extend(infector)
            parent_klass.descendants.push(subklass)
          end
        end
        klass.extend(infector)
        parent_klass.descendants.push(klass)
      end

      def descendants
        @descendants ||= []
      end

      def include(*classes)
        super
        classes.each do |klass|
          descendants.each do |descendant|
            descendant.send(:include, klass)
          end
        end
      end
    end
  end
end
