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
require 'chef/nil_argument'
require 'chef/mixin/params_validate'
require 'chef/mixin/from_file'
require 'chef/mixin/deep_merge'
require 'chef/dsl/include_attribute'
require 'chef/dsl/platform_introspection'
require 'chef/environment'
require 'chef/rest'
require 'chef/run_list'
require 'chef/node/attribute'
require 'chef/mash'
require 'chef/json_compat'
require 'chef/search/query'
require 'chef/whitelist'

class Chef
  class Node

    extend Forwardable

    def_delegators :attributes, :keys, :each_key, :each_value, :key?, :has_key?
    def_delegators :attributes, :rm, :rm_default, :rm_normal, :rm_override
    def_delegators :attributes, :default!, :normal!, :override!, :force_default!, :force_override!

    attr_accessor :recipe_list, :run_state, :override_runlist

    attr_accessor :chef_server_rest

    # RunContext will set itself as run_context via this setter when
    # initialized. This is needed so DSL::IncludeAttribute (in particular,
    # #include_recipe) can access the run_context to determine if an attributes
    # file has been seen yet.
    #--
    # TODO: This is a pretty ugly way to solve that problem.
    attr_accessor :run_context

    include Chef::Mixin::FromFile
    include Chef::DSL::IncludeAttribute
    include Chef::DSL::PlatformIntrospection

    include Chef::Mixin::ParamsValidate

    # Create a new Chef::Node object.
    def initialize(chef_server_rest: nil)
      @chef_server_rest = chef_server_rest
      @name = nil

      @chef_environment = '_default'
      @primary_runlist = Chef::RunList.new
      @override_runlist = Chef::RunList.new

      @attributes = Chef::Node::Attribute.new({}, {}, {}, {})

      @run_state = {}
    end

    # Used by DSL
    def node
      self
    end

    def chef_server_rest
      @chef_server_rest ||= Chef::REST.new(Chef::Config[:chef_server_url])
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

    def chef_environment=(environment)
      chef_environment(environment)
    end

    alias :environment :chef_environment

    def attributes
      @attributes
    end

    alias :attribute :attributes
    alias :construct_attributes :attributes

    # Return an attribute of this node.  Returns nil if the attribute is not found.
    def [](attrib)
      attributes[attrib]
    end

    # Set a normal attribute of this node, but auto-vivify any Mashes that
    # might be missing
    def normal
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = false
      attributes.normal
    end

    alias_method :set, :normal

    # Set a normal attribute of this node, auto-vivifying any mashes that are
    # missing, but if the final value already exists, don't set it
    def normal_unless
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = true
      attributes.normal
    end

    alias_method :set_unless, :normal_unless

    # Set a default of this node, but auto-vivify any Mashes that might
    # be missing
    def default
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = false
      attributes.default
    end

    # Set a default attribute of this node, auto-vivifying any mashes that are
    # missing, but if the final value already exists, don't set it
    def default_unless
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = true
      attributes.default
    end

    # Set an override attribute of this node, but auto-vivify any Mashes that
    # might be missing
    def override
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = false
      attributes.override
    end

    # Set an override attribute of this node, auto-vivifying any mashes that
    # are missing, but if the final value already exists, don't set it
    def override_unless
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = true
      attributes.override
    end

    alias :override_attrs :override
    alias :default_attrs :default
    alias :normal_attrs :normal

    def override_attrs=(new_values)
      attributes.override = new_values
    end

    def default_attrs=(new_values)
      attributes.default = new_values
    end

    def normal_attrs=(new_values)
      attributes.normal = new_values
    end

    def automatic_attrs
      attributes.top_level_breadcrumb = nil
      attributes.set_unless_value_present = false
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
      attributes.send(symbol, *args)
    end

    # Returns true if this Node expects a given recipe, false if not.
    #
    # First, the run list is consulted to see whether the recipe is
    # explicitly included. If it's not there, it looks in
    # `node[:recipes]`, which is populated when the run_list is expanded
    #
    # NOTE: It's used by cookbook authors
    def recipe?(recipe_name)
      run_list.include?(recipe_name) || Array(self[:recipes]).include?(recipe_name)
    end

    # used by include_recipe to add recipes to the expanded run_list to be
    # saved back to the node and be searchable
    def loaded_recipe(cookbook, recipe)
      fully_qualified_recipe = "#{cookbook}::#{recipe}"
      automatic_attrs[:recipes] << fully_qualified_recipe unless Array(self[:recipes]).include?(fully_qualified_recipe)
    end

    # Returns true if this Node expects a given role, false if not.
    def role?(role_name)
      run_list.include?("role[#{role_name}]")
    end

    def primary_runlist
      @primary_runlist
    end

    def override_runlist(*args)
      args.length > 0 ? @override_runlist.reset!(args) : @override_runlist
    end

    def select_run_list
      @override_runlist.empty? ? @primary_runlist : @override_runlist
    end

    # Returns an Array of roles and recipes, in the order they will be applied.
    # If you call it with arguments, they will become the new list of roles and recipes.
    def run_list(*args)
      rl = select_run_list
      args.length > 0 ? rl.reset!(args) : rl
    end

    def run_list=(list)
      rl = select_run_list
      rl = list
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

    def tag(*tags)
      tags.each do |tag|
        self.normal[:tags].push(tag.to_s) unless self[:tags].include? tag.to_s
      end

      self[:tags]
    end

    # Extracts the run list from +attrs+ and applies it. Returns the remaining attributes
    def consume_run_list(attrs)
      attrs = attrs ? attrs.dup : {}
      if new_run_list = attrs.delete("recipes") || attrs.delete("run_list")
        if attrs.key?("recipes") || attrs.key?("run_list")
          raise Chef::Exceptions::AmbiguousRunlistSpecification, "please set the node's run list using the 'run_list' attribute only."
        end
        Chef::Log.info("Setting the run_list to #{new_run_list.inspect} from CLI options")
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

      automatic_attrs[:recipes] = expansion.recipes
      automatic_attrs[:roles] = expansion.roles

      apply_expansion_attributes(expansion)

      expansion
    end

    # Apply the default and overrides attributes from the expansion
    # passed in, which came from roles.
    def apply_expansion_attributes(expansion)
      loaded_environment = if chef_environment == "_default"
                             Chef::Environment.new.tap {|e| e.name("_default")}
                           else
                             Chef::Environment.load(chef_environment)
                           end

      attributes.env_default = loaded_environment.default_attributes
      attributes.env_override = loaded_environment.override_attributes

      attribute.role_default = expansion.default_attrs
      attributes.role_override = expansion.override_attrs
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
      index_hash["run_list"] = run_list.run_list_items
      index_hash
    end

    def display_hash
      display = {}
      display["name"]             = name
      display["chef_environment"] = chef_environment
      display["automatic"]        = automatic_attrs
      display["normal"]           = normal_attrs
      display["default"]          = attributes.combined_default
      display["override"]         = attributes.combined_override
      display["run_list"]         = run_list.run_list_items
      display
    end

    # Serialize this object as a hash
    def to_json(*a)
      Chef::JSONCompat.to_json(for_json, *a)
    end

    def for_json
      result = {
        "name" => name,
        "chef_environment" => chef_environment,
        'json_class' => self.class.name,
        "automatic" => attributes.automatic,
        "normal" => attributes.normal,
        "chef_type" => "node",
        "default" => attributes.combined_default,
        "override" => attributes.combined_override,
        #Render correctly for run_list items so malformed json does not result
        "run_list" => @primary_runlist.run_list.map { |item| item.to_s }
      }
      result
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
      node
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
      node.chef_environment(Chef::Config[:environment]) unless Chef::Config[:environment].nil? || Chef::Config[:environment].chomp.empty?
      node
    end

    # Load a node by name
    def self.load(name)
      Chef::REST.new(Chef::Config[:chef_server_url]).get_rest("nodes/#{name}")
    end

    # Remove this node via the REST API
    def destroy
      chef_server_rest.delete_rest("nodes/#{name}")
    end

    # Save this node via the REST API
    def save
      # Try PUT. If the node doesn't yet exist, PUT will return 404,
      # so then POST to create.
      begin
        if Chef::Config[:why_run]
          Chef::Log.warn("In whyrun mode, so NOT performing node save.")
        else
          chef_server_rest.put_rest("nodes/#{name}", data_for_save)
        end
      rescue Net::HTTPServerException => e
        raise e unless e.response.code == "404"
        chef_server_rest.post_rest("nodes", data_for_save)
      end
      self
    end

    # Create the node via the REST API
    def create
      chef_server_rest.post_rest("nodes", data_for_save)
      self
    end

    def to_s
      "node[#{name}]"
    end

    def <=>(other_node)
      self.name <=> other_node.name
    end

    private

    def data_for_save
      data = for_json
      ["automatic", "default", "normal", "override"].each do |level|
        whitelist_config_option = "#{level}_attribute_whitelist".to_sym
        whitelist = Chef::Config[whitelist_config_option]
        unless whitelist.nil? # nil => save everything
          Chef::Log.info("Whitelisting #{level} node attributes for save.")
          data[level] = Chef::Whitelist.filter(data[level], whitelist)
        end
      end
      data
    end

  end
end
