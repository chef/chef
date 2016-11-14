#--
# Copyright:: Copyright 2016, Chef Software, Inc.
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
      module StateTracking
        attr_reader :__path__
        attr_reader :__root__
        attr_reader :__node__
        attr_reader :__precedence__

        def initialize(data = nil, root = self, node = nil, precedence = nil)
          # __path__ and __root__ must be nil when we call super so it knows
          # to avoid resetting the cache on construction
          data.nil? ? super() : super(data)
          @__path__ = []
          @__root__ = root
          @__node__ = node
          @__precedence__ = precedence
        end

        def [](*args)
          ret = super
          key = args.first
          next_path = [ __path__, convert_key(key) ].flatten.compact
          copy_state_to(ret, next_path)
        end

        def []=(*args)
          ret = super
          key = args.first
          value = args.last
          next_path = [ __path__, convert_key(key) ].flatten.compact
          send_attribute_changed_event(next_path, value)
          copy_state_to(ret, next_path)
        end

        protected

        def __path__=(path)
          @__path__ = path
        end

        def __root__=(root)
          @__root__ = root
        end

        def __precedence__=(precedence)
          @__precedence__ = precedence
        end

        def __node__=(node)
          @__node__ = node
        end

        private

        def send_attribute_changed_event(next_path, value)
          if __node__ && __node__.run_context && __node__.run_context.events
            __node__.run_context.events.attribute_changed(__precedence__, next_path, value)
          end
        end

        def send_reset_cache(path = nil, key = nil)
          next_path = [ path, key ].flatten.compact
          __root__.reset_cache(next_path.first) if !__root__.nil? && __root__.respond_to?(:reset_cache) && !next_path.nil?
        end

        def copy_state_to(ret, next_path)
          if ret.is_a?(StateTracking)
            ret.__path__ = next_path
            ret.__root__ = __root__
            ret.__node__ = __node__
            ret.__precedence__ = __precedence__
          end
          ret
        end
      end
    end
  end
end
