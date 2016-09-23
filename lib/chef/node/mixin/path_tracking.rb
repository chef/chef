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
      module PathTracking
        attr_reader :__path

        def initialize(*args)
          super
          @__path = []
        end

        def [](key)
          ret = super
          ret.__path = __path + [ convert_key(key) ] if ret.is_a?(PathTracking)
          ret
        end

        def []=(key, value)
          ret = super
          ret.__path = __path + [ convert_key(key) ] if ret.is_a?(PathTracking)
          ret
        end

        protected

        def __path=(path)
          @__path = path
        end
      end
    end
  end
end
