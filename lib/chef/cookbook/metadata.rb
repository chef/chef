# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../exceptions"
require_relative "../mash"
require_relative "../mixin/from_file"
require_relative "../mixin/params_validate"
require_relative "../log"
require_relative "../version_class"
require_relative "../version_constraint"
require_relative "../version_constraint/platform"
require_relative "../json_compat"

class Chef
  class Cookbook

    # == Chef::Cookbook::Metadata
    # Chef::Cookbook::Metadata provides a convenient DSL for declaring metadata
    # about Chef Cookbooks.
    class Metadata

      NAME                   = "name".freeze
      DESCRIPTION            = "description".freeze
      LONG_DESCRIPTION       = "long_description".freeze
      MAINTAINER             = "maintainer".freeze
      MAINTAINER_EMAIL       = "maintainer_email".freeze
      LICENSE                = "license".freeze
      PLATFORMS              = "platforms".freeze
      DEPENDENCIES           = "dependencies".freeze
      PROVIDING              = "providing".freeze
      RECIPES                = "recipes".freeze
      VERSION                = "version".freeze
      SOURCE_URL             = "source_url".freeze
      ISSUES_URL             = "issues_url".freeze
      PRIVACY                = "privacy".freeze
      CHEF_VERSIONS          = "chef_versions".freeze
      OHAI_VERSIONS          = "ohai_versions".freeze
      GEMS                   = "gems".freeze
      EAGER_LOAD_LIBRARIES   = "eager_load_libraries".freeze

      COMPARISON_FIELDS = %i{name description long_description maintainer
                            maintainer_email license platforms dependencies
                            providing recipes version source_url issues_url
                            privacy chef_versions ohai_versions gems
                            eager_load_libraries}.freeze

      VERSION_CONSTRAINTS = { depends: DEPENDENCIES,
                              provides: PROVIDING,
                              chef_version: CHEF_VERSIONS,
                              ohai_version: OHAI_VERSIONS }.freeze

      include Chef::Mixin::ParamsValidate
      include Chef::Mixin::FromFile

      attr_reader :platforms
      attr_reader :dependencies
      attr_reader :providing
      attr_reader :recipes

      # @return [Array<Gem::Dependency>] Array of supported Chef versions
      attr_reader :chef_versions
      # @return [Array<Gem::Dependency>] Array of supported Ohai versions
      attr_reader :ohai_versions
      # @return [Array<Array>] Array of gems to install with *args as an Array
      attr_reader :gems

      # Builds a new Chef::Cookbook::Metadata object.
      #
      # === Parameters
      # cookbook<String>:: An optional cookbook object
      # maintainer<String>:: An optional maintainer
      # maintainer_email<String>:: An optional maintainer email
      # license<String>::An optional license. Default is Apache v2.0
      #
      # === Returns
      # metadata<Chef::Cookbook::Metadata>
      def initialize
        @name = nil

        @description = ""
        @long_description = ""
        @license = "All rights reserved"

        @maintainer = ""
        @maintainer_email = ""

        @platforms = Mash.new
        @dependencies = Mash.new
        @providing = Mash.new
        @recipes = Mash.new
        @version = Version.new("0.0.0")
        @source_url = ""
        @issues_url = ""
        @privacy = false
        @chef_versions = []
        @ohai_versions = []
        @gems = []
        @eager_load_libraries = true

        @errors = []
      end

      def ==(other)
        COMPARISON_FIELDS.inject(true) do |equal_so_far, field|
          equal_so_far && other.respond_to?(field) && (other.send(field) == send(field))
        end
      end

      # Whether this metadata is valid. In order to be valid, all required
      # fields must be set. Chef's validation implementation checks the content
      # of a given field when setting (and raises an error if the content does
      # not meet the criteria), so the content of the fields is not considered
      # when checking validity.
      #
      # === Returns
      # valid<Boolean>:: Whether this metadata object is valid
      def valid?
        run_validation
        @errors.empty?
      end

      # A list of validation errors for this metadata object. See #valid? for
      # comments about the validation criteria.
      #
      # If there are any validation errors, one or more error strings will be
      # returned. Otherwise an empty array is returned.
      #
      # === Returns
      # error messages<Array>:: Whether this metadata object is valid
      def errors
        run_validation
        @errors
      end

      # Sets the cookbooks maintainer, or returns it.
      #
      # === Parameters
      # maintainer<String>:: The maintainers name
      #
      # === Returns
      # maintainer<String>:: Returns the current maintainer.
      def maintainer(arg = nil)
        set_or_return(
          :maintainer,
          arg,
          kind_of: [ String ]
        )
      end

      # Sets the maintainers email address, or returns it.
      #
      # === Parameters
      # maintainer_email<String>:: The maintainers email address
      #
      # === Returns
      # maintainer_email<String>:: Returns the current maintainer email.
      def maintainer_email(arg = nil)
        set_or_return(
          :maintainer_email,
          arg,
          kind_of: [ String ]
        )
      end

      # Sets the current license, or returns it.
      #
      # === Parameters
      # license<String>:: The current license.
      #
      # === Returns
      # license<String>:: Returns the current license
      def license(arg = nil)
        set_or_return(
          :license,
          arg,
          kind_of: [ String ]
        )
      end

      # Sets the current description, or returns it. Should be short - one line only!
      #
      # === Parameters
      # description<String>:: The new description
      #
      # === Returns
      # description<String>:: Returns the description
      def description(arg = nil)
        set_or_return(
          :description,
          arg,
          kind_of: [ String ]
        )
      end

      # Sets the current long description, or returns it. Might come from a README, say.
      #
      # === Parameters
      # long_description<String>:: The new long description
      #
      # === Returns
      # long_description<String>:: Returns the long description
      def long_description(arg = nil)
        set_or_return(
          :long_description,
          arg,
          kind_of: [ String ]
        )
      end

      # Sets the current cookbook version, or returns it.  Can be two or three digits, separated
      # by dots.  ie: '2.1', '1.5.4' or '0.9'.
      #
      # === Parameters
      # version<String>:: The current version, as a string
      #
      # === Returns
      # version<String>:: Returns the current version
      def version(arg = nil)
        if arg
          @version = Chef::Version.new(arg)
        end

        @version.to_s
      end

      # Sets the name of the cookbook, or returns it.
      #
      # === Parameters
      # name<String>:: The current cookbook name.
      #
      # === Returns
      # name<String>:: Returns the current cookbook name.
      def name(arg = nil)
        set_or_return(
          :name,
          arg,
          kind_of: [ String ]
        )
      end

      # Adds a supported platform, with version checking strings.
      #
      # === Parameters
      # platform<String>,<Symbol>:: The platform (like :ubuntu or :mac_os_x)
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has
      # the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def supports(platform, *version_args)
        version = new_args_format(:supports, platform, version_args)
        constraint = validate_version_constraint(:supports, platform, version)
        @platforms[platform] = constraint.to_s
        @platforms[platform]
      end

      # Adds a dependency on another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has
      # the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def depends(cookbook, *version_args)
        if cookbook == name
          raise "Cookbook depends on itself in cookbook #{name}, please remove the this unnecessary self-dependency"
        else
          version = new_args_format(:depends, cookbook, version_args)
          constraint = validate_version_constraint(:depends, cookbook, version)
          @dependencies[cookbook] = constraint.to_s
        end

        @dependencies[cookbook]
      end

      # Adds a recipe, definition, or resource provided by this cookbook.
      #
      # Recipes are specified as normal
      # Definitions are followed by (), and can include :params for prototyping
      # Resources are the stringified version (service[apache2])
      #
      # === Parameters
      # recipe, definition, resource<String>:: The thing we provide
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has
      # the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def provides(cookbook, *version_args)
        version = new_args_format(:provides, cookbook, version_args)
        constraint = validate_version_constraint(:provides, cookbook, version)
        @providing[cookbook] = constraint.to_s
        @providing[cookbook]
      end

      # Metadata DSL to set a valid chef_version.  May be declared multiple times
      # with the result being 'OR'd such that if any statements match, the version
      # is considered supported.  Uses Gem::Requirement for its implementation.
      #
      # @param version_args [Array<String>] Version constraint in String form
      # @return [Array<Gem::Dependency>] Current chef_versions array
      def chef_version(*version_args)
        @chef_versions << Gem::Dependency.new("chef", *version_args) unless version_args.empty?
        @chef_versions
      end

      # Metadata DSL to set a valid ohai_version.  May be declared multiple times
      # with the result being 'OR'd such that if any statements match, the version
      # is considered supported.  Uses Gem::Requirement for its implementation.
      #
      # @param version_args [Array<String>] Version constraint in String form
      # @return [Array<Gem::Dependency>] Current ohai_versions array
      def ohai_version(*version_args)
        @ohai_versions << Gem::Dependency.new("ohai", *version_args) unless version_args.empty?
        @ohai_versions
      end

      # Metadata DSL to set a gem to install from the cookbook metadata.  May be declared
      # multiple times.  All the gems from all the cookbooks are combined into one Gemfile
      # and depsolved together.  Uses Bundler's DSL for its implementation.
      #
      # @param args [Array<String>] Gem name and options to pass to Bundler's DSL
      # @return [Array<Array>] Array of gem statements as args
      def gem(*args)
        @gems << args unless args.empty?
        @gems
      end

      # Metadata DSL to control the behavior of library loading.
      #
      # Can be set to:
      #
      # true   - libraries are eagerly loaded in alphabetical order (backcompat)
      # false  - libraries are not eagerly loaded, the libraries dir is added to the LOAD_PATH
      # String - a file or glob pattern to eagerly load, otherwise it is treated like `false`
      # Array<String> - array of files or globs to eagerly load, otherwise it is treated like `false`
      #
      # @params arg [Array,String,TrueClass,FalseClass]
      # @params [Array,TrueClass,FalseClass]
      def eager_load_libraries(arg = nil)
        set_or_return(
          :eager_load_libraries,
          arg,
          kind_of: [ Array, String, TrueClass, FalseClass ]
        )
      end

      # Adds a description for a recipe.
      #
      # === Parameters
      # recipe<String>:: The recipe
      # description<String>:: The description of the recipe
      #
      # === Returns
      # description<String>:: Returns the current description
      def recipe(name, description)
        @recipes[name] = description
      end

      # Sets the cookbook's recipes to the list of recipes in the given
      # +cookbook+. Any recipe that already has a description (if set by the
      # #recipe method) will not be updated.
      #
      # === Parameters
      # cookbook<CookbookVersion>:: CookbookVersion object representing the cookbook
      # description<String>:: The description of the recipe
      #
      # === Returns
      # recipe_unqualified_names<Array>:: An array of the recipe names given by the cookbook
      def recipes_from_cookbook_version(cookbook)
        cookbook.fully_qualified_recipe_names.map do |recipe_name|
          unqualified_name =
            if recipe_name.end_with?("::default")
              name.to_s
            else
              recipe_name
            end

          @recipes[unqualified_name] ||= ""
          provides(unqualified_name)

          unqualified_name
        end
      end

      # Convert an Array of Gem::Dependency objects (chef_version/ohai_version) to an Array.
      #
      # Gem::Dependency#to_s is not useful, and there is no #to_json defined on it or its component
      # objects, so we have to write our own rendering method.
      #
      # [ Gem::Dependency.new(">= 12.5"), Gem::Dependency.new(">= 11.18.0", "< 12.0") ]
      #
      # results in:
      #
      # [ [ ">= 12.5" ], [ ">= 11.18.0", "< 12.0" ] ]
      #
      # @param deps [Array<Gem::Dependency>] Multiple Gem-style version constraints
      # @return [Array<Array<String>]] Simple object representation of version constraints (for json)
      def gem_requirements_to_array(*deps)
        deps.map do |dep|
          dep.requirement.requirements.map do |op, version|
            "#{op} #{version}"
          end.sort
        end
      end

      # Convert an Array of Gem::Dependency objects (chef_version/ohai_version) to a hash.
      #
      # This is the inverse of #gem_requirements_to_array
      #
      # @param what [String] What version constraint we are constructing ('chef' or 'ohai' presently)
      # @param array [Array<Array<String>]] Simple object representation of version constraints (from json)
      # @return [Array<Gem::Dependency>] Multiple Gem-style version constraints
      def gem_requirements_from_array(what, array)
        array.map do |dep|
          Gem::Dependency.new(what, *dep)
        end
      end

      def to_h
        {
          NAME => name,
          DESCRIPTION => description,
          LONG_DESCRIPTION => long_description,
          MAINTAINER => maintainer,
          MAINTAINER_EMAIL => maintainer_email,
          LICENSE => license,
          PLATFORMS => platforms,
          DEPENDENCIES => dependencies,
          PROVIDING => providing,
          RECIPES => recipes,
          VERSION => version,
          SOURCE_URL => source_url,
          ISSUES_URL => issues_url,
          PRIVACY => privacy,
          CHEF_VERSIONS => gem_requirements_to_array(*chef_versions),
          OHAI_VERSIONS => gem_requirements_to_array(*ohai_versions),
          GEMS => gems,
          EAGER_LOAD_LIBRARIES => eager_load_libraries,
        }
      end

      alias_method :to_hash, :to_h

      def to_json(*a)
        Chef::JSONCompat.to_json(to_h, *a)
      end

      def self.from_hash(o)
        cm = new
        cm.from_hash(o)
        cm
      end

      def from_hash(o)
        @name                         = o[NAME] if o.key?(NAME)
        @description                  = o[DESCRIPTION] if o.key?(DESCRIPTION)
        @long_description             = o[LONG_DESCRIPTION] if o.key?(LONG_DESCRIPTION)
        @maintainer                   = o[MAINTAINER] if o.key?(MAINTAINER)
        @maintainer_email             = o[MAINTAINER_EMAIL] if o.key?(MAINTAINER_EMAIL)
        @license                      = o[LICENSE] if o.key?(LICENSE)
        @platforms                    = o[PLATFORMS] if o.key?(PLATFORMS)
        @dependencies                 = handle_incorrect_constraints(o[DEPENDENCIES]) if o.key?(DEPENDENCIES)
        @providing                    = o[PROVIDING] if o.key?(PROVIDING)
        @recipes                      = o[RECIPES] if o.key?(RECIPES)
        @version                      = o[VERSION] if o.key?(VERSION)
        @source_url                   = o[SOURCE_URL] if o.key?(SOURCE_URL)
        @issues_url                   = o[ISSUES_URL] if o.key?(ISSUES_URL)
        @privacy                      = o[PRIVACY] if o.key?(PRIVACY)
        @chef_versions                = gem_requirements_from_array("chef", o[CHEF_VERSIONS]) if o.key?(CHEF_VERSIONS)
        @ohai_versions                = gem_requirements_from_array("ohai", o[OHAI_VERSIONS]) if o.key?(OHAI_VERSIONS)
        @gems                         = o[GEMS] if o.key?(GEMS)
        @eager_load_libraries         = o[EAGER_LOAD_LIBRARIES] if o.key?(EAGER_LOAD_LIBRARIES)
        self
      end

      def self.from_json(string)
        o = Chef::JSONCompat.from_json(string)
        from_hash(o)
      end

      def self.validate_json(json_str)
        o = Chef::JSONCompat.from_json(json_str)
        metadata = new
        VERSION_CONSTRAINTS.each do |dependency_type, hash_key|
          if dependency_group = o[hash_key]
            dependency_group.each do |cb_name, constraints|
              if metadata.respond_to?(dependency_type)
                metadata.public_send(dependency_type, cb_name, *Array(constraints))
              end
            end
          end
        end
        true
      end

      def from_json(string)
        o = Chef::JSONCompat.from_json(string)
        from_hash(o)
      end

      # Sets the cookbook's source URL, or returns it.
      #
      # === Parameters
      # maintainer<String>:: The source URL
      #
      # === Returns
      # source_url<String>:: Returns the current source URL.
      def source_url(arg = nil)
        set_or_return(
          :source_url,
          arg,
          kind_of: [ String ]
        )
      end

      # This method translates version constraint strings from
      # cookbooks with the old format.
      #
      # Before we began respecting version constraints, we allowed
      # multiple constraints to be placed on cookbooks, as well as the
      # << and >> operators, which are now just < and >. For
      # specifications with more than one constraint, we return an
      # empty array (otherwise, we're silently abiding only part of
      # the contract they have specified to us). If there is only one
      # constraint, we are replacing the old << and >> with the new <
      # and >.
      def handle_incorrect_constraints(specification)
        specification.inject(Mash.new) do |acc, (cb, constraints)|
          constraints = Array(constraints)
          acc[cb] = (constraints.empty? || constraints.size > 1) ? [] : constraints.first
          acc
        end
      end

      # Sets the cookbook's issues URL, or returns it.
      #
      # === Parameters
      # issues_url<String>:: The issues URL
      #
      # === Returns
      # issues_url<String>:: Returns the current issues URL.
      def issues_url(arg = nil)
        set_or_return(
          :issues_url,
          arg,
          kind_of: [ String ]
        )
      end

      #
      # Sets the cookbook's privacy flag, or returns it.
      #
      # === Parameters
      # privacy<TrueClass,FalseClass>:: Whether this cookbook is private or not
      #
      # === Returns
      # privacy<TrueClass,FalseClass>:: Whether this cookbook is private or not
      #
      def privacy(arg = nil)
        set_or_return(
          :privacy,
          arg,
          kind_of: [ TrueClass, FalseClass ]
        )
      end

      # Validates that the Ohai::VERSION of the running chef-client matches one of the
      # configured ohai_version statements in this cookbooks metadata.
      #
      # @raise [Chef::Exceptions::CookbookOhaiVersionMismatch] if the cookbook fails validation
      def validate_ohai_version!
        unless gem_dep_matches?("ohai", Gem::Version.new(Ohai::VERSION), *ohai_versions)
          raise Exceptions::CookbookOhaiVersionMismatch.new(Ohai::VERSION, name, version, *ohai_versions)
        end
      end

      # Validates that the Chef::VERSION of the running chef-client matches one of the
      # configured chef_version statements in this cookbooks metadata.
      #
      # @raise [Chef::Exceptions::CookbookChefVersionMismatch] if the cookbook fails validation
      def validate_chef_version!
        unless gem_dep_matches?("chef", Gem::Version.new(Chef::VERSION), *chef_versions)
          raise Exceptions::CookbookChefVersionMismatch.new(Chef::VERSION, name, version, *chef_versions)
        end
      end

      def method_missing(method, *args, &block)
        if block_given?
          super
        else
          Chef::Log.trace "ignoring method #{method} on cookbook with name #{name}, possible typo or the ghosts of metadata past or future?"
        end
      end

      private

      # Helper to match a gem style version (ohai_version/chef_version) against a set of
      # Gem::Dependency version constraints.  If none are present, it always matches.  if
      # multiple are present, one must match.  Returns false if none matches.
      #
      # @param what [String] the name of the constraint (e.g. 'chef' or 'ohai')
      # @param version [String] the version to compare against the constraints
      # @param deps [Array<Gem::Dependency>] Multiple Gem-style version constraints
      # @return [Boolean] true if no constraints or a match, false if no match
      def gem_dep_matches?(what, version, *deps)
        # always match if we have no chef_version at all
        return true unless deps.length > 0

        # match if we match any of the chef_version lines
        deps.any? { |dep| dep.match?(what, version) }
      end

      def run_validation
        if name.nil?
          @errors = ["The `name' attribute is required in cookbook metadata"]
        end
      end

      def new_args_format(caller_name, dep_name, version_constraints)
        if version_constraints.empty?
          ">= 0.0.0"
        elsif version_constraints.size == 1
          version_constraints.first
        else
          msg = <<~OBSOLETED
            The dependency specification syntax you are using is no longer valid. You may not
            specify more than one version constraint for a particular cookbook.
            Consult https://docs.chef.io/config_rb_metadata/ for the updated syntax.

            Called by: #{caller_name} '#{dep_name}', #{version_constraints.map(&:inspect).join(", ")}
            Called from:
            #{caller[0...5].map { |line| "  " + line }.join("\n")}
          OBSOLETED
          raise Exceptions::ObsoleteDependencySyntax, msg
        end
      end

      def validate_version_constraint(caller_name, dep_name, constraint_str)
        Chef::VersionConstraint::Platform.new(constraint_str)
      rescue Chef::Exceptions::InvalidVersionConstraint => e
        Log.debug(e)

        msg = <<~INVALID
          The version constraint syntax you are using is not valid. If you recently
          upgraded from Chef Infra releases before 0.10, be aware that you no may
          longer use "<<" and ">>" for 'less than' and 'greater than'; use '<' and
          '>' instead. Consult https://docs.chef.io/config_rb_metadata/ for more
          information.

          Called by: #{caller_name} '#{dep_name}', '#{constraint_str}'
          Called from:
          #{caller[0...5].map { |line| "  " + line }.join("\n")}
        INVALID
        raise Exceptions::InvalidVersionConstraint, msg
      end

      # Verify that the given array is an array of strings
      #
      # Raise an exception if the members of the array are not Strings
      #
      # === Parameters
      # arry<Array>:: An array to be validated
      def validate_string_array(arry)
        if arry.is_a?(Array)
          arry.each do |choice|
            validate( { choice: choice }, { choice: { kind_of: String } } )
          end
        end
      end

      # Validate the choice of the options hash
      #
      # Raise an exception if the members of the array do not match the defaults
      # === Parameters
      # opts<Hash>:: The options hash
      def validate_choice_array(opts)
        if opts[:choice].is_a?(Array)
          case opts[:type]
          when "string"
            validator = [ String ]
          when "array"
            validator = [ Array ]
          when "hash"
            validator = [ Hash ]
          when "symbol"
            validator = [ Symbol ]
          when "boolean"
            validator = [ TrueClass, FalseClass ]
          when "numeric"
            validator = [ Numeric ]
          end

          opts[:choice].each do |choice|
            validate( { choice: choice }, { choice: { kind_of: validator } } )
          end
        end
      end

      # For backwards compatibility, remap Boolean values to String
      #   true is mapped to "required"
      #   false is mapped to "optional"
      #
      # === Parameters
      # required_attr<String><Boolean>:: The value of options[:required]
      #
      # === Returns
      # required_attr<String>:: "required", "recommended", or "optional"
      def remap_required_attribute(value)
        case value
        when true
          value = "required"
        when false
          value = "optional"
        end
        value
      end

      def validate_calculated_default_rule(options)
        calculated_conflict = ((options[:default].is_a?(Array) && !options[:default].empty?) ||
                               (options[:default].is_a?(String) && !options[:default] != "")) &&
          options[:calculated] == true
        raise ArgumentError, "Default cannot be specified if calculated is true!" if calculated_conflict
      end

      def validate_choice_default_rule(options)
        return if !options[:choice].is_a?(Array) || options[:choice].empty?

        if options[:default].is_a?(String) && options[:default] != ""
          raise ArgumentError, "Default must be one of your choice values!" if options[:choice].index(options[:default]).nil?
        end

        if options[:default].is_a?(Array) && !options[:default].empty?
          options[:default].each do |val|
            raise ArgumentError, "Default values must be a subset of your choice values!" if options[:choice].index(val).nil?
          end
        end
      end
    end

    #== Chef::Cookbook::MinimalMetadata
    # MinimalMetadata is a duck type of Cookbook::Metadata, used
    # internally by Chef Server when determining the optimal set of
    # cookbooks for a node.
    #
    # MinimalMetadata objects typically contain only enough information
    # to solve the cookbook collection for a run list, but not enough to
    # generate the proper response
    class MinimalMetadata < Metadata
      def initialize(name, params)
        @name = name
        from_hash(params)
      end
    end

  end
end
