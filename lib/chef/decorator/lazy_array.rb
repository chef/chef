#--
# Copyright:: Copyright 2016 Chef Software, Inc.
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

require "chef/decorator/lazy"

class Chef
  class Decorator
    # Lazy Array around Lazy Objects
    #
    # This only lazys access through `#[]`.  In order to implement #each we need to
    # know how many items we have and what their indexes are, so we'd have to evalute
    # the proc which makes that impossible.  You can call methods like #each and the
    # decorator will forward the method, but item access will not be lazy.
    #
    # #at() and #fetch() are not implemented but technically could be.
    #
    # @example
    #     def foo
    #         puts "allocated"
    #           "value"
    #     end
    #
    #     a = Chef::Decorator::LazyArray.new { [ foo ] }
    #
    #     puts "started"
    #     a[0]
    #     puts "still lazy"
    #     puts a[0]
    #
    #   outputs:
    #
    #     started
    #     still lazy
    #     allocated
    #     value
    #
    # @since 12.10.x
    class LazyArray < Lazy
      def [](idx)
        block = @block
        Lazy.new { block.call[idx] }
      end
    end
  end
end
