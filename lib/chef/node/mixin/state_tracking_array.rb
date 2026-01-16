#--
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "immutablize_array"
require_relative "state_tracking"

class Chef
  class Node
    module Mixin
      module StateTrackingArray
        include ::Chef::Node::Mixin::StateTracking

        MUTATOR_METHODS = Chef::Node::Mixin::ImmutablizeArray::DISALLOWED_MUTATOR_METHODS

        # For all of the methods that may mutate an Array, we override them to
        # also track the state and trigger attribute_changed event.
        MUTATOR_METHODS.each do |mutator|
          define_method(mutator) do |*args, &block|
            ret = super(*args, &block)
            send_attribute_changed_event(__path__, self)
            ret
          end
        end
      end
    end
  end
end
