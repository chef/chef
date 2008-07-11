#
# Chef::Node
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

require File.join(File.dirname(__FILE__), "mixin", "check_helper")
require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require File.join(File.dirname(__FILE__), "mixin", "from_file")

require 'rubygems'
require 'json'

class Chef
  class Node
    
    attr_accessor :attribute, :recipe_list, :couchdb_rev
    
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 3,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "node") {
              emit(doc.name, doc);
            }
          }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "node") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        },
      },
    }
    
    # Create a new Chef::Node object.
    def initialize()
      @name = nil
      @attribute = Hash.new
      @recipe_list = Array.new
      @couchdb_rev = nil
      @couchdb = Chef::CouchDB.new
    end
    
    # Find a recipe for this Chef::Node by fqdn.  Will search first for 
    # Chef::Config["node_path"]/fqdn.rb, then hostname.rb, then default.rb.
    # 
    # Returns a new Chef::Node object.
    #
    # Raises an ArgumentError if it cannot find the node. 
    def find_file(fqdn)
      node_file = nil
      host_parts = fqdn.split(".")
      hostname = host_parts[0]

      if File.exists?(File.join(Chef::Config[:node_path], "#{fqdn}.rb"))
        node_file = File.join(Chef::Config[:node_path], "#{fqdn}.rb")
      elsif File.exists?(File.join(Chef::Config[:node_path], "#{hostname}.rb"))
        node_file = File.join(Chef::Config[:node_path], "#{hostname}.rb")
      elsif File.exists?(File.join(Chef::Config[:node_path], "default.rb"))
        node_file = File.join(Chef::Config[:node_path], "default.rb")
      end
      unless node_file
        raise ArgumentError, "Cannot find a node matching #{fqdn}, not even with default.rb!" 
      end
      self.from_file(node_file)
    end
    
    # Set the name of this Node, or return the current name.
    def name(arg=nil)
      if arg != nil
        validate(
          { :name => arg }, 
          {
            :name => {
              :kind_of => String
            }
          }
        )
        @name = arg
      else
        @name
      end
    end
    
    # Return an attribute of this node.  Returns nil if the attribute is not found.
    def [](attrib)
      if @attribute.has_key?(attrib)        
        @attribute[attrib]
      elsif @attribute.has_key?(attrib.to_s)        
        @attribute[attrib.to_s]
      else
        nil
      end
    end
    
    # Set an attribute of this node
    def []=(attrib, value)
      @attribute[attrib] = value
    end
    
    # Iterates over each attribute, passing the attribute and value to the block.
    def each_attribute(&block)
      @attribute.each do |k,v|
        yield(k, v)
      end
    end
    
    # Return true if this Node has a given attribute, false if not.  Takes either a symbol or
    # a string.
    def attribute?(attrib)
      result = false
      result = @attribute.has_key?(attrib)
      return result if result
      return @attribute.has_key?(attrib.to_sym)
    end
    
    # Returns true if this Node expects a given recipe, false if not.
    def recipe?(recipe_name)
      @recipe_list.detect { |r| r == recipe_name } ? true : false
    end
    
    # Returns an Array of recipes.  If you call it with arguments, they will become the new
    # list of recipes.
    def recipes(*args)
      if args.length > 0
        @recipe_list = args.flatten
      else
        @recipe_list
      end
    end
    
    # Set an attribute based on the missing method.  If you pass an argument, we'll use that
    # to set the attribute values.  Otherwise, we'll wind up just returning the attributes
    # value.
    def method_missing(symbol, *args)
      if args.length != 0
        @attribute[symbol] = args.length == 1 ? args[0] : args
      else
        if @attribute.has_key?(symbol)
          @attribute[symbol]
        else
          raise ArgumentError, "Attribute #{symbol.to_s} is not defined!"
        end
      end
    end
    
    def to_index
      index_hash = {
        :index_name => "node",
        :id => "node_#{@name}",
        :name => @name,
      }
      @attribute.each do |key, value|
        index_hash[key] = value
      end
      index_hash[:recipe] = @recipe_list if @recipe_list.length > 0
      index_hash
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      result = {
        "name" => @name,
        'json_class' => self.class.name,
        "attributes" => @attribute,
        "chef_type" => "node",
        "recipes" => @recipe_list,
      }
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result.to_json(*a)
    end
    
    # Create a Chef::Node from JSON
    def self.json_create(o)
      node = new
      node.name(o["name"])
      o["attributes"].each do |k,v|
        node[k] = v
      end
      o["recipes"].each do |r|
        node.recipes << r
      end
      node.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      node
    end
    
    # List all the Chef::Node objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all Nodes, fully inflated.
    def self.list(inflate=false)
      rs = Chef::CouchDB.new.list("nodes", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end
    
    # Load a node by name from CouchDB
    def self.load(name)
      Chef::CouchDB.new.load("node", name)
    end
    
    # Remove this node from the CouchDB
    def destroy
      Chef::Queue.send_msg(:queue, :remove, self)
      @couchdb.delete("node", @name, @couchdb_rev)
    end
    
    # Save this node to the CouchDB
    def save
      Chef::Queue.send_msg(:queue, :index, self)
      results = @couchdb.store("node", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Whether or not there is an OpenID Registration with this key.
    def self.has_key?(name)
      Chef::CouchDB.new.has_key?("node", name)
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      Chef::CouchDB.new.create_design_document("nodes", DESIGN_DOCUMENT)
    end
    
    # As a string
    def to_s
      "node[#{@name}]"
    end
    
  end
end