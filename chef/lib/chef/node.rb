#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
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
require 'chef/mixin/language_include_attribute'
require 'chef/couchdb'
require 'chef/rest'
require 'chef/run_list'
require 'chef/node/attribute'
require 'chef/index_queue'
require 'extlib'
require 'json'

class Chef
  class Node
    
    attr_accessor :attribute, :recipe_list, :couchdb, :couchdb_rev, :run_state, :run_list, :override_attrs, :default_attrs, :cookbook_loader
    attr_reader :node
    attr_reader :couchdb_id
    
    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::LanguageIncludeAttribute
    include Chef::IndexQueue::Indexable
    
    DESIGN_DOCUMENT = {
      "version" => 9,
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
    def initialize(couchdb=nil)
      @name = nil
      @node = self

      @attribute = Mash.new
      @override_attrs = Mash.new
      @default_attrs = Mash.new
      @run_list = Chef::RunList.new

      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new

      @run_state = {
        :template_cache => Hash.new,
        :seen_recipes => Hash.new,
        :seen_attributes => Hash.new
      }
    end

    def couchdb_id=(value)
      @couchdb_id = value
      self.index_id = value
    end

    def chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])      
    end

    def self.chef_server_rest
      Chef::REST.new(Chef::Config[:chef_server_url])      
    end

    # Find a recipe for this Chef::Node by fqdn.  Will search first for 
    # Chef::Config["node_path"]/fqdn.rb, then hostname.rb, then default.rb.
    # 
    # Returns a new Chef::Node object.
    #
    # Raises an ArgumentError if it cannot find the node. 
    def find_file(fqdn)
      host_parts = fqdn.split(".")
      hostname = host_parts[0]
      
      [fqdn, hostname, "default"].each { |fname|
       node_file = File.join(Chef::Config[:node_path], "#{fname.to_s}.rb")        
       return self.from_file(node_file) if File.exists?(node_file)
     }
      
      raise ArgumentError, "Cannot find a node matching #{fqdn}, not even with default.rb!" 
    end
    
    # Set the name of this Node, or return the current name.
    def name(arg=nil)
      if arg != nil
        validate(
          {:name => arg }, 
          {:name => { :kind_of => String,
                      :cannot_be => :blank}
          })
        @name = arg
      else
        @name
      end
    end
    
    # Return an attribute of this node.  Returns nil if the attribute is not found.
    def [](attrib)
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs)[attrib]
    end
    
    # Set an attribute of this node
    def []=(attrib, value)
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs)[attrib] = value
    end
    
    def store(attrib, value)
      self[attrib] = value
    end

    # Set an attribute of this node, but auto-vivifiy any Mashes that might
    # be missing
    def set
      attrs = Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs)
      attrs.auto_vivifiy_on_read = true
      attrs
    end

    # Set an attribute of this node, auto-vivifiying any mashes that are
    # missing, but if the final value already exists, don't set it
    def set_unless
      attrs = Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs)
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
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs).attribute?(attrib)
    end
  
    # Yield each key of the top level to the block. 
    def each(&block)
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs).each(&block)
    end
    
    # Iterates over each attribute, passing the attribute and value to the block.
    def each_attribute(&block)
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs).each_attribute(&block)
    end

    # Set an attribute based on the missing method.  If you pass an argument, we'll use that
    # to set the attribute values.  Otherwise, we'll wind up just returning the attributes
    # value.
    def method_missing(symbol, *args)
      Chef::Node::Attribute.new(@attribute, @default_attrs, @override_attrs).send(symbol, *args)
    end
    
    # Returns true if this Node expects a given recipe, false if not.
    def recipe?(recipe_name)
      @run_list.include?(recipe_name) || @run_state[:seen_recipes].include?(recipe_name)
    end
    
    # Returns true if this Node expects a given role, false if not.
    def role?(role_name)
      @run_list.include?("role[#{role_name}]")
    end

    # Returns an Array of roles and recipes, in the order they will be applied.
    # If you call it with arguments, they will become the new list of roles and recipes. 
    def run_list(*args)
      args.length > 0 ? @run_list.reset!(args) : @run_list
    end
    
    def recipes(*args)
      Chef::Log.warn "Chef::Node#recipes method is deprecated.  Please use Chef::Node#run_list"
      run_list(*args)
    end

    # Returns true if this Node expects a given role, false if not.
    def run_list?(item)
      @run_list.detect { |r| r == item } ? true : false
    end
    
    def consume_attributes(attrs)
      attrs ||= {}
      Chef::Log.debug("Adding JSON Attributes")
      attrs.each do |key, value|
        if ["recipes", "run_list"].include?(key)
          run_list(value)
        else
          Chef::Log.debug("JSON Attribute: #{key} - #{value.inspect}")
          store(key, value)
        end
      end
      self[:tags] = Array.new unless attribute?(:tags)
      
    end
    
    # Transform the node to a Hash
    def to_hash
      index_hash = Hash.new
      self.each do |k, v|
        index_hash[k] = v
      end
      index_hash["chef_type"] = "node"
      index_hash["name"] = @name
      index_hash["recipe"] = @run_list.recipes if @run_list.recipes.length > 0
      index_hash["role"] = @run_list.roles if @run_list.roles.length > 0
      index_hash["run_list"] = @run_list.run_list if @run_list.run_list.length > 0
      index_hash
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      result = {
        "name" => @name,
        'json_class' => self.class.name,
        "attributes" => @attribute,
        "chef_type" => "node",
        "defaults" => @default_attrs,
        "overrides" => @override_attrs,
        "run_list" => @run_list.run_list,
      }
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result.to_json(*a)
    end
    
    # Create a Chef::Node from JSON
    def self.json_create(o)
      node = new
      node.name(o["name"])
      o["attributes"].each { |k,v| node[k] = v }
      
      node.default_attrs = Mash.new(o["defaults"]) if o.has_key?("defaults")
      node.override_attrs = Mash.new(o["overrides"]) if o.has_key?("overrides")

      if o.has_key?("run_list")
        node.run_list.reset!(o["run_list"])
      else
        o["recipes"].each { |r| node.recipes << r }
      end
      node.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      node.couchdb_id = o["_id"] if o.has_key?("_id")
      node.index_id = node.couchdb_id
      node
    end
    
    # List all the Chef::Node objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all Nodes, fully inflated.
    def self.cdb_list(inflate=false, couchdb=nil)
      rs =(couchdb || Chef::CouchDB.new).list("nodes", inflate)
      lookup = (inflate ? "value" : "key")
      rs["rows"].collect { |r| r[lookup] }
    end

    def self.list(inflate=false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:node) do |n|
          response[n.name] = n unless n.nil?
        end
        response
      else
        Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("nodes")
      end
    end
    
    # Load a node by name from CouchDB
    def self.cdb_load(name, couchdb=nil)
      (couchdb || Chef::CouchDB.new).load("node", name)      
    end

    def self.exists?(nodename, couchdb)
      begin
        self.cdb_load(nodename, couchdb)
      rescue Chef::Exceptions::CouchDBNotFound
        nil
      end
    end
    
    # Load a node by name
    def self.load(name)
      Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("nodes/#{name}")
    end
    
    # Remove this node from the CouchDB
    def cdb_destroy
      @couchdb.delete("node", @name, @couchdb_rev)
    end

    # Remove this node via the REST API
    def destroy
      chef_server_rest.delete_rest("nodes/#{@name}")
    end
    
    # Save this node to the CouchDB
    def cdb_save
      @couchdb_rev = @couchdb.store("node", @name, self)["rev"]
    end

    # Save this node via the REST API
    def save
      begin
        chef_server_rest.put_rest("nodes/#{@name}", self)
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("nodes", self)
      end
      self
    end
    
    # Create the node via the REST API
    def create
      chef_server_rest.post_rest("nodes", self)
      self
    end 

    # Set up our CouchDB design document
    def self.create_design_document(couchdb=nil)
      (couchdb || Chef::CouchDB.new).create_design_document("nodes", DESIGN_DOCUMENT)
    end
    
    # As a string
    def to_s
      "node[#{@name}]"
    end

  end
end
