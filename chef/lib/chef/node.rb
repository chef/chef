#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

require 'forwardable'
require 'chef/config'
require 'chef/cookbook/cookbook_collection'
require 'chef/nil_argument'
require 'chef/mixin/check_helper'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/mixin/language_include_attribute'
require 'chef/mixin/deep_merge'
require 'chef/environment'
require 'chef/couchdb'
require 'chef/rest'
require 'chef/run_list'
require 'chef/node/attribute'
require 'chef/index_queue'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'

class Chef
  class Node

    extend Forwardable

    def_delegators :attributes, :keys, :each_key, :each_value, :key?, :has_key?

    attr_accessor :recipe_list, :couchdb, :couchdb_rev, :run_state, :run_list
    attr_reader :couchdb_id

    # TODO: 5/18/2010 cw/timh. cookbook_collection should be removed
    # from here and for any place it's needed, it should be accessed
    # through a Chef::RunContext
    attr_accessor :cookbook_collection

    include Chef::Mixin::CheckHelper
    include Chef::Mixin::FromFile
    include Chef::Mixin::ParamsValidate
    include Chef::Mixin::LanguageIncludeAttribute
    include Chef::IndexQueue::Indexable

    DESIGN_DOCUMENT = {
      "version" => 11,
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
                var to_emit = { "name": doc.name, "chef_environment": doc.chef_environment };
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
        },
        "by_environment" => {
          "map" => <<-EOJS
            function(doc) {
              if (doc.chef_type == "node") {
                var env = (doc['chef_environment'] == null ? "_default" : doc['chef_environment']);
                emit(env, doc.name);
              }
            }
          EOJS
        }
      },
    }

    # Create a new Chef::Node object.
    def initialize(couchdb=nil)
      @name = nil

      @chef_environment = '_default'
      @run_list = Chef::RunList.new

      @attributes = Chef::Node::Attribute.new({}, {}, {}, {})

      @couchdb_rev = nil
      @couchdb_id = nil
      @couchdb = couchdb || Chef::CouchDB.new

      @run_state = {
        :template_cache => Hash.new,
        :seen_recipes => Hash.new,
        :seen_attributes => Hash.new
      }
      # TODO: 5/20/2010 need this here as long as other objects try to access
      # the cookbook collection via Node, otherwise get NoMethodError on nil.
      @cookbook_collection = CookbookCollection.new
    end

    def couchdb_id=(value)
      @couchdb_id = value
      @index_id = value
    end

    # Used by DSL
    def node
      self
    end

    def chef_server_rest
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
                     :cannot_be => :blank,
                     :regex => /^[\-[:alnum:]_:.]+$/}
                 })
        @name = arg
      else
        @name
      end
    end

    def chef_environment(arg=nil)
      set_or_return(
        :chef_environment,
        arg,
        { :regex => /^[\-[:alnum:]_]+$/, :kind_of => String }
      )
    end

    alias :environment :chef_environment



    def attributes
      @attributes
    end

    alias :attribute :attributes
    alias :construct_attributes :attributes

    # Return an attribute of this node.  Returns nil if the attribute is not found.
    def [](attrib)
      attributes.reset_for_read
      attributes[attrib]
    end

    # Set a normal attribute of this node, but auto-vivify any Mashes that
    # might be missing
    def normal
      attributes.normal
    end

    alias_method :set, :normal

    # Set a normal attribute of this node, auto-vivifying any mashes that are
    # missing, but if the final value already exists, don't set it
    def normal_unless
      attributes.set_unless_value_present = true
      attributes.normal
    end
    alias_method :set_unless, :normal_unless

    # Set a default of this node, but auto-vivify any Mashes that might
    # be missing
    def default
      attributes.default
    end

    # Set a default attribute of this node, auto-vivifying any mashes that are
    # missing, but if the final value already exists, don't set it
    def default_unless
      attributes.set_unless_value_present = true
      attributes.default
    end

    # Set an override attribute of this node, but auto-vivify any Mashes that
    # might be missing
    def override
      attributes.override
    end

    # Set an override attribute of this node, auto-vivifying any mashes that
    # are missing, but if the final value already exists, don't set it
    def override_unless
      attributes.set_unless_value_present = true
      attributes.override
    end


    def override_attrs
     attributes.override
    end

    def override_attrs=(new_values)
      attributes.override = new_values
    end

    def default_attrs
      attributes.default
    end

    def default_attrs=(new_values)
      attributes.default = new_values
    end

    def normal_attrs
      attributes.normal
    end

    def normal_attrs=(new_values)
      attributes.normal = new_values
    end

    def automatic_attrs
      attributes.automatic
    end

    def automatic_attrs=(new_values)
      attributes.automatic = new_values
    end

    # Return true if this Node has a given attribute, false if not.  Takes either a symbol or
    # a string.
    #
    # Only works on the top level. Preferred way is to use the normal [] style
    # lookup and call attribute?()
    def attribute?(attrib)
      attributes.attribute?(attrib)
    end

    # Yield each key of the top level to the block.
    def each(&block)
      attributes.each(&block)
    end

    # Iterates over each attribute, passing the attribute and value to the block.
    def each_attribute(&block)
      attributes.each_attribute(&block)
    end

    # Only works for attribute fetches, setting is no longer supported
    def method_missing(symbol, *args)
      attributes.reset_for_read
      attributes.send(symbol, *args)
    end

    # Returns true if this Node expects a given recipe, false if not.
    #
    # First, the run list is consulted to see whether the recipe is
    # explicitly included. If it's not there, it looks in
    # run_state[:seen_recipes], which is populated by include_recipe
    # statements in the DSL (and thus would not be in the run list).
    #
    # NOTE: It's used by cookbook authors
    def recipe?(recipe_name)
      run_list.include?(recipe_name) || run_state[:seen_recipes].include?(recipe_name)
    end

    # Returns true if this Node expects a given role, false if not.
    def role?(role_name)
      run_list.include?("role[#{role_name}]")
    end

    # Returns an Array of roles and recipes, in the order they will be applied.
    # If you call it with arguments, they will become the new list of roles and recipes.
    def run_list(*args)
      args.length > 0 ? @run_list.reset!(args) : @run_list
    end

    # Returns true if this Node expects a given role, false if not.
    def run_list?(item)
      run_list.detect { |r| r == item } ? true : false
    end

    # Consume data from ohai and Attributes provided as JSON on the command line.
    def consume_external_attrs(ohai_data, json_cli_attrs)
      Chef::Log.debug("Extracting run list from JSON attributes provided on command line")
      consume_attributes(json_cli_attrs)

      self.automatic_attrs = ohai_data

      platform, version = Chef::Platform.find_platform_and_version(self)
      Chef::Log.debug("Platform is #{platform} version #{version}")
      self.automatic[:platform] = platform
      self.automatic[:platform_version] = version
    end

    # Consumes the combined run_list and other attributes in +attrs+
    def consume_attributes(attrs)
      normal_attrs_to_merge = consume_run_list(attrs)
      Chef::Log.debug("Applying attributes from json file")
      self.normal_attrs = Chef::Mixin::DeepMerge.merge(normal_attrs,normal_attrs_to_merge)
      self.tags # make sure they're defined
    end

    # Lazy initializer for tags attribute
    def tags
      normal[:tags] = [] unless attribute?(:tags)
      normal[:tags]
    end

    # Extracts the run list from +attrs+ and applies it. Returns the remaining attributes
    def consume_run_list(attrs)
      attrs = attrs ? attrs.dup : {}
      if new_run_list = attrs.delete("recipes") || attrs.delete("run_list")
        if attrs.key?("recipes") || attrs.key?("run_list")
          raise Chef::Exceptions::AmbiguousRunlistSpecification, "please set the node's run list using the 'run_list' attribute only."
        end
        Chef::Log.info("Setting the run_list to #{new_run_list.inspect} from JSON")
        run_list(new_run_list)
      end
      attrs
    end

    # Clear defaults and overrides, so that any deleted attributes
    # between runs are still gone.
    def reset_defaults_and_overrides
      self.default.clear
      self.override.clear
    end

    # Expands the node's run list and sets the default and override
    # attributes. Also applies stored attributes (from json provided
    # on the command line)
    #
    # Returns the fully-expanded list of recipes, a RunListExpansion.
    #
    #--
    # TODO: timh/cw, 5-14-2010: Should this method exist? Should we
    # instead modify default_attrs and override_attrs whenever our
    # run_list is mutated? Or perhaps do something smarter like
    # on-demand generation of default_attrs and override_attrs,
    # invalidated only when run_list is mutated?
    def expand!(data_source = 'server')
      expansion = run_list.expand(chef_environment, data_source)
      raise Chef::Exceptions::MissingRole, expansion if expansion.errors?

      self.tags # make sure they're defined

      automatic[:recipes] = expansion.recipes
      automatic[:roles] = expansion.roles


      expansion
    end

    # Apply the default and overrides attributes from the expansion
    # passed in, which came from roles.
    def apply_expansion_attributes(expansion)
      load_chef_environment_object = (chef_environment == "_default" ? nil : Chef::Environment.load(chef_environment))
      environment_default_attrs = load_chef_environment_object.nil? ? {} : load_chef_environment_object.default_attributes
      default_before_roles = Chef::Mixin::DeepMerge.merge(default_attrs, environment_default_attrs)
      self.default_attrs = Chef::Mixin::DeepMerge.merge(default_before_roles, expansion.default_attrs)
      environment_override_attrs = load_chef_environment_object.nil? ? {} : load_chef_environment_object.override_attributes
      overrides_before_environments = Chef::Mixin::DeepMerge.merge(override_attrs, expansion.override_attrs)
      self.override_attrs = Chef::Mixin::DeepMerge.merge(overrides_before_environments, environment_override_attrs)
    end

    # Transform the node to a Hash
    def to_hash
      index_hash = Hash.new
      index_hash["chef_type"] = "node"
      index_hash["name"] = name
      index_hash["chef_environment"] = chef_environment
      attribute.each do |key, value|
        index_hash[key] = value
      end
      index_hash["recipe"] = run_list.recipe_names if run_list.recipe_names.length > 0
      index_hash["role"] = run_list.role_names if run_list.role_names.length > 0
      index_hash["run_list"] = run_list.run_list if run_list.run_list.length > 0
      index_hash
    end

    def display_hash
      display = {}
      display["name"]             = name
      display["chef_environment"] = chef_environment
      display["automatic"]        = automatic_attrs
      display["normal"]           = normal_attrs
      display["default"]          = default_attrs
      display["override"]         = override_attrs
      display["run_list"]         = run_list.run_list
      display
    end

    # Serialize this object as a hash
    def to_json(*a)
      result = {
        "name" => name,
        "chef_environment" => chef_environment,
        'json_class' => self.class.name,
        "automatic" => attributes.automatic,
        "normal" => attributes.normal,
        "chef_type" => "node",
        "default" => attributes.default,
        "override" => attributes.override,
        #Render correctly for run_list items so malformed json does not result
        "run_list" => run_list.run_list.map { |item| item.to_s }
      }
      result["_rev"] = couchdb_rev if couchdb_rev
      result.to_json(*a)
    end

    def update_from!(o)
      run_list.reset!(o.run_list)
      self.automatic_attrs = o.automatic_attrs
      self.normal_attrs = o.normal_attrs
      self.override_attrs = o.override_attrs
      self.default_attrs = o.default_attrs
      chef_environment(o.chef_environment)
      self
    end

    # Create a Chef::Node from JSON
    def self.json_create(o)
      node = new
      node.name(o["name"])
      node.chef_environment(o["chef_environment"])
      if o.has_key?("attributes")
        node.normal_attrs = o["attributes"]
      end
      node.automatic_attrs = Mash.new(o["automatic"]) if o.has_key?("automatic")
      node.normal_attrs = Mash.new(o["normal"]) if o.has_key?("normal")
      node.default_attrs = Mash.new(o["default"]) if o.has_key?("default")
      node.override_attrs = Mash.new(o["override"]) if o.has_key?("override")

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

    def self.cdb_list_by_environment(environment, inflate=false, couchdb=nil)
      rs = (couchdb || Chef::CouchDB.new).get_view("nodes", "by_environment", :include_docs => inflate, :startkey => environment, :endkey => environment)
      inflate ? rs["rows"].collect {|r| r["doc"]} : rs["rows"].collect {|r| r["value"]}
    end

    def self.list_by_environment(environment, inflate=false)
      if inflate
        response = Hash.new
        Chef::Search::Query.new.search(:node, "chef_environment:#{environment}") {|n| response[n.name] = n unless n.nil?}
        response
      else
        Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("environments/#{environment}/nodes")
      end
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

    def self.find_or_create(node_name)
      load(node_name)
    rescue Net::HTTPServerException => e
      raise unless e.response.code == '404'
      node = build(node_name)
      node.create
    end

    def self.build(node_name)
      node = new
      node.name(node_name)
      node.chef_environment(Chef::Config[:environment]) unless Chef::Config[:environment].nil? || Chef::Config[:environment].chop.empty?
      node
    end

    # Load a node by name
    def self.load(name)
      Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("nodes/#{name}")
    end

    # Remove this node from the CouchDB
    def cdb_destroy
      couchdb.delete("node", name, couchdb_rev)
    end

    # Remove this node via the REST API
    def destroy
      chef_server_rest.delete_rest("nodes/#{name}")
    end

    # Save this node to the CouchDB
    def cdb_save
      @couchdb_rev = couchdb.store("node", name, self)["rev"]
    end

    # Save this node via the REST API
    def save
      # Try PUT. If the node doesn't yet exist, PUT will return 404,
      # so then POST to create.
      begin
        if Chef::Config[:why_run]
          Chef::Log.warn("In whyrun mode, so NOT performing node save.")
        else
          chef_server_rest.put_rest("nodes/#{name}", self)
        end
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

    def to_s
      "node[#{name}]"
    end

    # Load all attribute files for all cookbooks associated with this
    # node.
    def load_attributes
      cookbook_collection.values.each do |cookbook|
        cookbook.segment_filenames(:attributes).each do |segment_filename|
          Chef::Log.debug("Node #{name} loading cookbook #{cookbook.name}'s attribute file #{segment_filename}")
          self.from_file(segment_filename)
        end
      end
    end

    # Used by DSL.
    # Loads the attribute file specified by the short name of the
    # file, e.g., loads specified cookbook's
    #   "attributes/mailservers.rb"
    # if passed
    #   "mailservers"
    def load_attribute_by_short_filename(name, src_cookbook_name)
      src_cookbook = cookbook_collection[src_cookbook_name]
      raise Chef::Exceptions::CookbookNotFound, "could not find cookbook #{src_cookbook_name} while loading attribute #{name}" unless src_cookbook

      attribute_filename = src_cookbook.attribute_filenames_by_short_filename[name]
      raise Chef::Exceptions::AttributeNotFound, "could not find filename for attribute #{name} in cookbook #{src_cookbook_name}" unless attribute_filename

      self.from_file(attribute_filename)
      self
    end
  end
end
