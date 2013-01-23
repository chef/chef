#
# Author:: John Hampton (<john@cleanoffer.com>)
# Copyright:: Copyright (c) 2009 CleanOffer, Inc.
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
  class Resource
    class OneTwoThreeFour < Chef::Resource
      attr_reader :i_can_count

      def initialize(name, run_context)
        @resource_name = :one_two_three_four
        super
      end

      def i_can_count(tf)
        @i_can_count = tf
      end

      def something(arg=nil)
        if arg == true or arg == false
          @something = arg
        end
        @something
      end
    end
  end
end
