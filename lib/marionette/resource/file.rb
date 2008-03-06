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
      attr_accessor :backup, :checksum, :ensure, :force, :group, :ignore, :links,
                    :mode, :owner, :path, :purge, :recurse, :replace, :target
      
      def initialize(name)
        super(name)
        @backup = true
        @checksum = "md5sum"
      end
      
      def backup
        @backup
      end
      
      def backup=(arg)
        case arg
        when true
          @backup = true
        when false
          @backup = false
        when Integer
          @backup = arg  
        else
          raise ArgumentError, "backup must be true, false, or a number!"
        end
      end
      
      def checksum
        @checksum
      end
      
      def checksum=(arg)
        case arg
        when "md5sum"
          @checksum = arg
        when "mtime"
          @checksum = arg
        else
          raise ArgumentError, "checksum must be md5sum or mtime!"
        end
      end
      
    end
  end
end