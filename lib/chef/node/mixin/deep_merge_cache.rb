#--
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../../delayed_evaluator"

class Chef
  class Node
    module Mixin
      module DeepMergeCache
        # Cache of deep merged values by top-level key.  This is a simple hash which has keys that are the
        # top-level keys of the node object, and we save the computed deep-merge for that key here.  There is
        # no cache of subtrees.
        attr_accessor :deep_merge_cache

        def initialize
          @merged_attributes = nil
          @combined_override = nil
          @combined_default = nil
          @deep_merge_cache = {}
        end

        # Invalidate a key in the deep_merge_cache.  If called with nil, or no arg, this will invalidate
        # the entire deep_merge cache.  In the case of the user doing node.default['foo']['bar']['baz']=
        # that eventually results in a call to reset_cache('foo') here.  A node.default=hash_thing call
        # must invalidate the entire cache and re-deep-merge the entire node object.
        def reset_cache(path = nil)
          if path.nil?
            deep_merge_cache.clear
          else
            deep_merge_cache.delete(path.to_s)
          end
        end

        alias :reset :reset_cache

        def [](key)
          ret = if deep_merge_cache.key?(key.to_s)
                  # return the cache of the deep merged values by top-level key
                  deep_merge_cache[key.to_s]
                else
                  # save all the work of computing node[key]
                  deep_merge_cache[key.to_s] = merged_attributes(key)
                end
          ret = ret.call while ret.is_a?(::Chef::DelayedEvaluator)
          ret
        end

      end
    end
  end
end
