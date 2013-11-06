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

class Chef
  class Resource
    class RubyBlock < Chef::Resource
      
      identity_attr :block_name
      state_attrs :whyrun_safe

      def initialize(name, run_context=nil)
        super
        @resource_name = :ruby_block
        @action = "create"
        @allowed_actions.push(:create)
        @block_name = name
        @whyrun_safe = false
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

      def whyrun_safe(arg=nil)
        set_or_return(
          :whyrun_safe,
          arg,
          :kind_of => [ TrueClass, FalseClass ]
        )
      end
    end
  end
end
