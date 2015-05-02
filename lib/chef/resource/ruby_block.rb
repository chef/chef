#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/resource'
require 'chef/provider/ruby_block'

class Chef
  class Resource
    class RubyBlock < Chef::Resource
      provides :ruby_block

      identity_attr :block_name

      def initialize(name, run_context=nil)
        super
        @resource_name = :ruby_block
        @action = "run"
        @allowed_actions << :create << :run
        @block_name = name
      end

      def block(&block)
        if block_given? and block
          @block = block
        else
          @block
        end
      end

      def block_name(arg=nil)
        set_or_return(
          :block_name,
          arg,
          :kind_of => String
        )
      end
    end
  end
end
