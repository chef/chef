#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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
    class Cron < Chef::Resource

      def initialize(name, collection=nil, node=nil)
        super(name, collection, node)
        @resource_name = :cron
        @action = :create
        @allowed_actions.push(:create, :delete)
        @minute = "*"
        @hour = "*"
        @day = "*"
        @month = "*"
        @weekday = "*"
        @command = nil
        @user = "root"
        @mailto = nil
        @path = nil
        @shell = nil
        @home = nil
      end

      def minute(arg=nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if Integer(arg) > 59 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :minute,
          converted_arg,
          :kind_of => String
        )
      end

      def hour(arg=nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if Integer(arg) > 23 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :hour,
          converted_arg,
          :kind_of => String
        )
      end

      def day(arg=nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if Integer(arg) > 31 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :day,
          converted_arg,
          :kind_of => String
        )
      end

      def month(arg=nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if Integer(arg) > 12 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :month,
          converted_arg,
          :kind_of => String
        )
      end

      def weekday(arg=nil)
        if arg.is_a?(Integer)
          converted_arg = arg.to_s
        else
          converted_arg = arg
        end
        begin
          if Integer(arg) > 7 then raise RangeError end
        rescue ArgumentError
        end
        set_or_return(
          :weekday,
          converted_arg,
          :kind_of => String
        )
      end

      def mailto(arg=nil)
        set_or_return(
          :mailto,
          arg,
          :kind_of => String
        )
      end

      def path(arg=nil)
        set_or_return(
          :path,
          arg,
          :kind_of => String
        )
      end

      def home(arg=nil)
        set_or_return(
          :home,
          arg,
          :kind_of => String
        )
      end

      def shell(arg=nil)
        set_or_return(
          :shell,
          arg,
          :kind_of => String
        )
      end

      def command(arg=nil)
        set_or_return(
          :command,
          arg,
          :kind_of => String
        )
      end

      def user(arg=nil)
        set_or_return(
          :user,
          arg,
          :kind_of => String
        )
      end
    end
  end
end


