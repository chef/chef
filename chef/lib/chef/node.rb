#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/config'
require 'chef/mixin/check_helper'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/couchdb'
require 'chef/queue'
require 'chef/run_list'
require 'chef/node/attribute'
require 'extlib'
require 'json'

class Chef
  class Node
    
    attr_accessor :attribute, :recipe_list, :couchdb_rev, :run_state, :run_list, :override, :default
    
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 8,
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
        "status" => {
          "map" => <<-EOJS
            function(doc) {
              if (doc.chef_type == "node") {
                var to_emit = { "name": doc.name };
                if (doc["attributes"]["fqdn"]) {
                  to_emit["fqdn"] = doc["attributes"]["fqdn"];
                } else {
                  to_emit["fqdn"] = "Undefined";
                }
                if (doc["attributes"]["ipaddress"]) {
                  to_emit["ipaddress"] = doc["attributes"]["ipaddress"];
                } else {
                  to_emit["ipaddress"] = "Undefined";
                }
                if (doc["attributes"]["ohai_time"]) {
                  to_emit["ohai_time"] = doc["attributes"]["ohai_time"];
                } else {
                  to_emit["ohai_time"] = "Undefined";
                } 
                if (doc["attributes"]["uptime"]) {
                  to_emit["uptime"] = doc["attributes"]["uptime"];
                } else {
                  to_emit["uptime"] = "Undefined";
                }
                if (doc["attributes"]["platform"]) {
                  to_emit["platform"] = doc["attributes"]["platform"];
                } else {
                  to_emit["platform"] = "Undefined";
                }
                if (doc["attributes"]["platform_version"]) {
                  to_emit["platform_version"] = doc["attributes"]["platform_version"];
                } else {
                  to_emit["platform_version"] = "Undefined";
                }
                if (doc["run_list"]) {
                  to_emit["run_list"] = doc["run_list"];
                } else {
                  to_emit["run_list"] = "Undefined";
                }
                emit(doc.name, to_emit);
              }
            }
          EOJS
        },
        "by_run_list" => {
          "map" => <<-EOJS
            function(doc) {
              if (doc.chef_type == "node") {
                if (doc['run_list']) {
                  for (var i=0; i < doc.run_list.length; i++) {
                    emit(doc['run_list'][i], doc.name);
                  }
                }
              }
            }
          EOJS
        }
      },
    }
    
    # Create a new Chef::Node object.
    def initialize()
      @name = nil

      @attribute = Mash.new
      @override = Mash.new
      @default = Mash.new
      @run_list = Chef::RunList.new 

      @couchdb_rev = nil
      @couchdb = Chef::CouchDB.new
      @run_state = {
        :template_cache => Hash.new,
        :seen_recipes => Hash.new
      }
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
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs[attrib] 
    end
    
    # Set an attribute of this node
    def []=(attrib, value)
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs[attrib] = value
    end

    # Set an attribute of this node, but auto-vivifiy any Mashes that might
    # be missing
    def set
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.auto_vivifiy_on_read = true
      attrs
    end

    # Set an attribute of this node, auto-vivifiying any mashes that are
    # missing, but if the final value already exists, don't set it
    def set_unless
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.auto_vivifiy_on_read = true
      attrs.set_unless_value_present = true
      attrs
    end

    alias_method :default, :set_unless

    # Return true if this Node has a given attribute, false if not.  Takes either a symbol or
    # a string.
    #
    # Only works on the top level. Preferred way is to use the normal [] style
    # lookup and call attribute?()
    def attribute?(attrib)
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.attribute?(attrib)
    end
  
    # Yield each key of the top level to the block. 
    def each(&block)
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.each(&block)
    end
    
    # Iterates over each attribute, passing the attribute and value to the block.
    def each_attribute(&block)
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.each_attribute(&block)
    end

    # Set an attribute based on the missing method.  If you pass an argument, we'll use that
    # to set the attribute values.  Otherwise, we'll wind up just returning the attributes
    # value.
    def method_missing(symbol, *args)
      attrs = Chef::Node::Attribute.new(@attribute, @default, @override)
      attrs.send(symbol, *args)
    end
    
    # Returns true if this Node expects a given recipe, false if not.
    def recipe?(recipe_name)
      if @run_list.include?(recipe_name)
        true
      else
        if @run_state[:seen_recipes].include?(recipe_name)
          true
        else
          false
        end
      end
    end
    
    # Returns an Array of recipes.  If you call it with arguments, they will become the new
    # list of recipes.
    def recipes(*args)
      if args.length > 0
        @run_list.reset(args)
      else
        @run_list
      end
    end

    # Returns true if this Node expects a given role, false if not.
    def role?(role_name)
      @run_list.include?("role[#{role_name}]")
    end

    # Returns an Array of roles and recipes, in the order they will be applied.
    # If you call it with arguments, they will become the new list of roles and recipes. 
    def run_list(*args)
      if args.length > 0
        @run_list.reset(args)
      else
        @run_list
      end
    end

    # Returns true if this Node expects a given role, false if not.
    def run_list?(item)
      @run_list.detect { |r| r == item } ? true : false
    end
    
    # Turns the node into an object that we can index.  I apologize up front for the
    # super confusion that is the recursive index_flatten hash, which comes up next.
    # Faith, young one, faith.
    #
    # === Returns
    # index_hash<Hash>:: A flattened hash of all the nodes attributes, suitable for indexing.
    def to_index
      index_hash = {
        "index_name" => "node",
        "id" => "node_#{@name}",
        "name" => @name,
      }
      @attribute.each do |key, value|
        if value.kind_of?(Hash) || value.kind_of?(Mash)
          index_flatten_hash(key, value).each do |to_index|
            to_index.each do |nk, nv|
              index_hash[nk] = nv
            end
          end
        else
          index_hash[key] = value
        end
      end
      index_hash["recipe"] = @run_list.recipes if @run_list.recipes.length > 0
      index_hash["roles"] = @run_list.roles if @run_list.roles.length > 0
      index_hash["run_list"] = @run_list.run_list if @run_list.run_list.length > 0
      index_hash
    end
    
    # Ah, song of my heart, index_flatten_hash.  This method flattens a hash in preparation
    # for indexing, by appending the name of it's parent to a current key with an _.  Hence,
    # node[:bar][:baz] = 'monkey' becomes bar_baz:monkey.
    #
    # === Returns
    # results<Array>:: An array of hashes with one element.
    def index_flatten_hash(parent_name, hash)
      results = Array.new
      hash.each do |k, v|
        if v.kind_of?(Hash) || v.kind_of?(Mash)
          results << index_flatten_hash("#{parent_name}_#{k}", v)
        else
          results << { "#{parent_name}_#{k}", v }
        end
      end
      results.flatten
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      result = {
        "name" => @name,
        'json_class' => self.class.name,
        "attributes" => @attribute,
        "chef_type" => "node",
        "run_list" => @run_list.run_list,
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
      if o.has_key?("defaults")
        node.default = o["defaults"]
      end
      if o.has_key?("overrides")
        node.override = o["overrides"]
      end
      if o.has_key?("run_list")
        node.run_list.reset(o["run_list"])
      else
        o["recipes"].each { |r| node.recipes << r }
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
