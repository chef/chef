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

class Marionette
  class Resource
    class File < Marionette::Resource
      attr_reader :backup, :checksum, :ensure, :group, :mode, :owner, :path
      
      def initialize(name, dg=nil)
        @resource_name = :file
        super(name, dg)
        @path = name
        @backup = true
        @checksum = "md5sum"
      end

      def backup=(arg)
        case arg
        when true, false, Integer
          @backup = arg 
        else
          raise ArgumentError, "backup must be true, false, or a number!"
        end
      end
      
      def checksum=(arg)
        case arg
        when "md5sum", "mtime"
          @checksum = arg
        else
          raise ArgumentError, "checksum must be md5sum or mtime!"
        end
      end
      
      def ensure=(arg)
        case arg
        when "absent", "present"
          @ensure = arg
        else
          raise ArgumentError, "ensure must be absent or present!"
        end
      end
      
      def group=(arg)
        case arg
        when /^([a-z]|[A-Z]|[0-9]|_|-)+$/, Integer
          @group = arg
        else
          raise ArgumentError, "group must match /^([a-z]|[A-Z]|[0-9]|_|-)$/, Integer!"
        end
      end
      
      def mode=(arg)
        case "#{arg.to_s}"
        when /^\d{3,4}$/
          @mode = arg
        else
          raise ArgumentError, "mode must be a valid unix file mode - 3 or 4 digets!"
        end
      end
      
      def owner=(arg)
        case arg
        when /^([a-z]|[A-Z]|[0-9]|_|-)+$/, Integer
          @group = arg
        else
          raise ArgumentError, "group must match /^([a-z]|[A-Z]|[0-9]|_|-)$/, Integer!"
        end
      end
      
      def path=(arg)
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