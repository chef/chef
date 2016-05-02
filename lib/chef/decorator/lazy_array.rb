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

require "chef/decorator"

class Chef
  class Decorator
    # Lazy wrapper to delay construction of an object until a method is
    # called against the object.
    #
    # @example
    #   a = Chef::Decorator::Lazy.new { puts "allocated" }
    #   puts "start"
    #   puts a.class
    #
    #   outputs:
    #
    #   start
    #   allocated
    #   String
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
