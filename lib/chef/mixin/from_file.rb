#
# Chef::Mixin::FromFile 
#
# A mixin that adds instance_eval support to a given object.
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
  module Mixin
    module FromFile
    
      # Loads a given ruby file, and runs instance_eval against it in the context of the current 
      # object.  
      #
      # Raises an IOError if the file cannot be found, or is not readable.
      def from_file(filename)
        if File.exists?(filename) && File.readable?(filename)
          self.instance_eval(IO.read(filename), filename, 1)
        else
          raise IOError, "Cannot open or read #{filename}!"
        end
      end
    end
  end
end
