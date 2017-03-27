#--
# Copyright:: Copyright 2016-2017, Chef Software Inc.
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
  class Node
    module Mixin
      module ImmutablizeHash
        DISALLOWED_MUTATOR_METHODS = [
          :[]=,
          :clear,
          :collect!,
          :default=,
          :default_proc=,
          :delete,
          :delete_if,
          :keep_if,
          :map!,
          :merge!,
          :update,
          :reject!,
          :replace,
          :select!,
          :shift,
          :write,
          :write!,
          :unlink,
          :unlink!,
        ]

        # Redefine all of the methods that mutate a Hash to raise an error when called.
        # This is the magic that makes this object "Immutable"
        DISALLOWED_MUTATOR_METHODS.each do |mutator_method_name|
          define_method(mutator_method_name) do |*args, &block|
            raise Exceptions::ImmutableAttributeModification
          end
        end
      end
    end
  end
end
