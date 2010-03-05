#
# Author:: Adam Jacob (<adam@opscode.com>)
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

class Chef
  class Resource
    class User < Chef::Resource
        
      def initialize(name, collection=nil, node=nil)
        super(name, collection, node)
        @resource_name = :user
        @username = name
        @comment = nil
        @uid = nil
        @gid = nil
        @home = nil
        @shell = nil
        @password = nil
        @action = :create
        @supports = { 
          :manage_home => false,
          :non_unique => false
        }
        @allowed_actions.push(:create, :remove, :modify, :manage, :lock, :unlock)
      end
      
      def username(arg=nil)
        set_or_return(
          :username,
          arg,
          :kind_of => [ String ]
        )
      end
      
      def comment(arg=nil)
        set_or_return(
          :comment,
          arg,
          :kind_of => [ String ]
        )
      end
      
      def uid(arg=nil)
        set_or_return(
          :uid,
          arg,
          :kind_of => [ String, Integer ]
        )
      end
      
      def gid(arg=nil)
        set_or_return(
          :gid,
          arg,
          :kind_of => [ String, Integer ]
        )
      end
      
      alias_method :group, :gid
      
      def home(arg=nil)
        set_or_return(
          :home,
          arg,
          :kind_of => [ String ]
        )
      end
      
      def shell(arg=nil)
        set_or_return(
          :shell,
          arg,
          :kind_of => [ String ]
        )
      end
      
      def password(arg=nil)
        set_or_return(
          :password,
          arg,
          :kind_of => [ String ]
        )
      end
      
    end
  end
end
