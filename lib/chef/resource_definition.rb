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

require File.join(File.dirname(__FILE__), "mixin", "from_file")

class Chef
  class ResourceDefinition
    
    include Chef::Mixin::FromFile
    
    attr_accessor :name, :params, :recipe
    
    def initialize
      @name = nil
      @params = Hash.new
      @recipe = nil
    end
    
    def define(resource_name, prototype_params=nil, &block)
      unless resource_name.kind_of?(Symbol)
        raise ArgumentError, "You must use a symbol when defining a new resource!"
      end
      @name = resource_name
      if prototype_params
        unless prototype_params.kind_of?(Hash)
          raise ArgumentError, "You must pass a hash as the prototype parameters for a definition."
        end
        @params = prototype_params
      end
      if Kernel.block_given?
        @recipe = block
      else
        raise ArgumentError, "You must pass a block to a definition."
      end
      true
    end
    
    # When we do the resource definition, we're really just setting new values for
    # the paramaters we prototyped at the top.  This method missing is as simple as
    # it gets.
    def method_missing(symbol, *args)
      @params[symbol] = args.length == 1 ? args[0] : args
    end
    
  end
end