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
        attr_reader :__path
        attr_reader :__root

        NULL = Object.new

        def initialize(data = NULL, root = self)
          # __path and __root must be nil when we call super so it knows
          # to avoid resetting the cache on construction
          data == NULL ? super() : super(data)
          @__path = []
          @__root = root
        end

        def [](key)
          ret = super
          if ret.is_a?(StateTracking)
            ret.__path = __path + [ convert_key(key) ]
            ret.__root = __root
          end
          ret
        end

        def []=(key, value)
          ret = super
          if ret.is_a?(StateTracking)
            ret.__path = __path + [ convert_key(key) ]
            ret.__root = __root
          end
          ret
        end

        protected

        def __path=(path)
          @__path = path
        end

        def __root=(root)
          @__root = root
        end

        private

        def send_reset_cache(path = __path)
          __root.reset_cache(path.first) if !__root.nil? && __root.respond_to?(:reset_cache) && !path.nil?
        end
      end
    end
  end
end
