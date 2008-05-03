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
    class Link < Chef::Resource
            
      def initialize(name, collection=nil)
        @resource_name = :link
        super(name, collection)
        @source_file = name
        @action = :create
        @link_type = :symbolic
        @target_file = nil
        @allowed_actions.push(:create, :delete)
      end
      
      def source_file(arg=nil)
        set_or_return(
          :source_file,
          arg,
          :kind_of => String
        )
      end
      
      def target_file(arg=nil)
        set_or_return(
          :target_file,
          arg,
          :kind_of => String
        )
      end
      
      def link_type(arg=nil)
        real_arg = arg.kind_of?(String) ? arg.to_sym : arg
        set_or_return(
          :link_type,
          real_arg,
          :equal_to => [ :symbolic, :hard ]
        )
      end
      
    end
  end
end