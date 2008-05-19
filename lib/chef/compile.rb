#
# Chef::Compile
#
# Compile a nodes resources.
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
  class Compile
      
    attr_accessor :node, :cookbook_loader, :collection, :definitions
    
    def initialize()
      @node = nil
      @cookbook_loader = Chef::CookbookLoader.new
      @collection = Chef::ResourceCollection.new
      @definitions = Hash.new
    end
    
    def load_node(name)
      Chef::Log.debug("Loading Chef Node #{name}")
      @node = Chef::Node.find(name)
    end
    
    def load_definitions()
      @cookbook_loader.each do |cookbook|
        hash = cookbook.load_definitions
        @definitions.merge!(hash)
      end
    end
    
    def load_recipes
      @node.recipes.each do |recipe|
        rmatch = recipe.match(/(.+?)::(.+)/)
        if rmatch
         cookbook = @cookbook_loader[rmatch[1]]
         cookbook.load_recipe(rmatch[2], @node, @collection, @definitions, @cookbook_loader)
        else
         cookbook = @cookbook_loader[recipe]
         cookbook.load_recipe("default", @node, @collection, @definitions, @cookbook_loader)
        end
      end
    end
    
  end
end