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

        NULL = Object.new

        def initialize(data = NULL, root = self)
          # __path__ and __root__ must be nil when we call super so it knows
          # to avoid resetting the cache on construction
          data == NULL ? super() : super(data)
          @__path__ = []
          @__root__ = root
        end

        def [](key)
          ret = super
          if ret.is_a?(StateTracking)
            ret.__path__ = __path__ + [ convert_key(key) ]
            ret.__root__ = __root__
          end
          ret
        end

        def []=(key, value)
          ret = super
          if ret.is_a?(StateTracking)
            ret.__path__ = __path__ + [ convert_key(key) ]
            ret.__root__ = __root__
          end
          ret
        end

        protected

        def __path__=(path)
          @__path__ = path
        end

        def __root__=(root)
          @__root__ = root
        end

        private

        def send_reset_cache(path = __path__)
          __root__.reset_cache(path.first) if !__root__.nil? && __root__.respond_to?(:reset_cache) && !path.nil?
        end
      end
    end
  end
end
