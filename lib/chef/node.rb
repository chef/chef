# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "forwardable" unless defined?(Forwardable)
require "securerandom" unless defined?(SecureRandom)
require_relative "constants"
require_relative "config"
require_relative "mixin/params_validate"
require_relative "mixin/from_file"
require_relative "mixin/deep_merge"
require_relative "dsl/include_attribute"
require_relative "dsl/universal"
require_relative "environment"
require_relative "server_api"
require_relative "run_list"
require_relative "node/attribute"
require_relative "mash"
require_relative "json_compat"
require_relative "search/query"
require_relative "attribute_allowlist"
require_relative "attribute_blocklist"

class Chef
  class Node

    extend Forwardable

    def_delegators :attributes, :keys, :each_key, :each_value, :key?, :has_key?
    def_delegators :attributes, :rm, :rm_default, :rm_normal, :rm_override
    def_delegators :attributes, :default!, :normal!, :override!, :force_default!, :force_override!
    def_delegators :attributes, :default_unless, :normal_unless, :override_unless, :set_unless
    def_delegators :attributes, :read, :read!, :write, :write!, :unlink, :unlink!

    attr_accessor :recipe_list, :run_state

    attr_reader :logger

    # RunContext will set itself as run_context via this setter when
    # initialized. This is needed so DSL::IncludeAttribute (in particular,
    # #include_recipe) can access the run_context to determine if an attributes
    # file has been seen yet.
    #--
    # TODO: This is a pretty ugly way to solve that problem.
    attr_accessor :run_context

    include Chef::Mixin::FromFile
    include Chef::DSL::IncludeAttribute
    include Chef::DSL::Universal

    include Chef::Mixin::ParamsValidate

    # Create a new Chef::Node object.
    def initialize(chef_server_rest: nil, logger: nil)
      @chef_server_rest = chef_server_rest
      @name = nil
      @logger = logger || Chef::Log.with_child(subsystem: "node")

      @chef_environment = "_default"
      @primary_runlist = Chef::RunList.new
      @override_runlist = Chef::RunList.new

      @policy_name = nil
      @policy_group = nil

      @attributes = Chef::Node::Attribute.new({}, {}, {}, {}, self)

      @run_state = {}
    end

    # after the run_context has been set on the node, go through the cookbook_collection
    # and setup the node[:cookbooks] attribute so that it is published in the node object
    def set_cookbook_attribute
      run_context.cookbook_collection.each do |cookbook_name, cookbook|
        automatic_attrs[:cookbooks][cookbook_name][:version] = cookbook.version
      end
    end

    # Used by DSL
    def node
      self
    end

    def chef_server_rest
      # for saving node data we use validate_utf8: false which will not
      # raise an exception on bad utf8 data, but will replace the bad
      # characters and render valid JSON.
      @chef_server_rest ||= Chef::ServerAPI.new(
        Chef::Config[:chef_server_url],
        client_name: Chef::Config[:node_name],
        signing_key_filename: Chef::Config[:client_key],
        validate_utf8: false
      )
    end

    # Set the name of this Node, or return the current name.
    def name(arg = nil)
      if !arg.nil?
        validate(
          { name: arg },
          { name: { kind_of: String,
                    cannot_be: :blank,
                    regex: /^[\-[:alnum:]_:.]+$/ },
          }
        )
        @name = arg
      else
        @name
      end
    end

    def chef_environment(arg = nil)
      set_or_return(
        :chef_environment,
        arg,
        { regex: /^[\-[:alnum:]_]+$/, kind_of: String }
      )
    end

    def chef_environment=(environment)
      chef_environment(environment)
    end

    alias :environment :chef_environment

    # The `policy_name` for this node. Setting this to a non-nil value will
    # enable policyfile mode when `chef-client` is run. If set in the config
    # file or in node json, running `chef-client` will update this value.
    #
    # @see Chef::PolicyBuilder::Dynamic
    # @see Chef::PolicyBuilder::Policyfile
    #
    # @param arg [String] the new policy_name value
    # @return [String] the current policy_name, or the one you just set
    def policy_name(arg = NOT_PASSED)
      return @policy_name if arg.equal?(NOT_PASSED)

      validate({ policy_name: arg }, { policy_name: { kind_of: [ String, NilClass ], regex: /^[\-:.[:alnum:]_]+$/ } })
      @policy_name = arg
    end

    # A "non-DSL-style" setter for `policy_name`
    #
    # @see #policy_name
    def policy_name=(policy_name)
      policy_name(policy_name)
    end

    # The `policy_group` for this node. Setting this to a non-nil value will
    # enable policyfile mode when `chef-client` is run. If set in the config
    # file or in node json, running `chef-client` will update this value.
    #
    # @see Chef::PolicyBuilder::Dynamic
    # @see Chef::PolicyBuilder::Policyfile
    #
    # @param arg [String] the new policy_group value
    # @return [String] the current policy_group, or the one you just set
    def policy_group(arg = NOT_PASSED)
      return @policy_group if arg.equal?(NOT_PASSED)

      validate({ policy_group: arg }, { policy_group: { kind_of: [ String, NilClass ], regex: /^[\-:.[:alnum:]_]+$/ } })
      @policy_group = arg
    end

    # A "non-DSL-style" setter for `policy_group`
    #
    # @see #policy_group
    def policy_group=(policy_group)
      policy_group(policy_group)
    end

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
      attributes.normal
    end

    # Set a default of this node, but auto-vivify any Mashes that might
    # be missing
    def default
      attributes.default
    end

    # Set an override attribute of this node, but auto-vivify any Mashes that
    # might be missing
    def override
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
    # XXX: this should be deprecated
    def method_missing(method, *args, &block)
      attributes.public_send(method, *args, &block)
    end

    # Fix respond_to + method so that it works with method_missing delegation
    def respond_to_missing?(method, include_private = false)
      attributes.respond_to?(method, false)
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
    #
    # @param role_name [String] Role to check for
    # @return [Boolean]
    def role?(role_name)
      Array(self[:roles]).include?(role_name)
    end

    def primary_runlist
      @primary_runlist
    end

    # This boolean can be useful to determine if an override_runlist is set, it can be true
    # even if the override_runlist is empty.
    #
    # (Mutators can set the override_runlist so any non-empty override_runlist is considered set)
    #
    # @return [Boolean] if the override run list has been set
    def override_runlist_set?
      !!@override_runlist_set || !override_runlist.empty?
    end

    # Accessor for override_runlist (this cannot set an empty override run list)
    #
    # @params args [Array] override run list to set
    # @return [Chef::RunList] the override run list
    def override_runlist(*args)
      return @override_runlist if args.length == 0

      @override_runlist_set = true
      @override_runlist.reset!(args)
    end

    # Setter for override_runlist which allows setting an empty override run list and marking it to be used
    #
    # @params array [Array] override run list to set
    # @return [Chef::RunList] the override run list
    def override_runlist=(array)
      @override_runlist_set = true
      @override_runlist.reset!(array)
    end

    def select_run_list
      override_runlist_set? ? @override_runlist : @primary_runlist
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

    # Handles both the consumption of ohai data and possibly JSON attributes from the CLI
    #
    # @api private
    def consume_external_attrs(ohai_data, json_cli_attrs)
      # FIXME(log): should be trace
      logger.debug("Extracting run list from JSON attributes provided on command line")
      consume_attributes(json_cli_attrs)

      self.automatic_attrs = ohai_data
      fix_automatic_attributes
    end

    # This is for ohai plugins to consume ohai data and have it merged, it should probably be renamed
    #
    # @api private
    def consume_ohai_data(ohai_data)
      self.automatic_attrs = Chef::Mixin::DeepMerge.merge(automatic_attrs, ohai_data)
      fix_automatic_attributes
    end

    # Always ensure that certain automatic attributes are populated and constructed correctly
    #
    # @api private
    def fix_automatic_attributes
      platform, version = Chef::Platform.find_platform_and_version(self)
      # FIXME(log): should be trace
      logger.debug("Platform is #{platform} version #{version}")
      automatic[:platform] = platform
      automatic[:platform_version] = Chef::VersionString.new(version)
      automatic[:chef_guid] = Chef::Config[:chef_guid] || ( Chef::Config[:chef_guid] = node_uuid )
      automatic[:name] = name
      automatic[:chef_environment] = chef_environment
    end

    # Consumes the combined run_list and other attributes in +attrs+
    def consume_attributes(attrs)
      normal_attrs_to_merge = consume_run_list(attrs)
      normal_attrs_to_merge = consume_chef_environment(normal_attrs_to_merge)
      # FIXME(log): should be trace
      logger.debug("Applying attributes from json file")
      self.normal_attrs = Chef::Mixin::DeepMerge.merge(normal_attrs, normal_attrs_to_merge)
      tags # make sure they're defined
    end

    # Lazy initializer for tags attribute
    def tags
      normal[:tags] = Array(normal[:tags])
      normal[:tags]
    end

    def tag(*args)
      args.each do |tag|
        tags.push(tag.to_s) unless tags.include? tag.to_s
      end

      tags
    end

    # Extracts the run list from +attrs+ and applies it. Returns the remaining attributes
    def consume_run_list(attrs)
      attrs = attrs ? attrs.dup : {}
      if new_run_list = attrs.delete("recipes") || attrs.delete("run_list")
        if attrs.key?("recipes") || attrs.key?("run_list")
          raise Chef::Exceptions::AmbiguousRunlistSpecification, "please set the node's run list using the 'run_list' attribute only."
        end

        logger.info("Setting the run_list to #{new_run_list} from CLI options")
        run_list(new_run_list)
      end
      attrs
    end

    # chef_environment when set in -j JSON will take precedence over
    # -E ENVIRONMENT. Ideally, IMO, the order of precedence should be (lowest to
    #  highest):
    #   config_file
    #   -j JSON
    #   -E ENVIRONMENT
    # so that users could reuse their JSON and override the chef_environment
    # configured within it with -E ENVIRONMENT. Because command line options are
    # merged with Chef::Config there is currently no way to distinguish between
    # an environment set via config from an environment set via command line.
    def consume_chef_environment(attrs)
      attrs = attrs ? attrs.dup : {}
      if env = attrs.delete("chef_environment")
        chef_environment(env)
      end
      attrs
    end

    # Clear defaults and overrides, so that any deleted attributes
    # between runs are still gone.
    def reset_defaults_and_overrides
      default.clear
      override.clear
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
    def expand!(data_source = "server")
      expansion = run_list.expand(chef_environment, data_source)
      raise Chef::Exceptions::MissingRole, expansion if expansion.errors?

      tags # make sure they're defined

      automatic_attrs[:recipes] = expansion.recipes.with_duplicate_names
      automatic_attrs[:expanded_run_list] = expansion.recipes.with_fully_qualified_names_and_version_constraints
      automatic_attrs[:roles] = expansion.roles

      apply_expansion_attributes(expansion)

      automatic_attrs[:chef_environment] = chef_environment
      expansion
    end

    # Apply the default and overrides attributes from the expansion
    # passed in, which came from roles.
    def apply_expansion_attributes(expansion)
      loaded_environment = if chef_environment == "_default"
                             Chef::Environment.new.tap { |e| e.name("_default") }
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
      index_hash = attributes.to_hash
      index_hash["chef_type"] = "node"
      index_hash["name"] = name
      index_hash["chef_environment"] = chef_environment
      index_hash["recipe"] = run_list.recipe_names if run_list.recipe_names.length > 0
      index_hash["role"] = run_list.role_names if run_list.role_names.length > 0
      index_hash["run_list"] = run_list.run_list_items
      index_hash
    end

    def display_hash
      display = {}
      display["name"]             = name
      display["chef_environment"] = chef_environment
      display["automatic"]        = attributes.automatic.to_hash
      display["normal"]           = attributes.normal.to_hash
      display["default"]          = attributes.combined_default.to_hash
      display["override"]         = attributes.combined_override.to_hash
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
        "json_class" => self.class.name,
        "automatic" => attributes.automatic.to_hash,
        "normal" => attributes.normal.to_hash,
        "chef_type" => "node",
        "default" => attributes.combined_default.to_hash,
        "override" => attributes.combined_override.to_hash,
        # Render correctly for run_list items so malformed json does not result
        "run_list" => @primary_runlist.run_list.map(&:to_s),
      }
      # Chef Server rejects node JSON with extra keys; prior to 12.3,
      # "policy_name" and "policy_group" are unknown; after 12.3 they are
      # optional, therefore only including them in the JSON if present
      # maximizes compatibility for most people.
      unless policy_group.nil? && policy_name.nil?
        result["policy_name"] = policy_name
        result["policy_group"] = policy_group
      end
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

    def self.from_hash(o)
      return o if o.is_a? Chef::Node

      node = new
      node.name(o["name"])

      node.policy_name = o["policy_name"] if o.key?("policy_name")
      node.policy_group = o["policy_group"] if o.key?("policy_group")

      unless node.policy_group.nil?
        node.chef_environment(o["policy_group"])
      else
        node.chef_environment(o["chef_environment"])
      end

      if o.key?("attributes")
        node.normal_attrs = o["attributes"]
      end
      node.automatic_attrs = Mash.new(o["automatic"]) if o.key?("automatic")
      node.normal_attrs = Mash.new(o["normal"]) if o.key?("normal")
      node.default_attrs = Mash.new(o["default"]) if o.key?("default")
      node.override_attrs = Mash.new(o["override"]) if o.key?("override")

      if o.key?("run_list")
        node.run_list.reset!(o["run_list"])
      elsif o.key?("recipes")
        o["recipes"].each { |r| node.recipes << r }
      end

      node
    end

    def self.list_by_environment(environment, inflate = false)
      if inflate
        response = {}
        Chef::Search::Query.new.search(:node, "chef_environment:#{environment}") { |n| response[n.name] = n unless n.nil? }
        response
      else
        Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("environments/#{environment}/nodes")
      end
    end

    def self.list(inflate = false)
      if inflate
        response = {}
        Chef::Search::Query.new.search(:node) do |n|
          n = Chef::Node.from_hash(n)
          response[n.name] = n unless n.nil?
        end
        response
      else
        Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("nodes")
      end
    end

    def self.find_or_create(node_name)
      load(node_name)
    rescue Net::HTTPClientException => e
      raise unless e.response.code == "404"

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
      from_hash(Chef::ServerAPI.new(Chef::Config[:chef_server_url]).get("nodes/#{name}"))
    end

    # Remove this node via the REST API
    def destroy
      chef_server_rest.delete("nodes/#{name}")
    end

    # Save this node via the REST API
    def save
      # Try PUT. If the node doesn't yet exist, PUT will return 404,
      # so then POST to create.
      begin
        if Chef::Config[:why_run]
          logger.warn("In why-run mode, so NOT performing node save.")
        else
          chef_server_rest.put("nodes/#{name}", data_for_save)
        end
      rescue Net::HTTPClientException => e
        if e.response.code == "404"
          chef_server_rest.post("nodes", data_for_save)
        else
          raise
        end
      end
      self
    end

    # Create the node via the REST API
    def create
      chef_server_rest.post("nodes", data_for_save)
      self
    rescue Net::HTTPClientException => e
      # Chef Server before 12.3 rejects node JSON with 'policy_name' or
      # 'policy_group' keys, but 'policy_name' will be detected first.
      # Backcompat can be removed in 13.0
      if e.response.code == "400" && e.response.body.include?("Invalid key policy_name")
        chef_server_rest.post("nodes", data_for_save_without_policyfile_attrs)
      else
        raise
      end
    end

    def to_s
      "node[#{name}]"
    end

    def ==(other)
      if other.is_a?(self.class)
        name == other.name
      else
        false
      end
    end

    def <=>(other)
      name <=> other.name
    end

    # Returns hash of node data with attributes based on whitelist/blacklist rules.
    def data_for_save
      data = for_json
      %w{automatic default normal override}.each do |level|
        allowlist = allowlist_or_whitelist_config(level)
        unless allowlist.nil? # nil => save everything
          logger.info("Allowing #{level} node attributes for save.")
          data[level] = Chef::AttributeAllowlist.filter(data[level], allowlist)
        end

        blocklist = blocklist_or_blacklist_config(level)
        unless blocklist.nil? # nil => remove nothing
          logger.info("Blocking #{level} node attributes for save")
          data[level] = Chef::AttributeBlocklist.filter(data[level], blocklist)
        end
      end
      data
    end

    private

    def save_without_policyfile_attrs
      trimmed_data = data_for_save_without_policyfile_attrs

      chef_server_rest.put("nodes/#{name}", trimmed_data)
    rescue Net::HTTPClientException => e
      raise e unless e.response.code == "404"

      chef_server_rest.post("nodes", trimmed_data)
    end

    def data_for_save_without_policyfile_attrs
      data_for_save.tap do |trimmed_data|
        trimmed_data.delete("policy_name")
        trimmed_data.delete("policy_group")
      end
    end

    # a method to handle the renamed configuration from whitelist -> allowed
    # and to throw a deprecation warning when the old configuration is set
    #
    # @param [String] level the attribute level
    def allowlist_or_whitelist_config(level)
      if Chef::Config["#{level}_attribute_whitelist".to_sym]
        Chef.deprecated(:attribute_whitelist_configuration, "Attribute whitelist configurations have been deprecated. Use the allowed_LEVEL_attribute configs instead")
        Chef::Config["#{level}_attribute_whitelist".to_sym]
      else
        Chef::Config["allowed_#{level}_attributes".to_sym]
      end
    end

    # a method to handle the renamed configuration from blacklist -> blocked
    # and to throw a deprecation warning when the old configuration is set
    #
    # @param [String] level the attribute level
    def blocklist_or_blacklist_config(level)
      if Chef::Config["#{level}_attribute_blacklist".to_sym]
        Chef.deprecated(:attribute_blacklist_configuration, "Attribute blacklist configurations have been deprecated. Use the blocked_LEVEL_attribute configs instead")
        Chef::Config["#{level}_attribute_blacklist".to_sym]
      else
        Chef::Config["blocked_#{level}_attributes".to_sym]
      end
    end

    # Returns a UUID that uniquely identifies this node for reporting reasons.
    #
    # The node is read in from disk if it exists, or it's generated if it does
    # does not exist.
    #
    # @return [String] UUID for the node
    #
    def node_uuid
      path = File.expand_path(Chef::Config[:chef_guid_path])
      dir = File.dirname(path)

      unless File.exist?(path)
        FileUtils.mkdir_p(dir)
        File.write(path, SecureRandom.uuid)
      end

      File.open(path).first.chomp
    end

  end
end
