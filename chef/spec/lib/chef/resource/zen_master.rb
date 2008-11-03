# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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
    class ZenMaster < Chef::Resource
      attr_reader :peace
      
      def initialize(name, collection=nil, node=nil)
        @resource_name = :zen_master
        super(name, collection, node)
      end
      
      def peace(tf)
        @peace = tf
      end
      
      def something(arg=nil)
        set_if_args(@something, arg) do
          case arg
          when true, false
            @something = arg
          end
        end
      end
    end
  end
end