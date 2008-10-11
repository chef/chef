#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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
    class Execute < Chef::Resource
        
      def initialize(name, collection=nil, node=nil)
        super(name, collection, node)
        @resource_name = :execute
        @command = name
        @backup = 5
        @action = "run"
        @creates = nil
        @cwd = nil
        @environment = nil
        @group = nil
        @only_if = nil
        @path = nil
        @notify_only = false
        @returns = 0
        @timeout = nil
        @not_if = nil
        @user = nil
        @allowed_actions.push(:run)
      end
      
      def command(arg=nil)
        set_or_return(
          :command,
          arg,
          :kind_of => [ String ]
        )
      end

      def creates(arg=nil)
        set_or_return(
          :creates,
          arg,
          :kind_of => [ String ]
        )
      end
      
      def cwd(arg=nil)
        set_or_return(
          :cwd,
          arg,
          :kind_of => [ String ]
        )
      end

      def environment(arg=nil)
        set_or_return(
          :environment,
          arg,
          :kind_of => [ Hash ]
        )
      end
      
      def group(arg=nil)
        set_or_return(
          :group,
          arg,
          :kind_of => [ String, Integer ]
        )
      end
      
      def only_if(arg=nil, &blk)
        if Kernel.block_given?
          @only_if = blk
        else
          @only_if = arg if arg
        end
        @only_if
      end

      def path(arg=nil)
        set_or_return(
          :path,
          arg,
          :kind_of => [ Array ]
        )
      end
      
      def returns(arg=nil)
        set_or_return(
          :returns,
          arg,
          :kind_of => [ Integer ]
        )
      end
      
      def timeout(arg=nil)
        set_or_return(
          :timeout,
          arg,
          :kind_of => [ Integer ]
        )
      end

      def not_if(arg=nil, &blk)
        if Kernel.block_given?
          @not_if = blk
        else
          @not_if = arg if arg
        end
        @not_if
      end
      
      def user(arg=nil)
        set_or_return(
          :user,
          arg,
          :kind_of => [ String, Integer ]
        )
      end

    end
  end
end