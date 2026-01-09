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

class Chef
  class Node
    module Mixin
      # missing methods for Arrays similar to Chef::Mash methods that call
      # convert_value correctly.
      module MashyArray
        def <<(obj)
          super(convert_value(obj))
        end

        def []=(*keys, value)
          super(*keys, convert_value(value))
        end

        def push(*objs)
          objs = objs.map { |obj| convert_value(obj) }
          super(*objs)
        end

        def unshift(*objs)
          objs = objs.map { |obj| convert_value(obj) }
          super(*objs)
        end

        def insert(index, *objs)
          objs = objs.map { |obj| convert_value(obj) }
          super(index, *objs)
        end

        def collect!(&block)
          super
          map! { |x| convert_value(x) }
        end

        def map!(&block)
          super
          super { |x| convert_value(x) }
        end

        def fill(*args, &block)
          super
          map! { |x| convert_value(x) }
        end

        def replace(obj)
          super(convert_value(obj))
        end
      end
    end
  end
end
