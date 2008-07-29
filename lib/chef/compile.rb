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
    
    # Creates a new Chef::Compile object.  This object gets used by the Chef Server to generate
    # a fully compiled recipe list for a node.
    def initialize()
      @node = nil
      @cookbook_loader = Chef::CookbookLoader.new
      @collection = Chef::ResourceCollection.new
      @definitions = Hash.new
    end
    
    # Looks up the node via the "name" argument, first from CouchDB, then by calling
    # Chef::Node.find_file(name)
    #
    # The first step in compiling the catalog. Results available via the node accessor.
    def load_node(name)
      Chef::Log.debug("Loading Chef Node #{name} from CouchDB")
      @node = Chef::Node.load(name)
      Chef::Log.debug("Loading Recipe for Chef Node #{name}")
      @node.find_file(name)
      @node
    end
    
    # Load all the definitions, from every cookbook, so they are available when we process
    # the recipes.
    #
    # Results available via the definitions accessor.
    def load_definitions()
      @cookbook_loader.each do |cookbook|
        hash = cookbook.load_definitions
        @definitions.merge!(hash)
      end
    end
    
    # Load all the recipes specified in the node data (loaded via load_node, above.)
    # 
    # The results are available via the collection accessor (which returns a Chef::ResourceCollection 
    # object)
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