#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# 

class Chef
  class Resource
    class Directory < Chef::Resource::File
            
      def initialize(name, collection=nil)
        @resource_name = :file
        super(name, collection)
        @path = name
        @action = "create"
      end
      
      def action(arg=nil)
        set_if_args(@action, arg) do 
          case arg
          when "create", "delete", "touch", "nothing"
            @action = arg
          else
            raise ArgumentError, "action must be create, delete, or touch!"
          end
        end
      end
      
      def group(arg=nil)
        set_if_args(@group, arg) do
          case arg
          when /^([a-z]|[A-Z]|[0-9]|_|-)+$/, Integer
            @group = arg
          else
            raise ArgumentError, "group must match /^([a-z]|[A-Z]|[0-9]|_|-)$/, Integer!"
          end
        end
      end
      
      def mode(arg=nil)
        set_if_args(@mode, arg) do
          case "#{arg.to_s}"
          when /^\d{3,4}$/
            @mode = arg
          else
            raise ArgumentError, "mode must be a valid unix file mode - 3 or 4 digets!"
          end
        end
      end
      
      def owner(arg=nil)
        set_if_args(@owner, arg) do
          case arg
          when /^([a-z]|[A-Z]|[0-9]|_|-)+$/, Integer
            @owner = arg
          else
            raise ArgumentError, "group must match /^([a-z]|[A-Z]|[0-9]|_|-)$/, Integer!"
          end
        end
      end
      
      def path(arg=nil)
        set_if_args(@path, arg) do
          case arg
          when String
            @path = arg
          else
            raise ArgumentError, "path must be a string!"
          end
        end
      end
      
    end
  end
end