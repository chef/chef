#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2008-2010 Opscode, Inc.
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

require 'chef/mash'
require 'chef/mixin/from_file'
require 'chef/mixin/params_validate'
require 'chef/log'
require 'chef/version_class'
require 'chef/version_constraint'

class Chef
  class Cookbook

    # == Chef::Cookbook::Metadata
    # Chef::Cookbook::Metadata provides a convenient DSL for declaring metadata
    # about Chef Cookbooks.
    class Metadata

      NAME              = 'name'.freeze
      DESCRIPTION       = 'description'.freeze
      LONG_DESCRIPTION  = 'long_description'.freeze
      MAINTAINER        = 'maintainer'.freeze
      MAINTAINER_EMAIL  = 'maintainer_email'.freeze
      LICENSE           = 'license'.freeze
      PLATFORMS         = 'platforms'.freeze
      DEPENDENCIES      = 'dependencies'.freeze
      RECOMMENDATIONS   = 'recommendations'.freeze
      SUGGESTIONS       = 'suggestions'.freeze
      CONFLICTING       = 'conflicting'.freeze
      PROVIDING         = 'providing'.freeze
      REPLACING         = 'replacing'.freeze
      ATTRIBUTES        = 'attributes'.freeze
      GROUPINGS         = 'groupings'.freeze
      RECIPES           = 'recipes'.freeze
      VERSION           = 'version'.freeze

      COMPARISON_FIELDS = [ :name, :description, :long_description, :maintainer,
                            :maintainer_email, :license, :platforms, :dependencies,
                            :recommendations, :suggestions, :conflicting, :providing,
                            :replacing, :attributes, :groupings, :recipes, :version]

      VERSION_CONSTRAINTS = {:depends     => DEPENDENCIES,
                             :recommends  => RECOMMENDATIONS,
                             :suggests    => SUGGESTIONS,
                             :conflicts   => CONFLICTING,
                             :provides    => PROVIDING,
                             :replaces    => REPLACING }

      include Chef::Mixin::ParamsValidate
      include Chef::Mixin::FromFile

      attr_reader   :cookbook,
                    :platforms,
                    :dependencies,
                    :recommendations,
                    :suggestions,
                    :conflicting,
                    :providing,
                    :replacing,
                    :attributes,
                    :groupings,
                    :recipes,
                    :version

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
      def initialize(cookbook=nil, maintainer='YOUR_COMPANY_NAME', maintainer_email='YOUR_EMAIL', license='none')
        @cookbook = cookbook
        @name = cookbook ? cookbook.name : ""
        @long_description = ""
        self.maintainer(maintainer)
        self.maintainer_email(maintainer_email)
        self.license(license)
        self.description('A fabulous new cookbook')
        @platforms = Mash.new
        @dependencies = Mash.new
        @recommendations = Mash.new
        @suggestions = Mash.new
        @conflicting = Mash.new
        @providing = Mash.new
        @replacing = Mash.new
        @attributes = Mash.new
        @groupings = Mash.new
        @recipes = Mash.new
        @version = Version.new "0.0.0"
        if cookbook
          @recipes = cookbook.fully_qualified_recipe_names.inject({}) do |r, e|
            e = self.name if e =~ /::default$/
            r[e] = ""
            self.provides e
            r
          end
        end
      end

      def ==(other)
        COMPARISON_FIELDS.inject(true) do |equal_so_far, field|
          equal_so_far && other.respond_to?(field) && (other.send(field) == send(field))
        end
      end

      # Sets the cookbooks maintainer, or returns it.
      #
      # === Parameters
      # maintainer<String>:: The maintainers name
      #
      # === Returns
      # maintainer<String>:: Returns the current maintainer.
      def maintainer(arg=nil)
        set_or_return(
          :maintainer,
          arg,
          :kind_of => [ String ]
        )
      end

      # Sets the maintainers email address, or returns it.
      #
      # === Parameters
      # maintainer_email<String>:: The maintainers email address
      #
      # === Returns
      # maintainer_email<String>:: Returns the current maintainer email.
      def maintainer_email(arg=nil)
        set_or_return(
          :maintainer_email,
          arg,
          :kind_of => [ String ]
        )
      end

      # Sets the current license, or returns it.
      #
      # === Parameters
      # license<String>:: The current license.
      #
      # === Returns
      # license<String>:: Returns the current license
      def license(arg=nil)
        set_or_return(
          :license,
          arg,
          :kind_of => [ String ]
        )
      end

      # Sets the current description, or returns it. Should be short - one line only!
      #
      # === Parameters
      # description<String>:: The new description
      #
      # === Returns
      # description<String>:: Returns the description
      def description(arg=nil)
        set_or_return(
          :description,
          arg,
          :kind_of => [ String ]
        )
      end

      # Sets the current long description, or returns it. Might come from a README, say.
      #
      # === Parameters
      # long_description<String>:: The new long description
      #
      # === Returns
      # long_description<String>:: Returns the long description
      def long_description(arg=nil)
        set_or_return(
          :long_description,
          arg,
          :kind_of => [ String ]
        )
      end

      # Sets the current cookbook version, or returns it.  Can be two or three digits, seperated
      # by dots.  ie: '2.1', '1.5.4' or '0.9'.
      #
      # === Parameters
      # version<String>:: The curent version, as a string
      #
      # === Returns
      # version<String>:: Returns the current version
      def version(arg=nil)
        if arg
          @version = Chef::Version.new(arg)
        end

        @version.to_s
      end

      # Sets the name of the cookbook, or returns it.
      #
      # === Parameters
      # name<String>:: The curent cookbook name.
      #
      # === Returns
      # name<String>:: Returns the current cookbook name.
      def name(arg=nil)
        set_or_return(
          :name,
          arg,
          :kind_of => [ String ]
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
        validate_version_constraint(:supports, platform, version)
        @platforms[platform] = version
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
        version = new_args_format(:depends, cookbook, version_args)
        validate_version_constraint(:depends, cookbook, version)
        @dependencies[cookbook] = version
        @dependencies[cookbook]
      end

      # Adds a recommendation for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has
      # the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def recommends(cookbook, *version_args)
        version = new_args_format(:recommends, cookbook,  version_args)
        validate_version_constraint(:recommends, cookbook, version)
        @recommendations[cookbook] = version
        @recommendations[cookbook]
      end

      # Adds a suggestion for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has the
      # formx.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def suggests(cookbook, *version_args)
        version = new_args_format(:suggests, cookbook, version_args)
        validate_version_constraint(:suggests, cookbook, version)
        @suggestions[cookbook] = version
        @suggestions[cookbook]
      end

      # Adds a conflict for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has
      # the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def conflicts(cookbook, *version_args)
        version = new_args_format(:conflicts, cookbook, version_args)
        validate_version_constraint(:conflicts, cookbook, version)
        @conflicting[cookbook] = version
        @conflicting[cookbook]
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
        validate_version_constraint(:provides, cookbook, version)
        @providing[cookbook] = version
        @providing[cookbook]
      end

      # Adds a cookbook that is replaced by this one, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook we replace
      # version<String>:: A version constraint of the form "OP VERSION",
      # where OP is one of < <= = > >= ~> and VERSION has the form x.y.z or x.y.
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform
      def replaces(cookbook, *version_args)
        version = new_args_format(:replaces, cookbook, version_args)
        validate_version_constraint(:replaces, cookbook, version)
        @replacing[cookbook] = version
        @replacing[cookbook]
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

      # Adds an attribute )hat a user needs to configure for this cookbook. Takes
      # a name (with the / notation for a nested attribute), followed by any of
      # these options
      #
      #   display_name<String>:: What a UI should show for this attribute
      #   description<String>:: A hint as to what this attr is for
      #   choice<Array>:: An array of choices to present to the user.
      #   calculated<Boolean>:: If true, the default value is calculated by the recipe and cannot be displayed.
      #   type<String>:: "string" or "array" - default is "string"  ("hash" is supported for backwards compatibility)
      #   required<String>:: Whether this attr is 'required', 'recommended' or 'optional' - default 'optional' (true/false values also supported for backwards compatibility)
      #   recipes<Array>:: An array of recipes which need this attr set.
      #   default<String>,<Array>,<Hash>:: The default value
      #
      # === Parameters
      # name<String>:: The name of the attribute ('foo', or 'apache2/log_dir')
      # options<Hash>:: The description of the options
      #
      # === Returns
      # options<Hash>:: Returns the current options hash
      def attribute(name, options)
        validate(
          options,
          {
            :display_name => { :kind_of => String },
            :description => { :kind_of => String },
            :choice => { :kind_of => [ Array ], :default => [] },
            :calculated => { :equal_to => [ true, false ], :default => false },
            :type => { :equal_to => [ "string", "array", "hash", "symbol" ], :default => "string" },
            :required => { :equal_to => [ "required", "recommended", "optional", true, false ], :default => "optional" },
            :recipes => { :kind_of => [ Array ], :default => [] },
            :default => { :kind_of => [ String, Array, Hash ] }
          }
        )
        options[:required] = remap_required_attribute(options[:required]) unless options[:required].nil?
        validate_string_array(options[:choice])
        validate_calculated_default_rule(options)
        validate_choice_default_rule(options)

        @attributes[name] = options
        @attributes[name]
      end

      def grouping(name, options)
        validate(
          options,
          {
            :title => { :kind_of => String },
            :description => { :kind_of => String }
          }
        )
        @groupings[name] = options
        @groupings[name]
      end

      def to_hash
        {
          NAME             => self.name,
          DESCRIPTION      => self.description,
          LONG_DESCRIPTION => self.long_description,
          MAINTAINER       => self.maintainer,
          MAINTAINER_EMAIL => self.maintainer_email,
          LICENSE          => self.license,
          PLATFORMS        => self.platforms,
          DEPENDENCIES     => self.dependencies,
          RECOMMENDATIONS  => self.recommendations,
          SUGGESTIONS      => self.suggestions,
          CONFLICTING      => self.conflicting,
          PROVIDING        => self.providing,
          REPLACING        => self.replacing,
          ATTRIBUTES       => self.attributes,
          GROUPINGS        => self.groupings,
          RECIPES          => self.recipes,
          VERSION          => self.version
        }
      end

      def to_json(*a)
        self.to_hash.to_json(*a)
      end

      def self.from_hash(o)
        cm = self.new()
        cm.from_hash(o)
        cm
      end

      def from_hash(o)
        @name                         = o[NAME] if o.has_key?(NAME)
        @description                  = o[DESCRIPTION] if o.has_key?(DESCRIPTION)
        @long_description             = o[LONG_DESCRIPTION] if o.has_key?(LONG_DESCRIPTION)
        @maintainer                   = o[MAINTAINER] if o.has_key?(MAINTAINER)
        @maintainer_email             = o[MAINTAINER_EMAIL] if o.has_key?(MAINTAINER_EMAIL)
        @license                      = o[LICENSE] if o.has_key?(LICENSE)
        @platforms                    = o[PLATFORMS] if o.has_key?(PLATFORMS)
        @dependencies                 = handle_deprecated_constraints(o[DEPENDENCIES]) if o.has_key?(DEPENDENCIES)
        @recommendations              = handle_deprecated_constraints(o[RECOMMENDATIONS]) if o.has_key?(RECOMMENDATIONS)
        @suggestions                  = handle_deprecated_constraints(o[SUGGESTIONS]) if o.has_key?(SUGGESTIONS)
        @conflicting                  = handle_deprecated_constraints(o[CONFLICTING]) if o.has_key?(CONFLICTING)
        @providing                    = o[PROVIDING] if o.has_key?(PROVIDING)
        @replacing                    = handle_deprecated_constraints(o[REPLACING]) if o.has_key?(REPLACING)
        @attributes                   = o[ATTRIBUTES] if o.has_key?(ATTRIBUTES)
        @groupings                    = o[GROUPINGS] if o.has_key?(GROUPINGS)
        @recipes                      = o[RECIPES] if o.has_key?(RECIPES)
        @version                      = o[VERSION] if o.has_key?(VERSION)
        self
      end

      def self.from_json(string)
        o = Chef::JSONCompat.from_json(string)
        self.from_hash(o)
      end

      def self.validate_json(json_str)
        o = Chef::JSONCompat.from_json(json_str)
        metadata = new()
        VERSION_CONSTRAINTS.each do |method_name, hash_key|
          if constraints = o[hash_key]
           constraints.each do |cb_name, constraints|
             metadata.send(method_name, cb_name, *Array(constraints))
           end
          end
        end
        true
      end

      def from_json(string)
        o = Chef::JSONCompat.from_json(string)
        from_hash(o)
      end

    private

      def new_args_format(caller_name, dep_name, version_constraints)
        if version_constraints.empty?
          ">= 0.0.0"
        elsif version_constraints.size == 1
          version_constraints.first
        else
          msg=<<-OBSOLETED
The dependency specification syntax you are using is no longer valid. You may not
specify more than one version constraint for a particular cookbook.
Consult http://wiki.opscode.com/display/chef/Metadata for the updated syntax.

Called by: #{caller_name} '#{dep_name}', #{version_constraints.map {|vc| vc.inspect}.join(", ")}
Called from:
#{caller[0...5].map {|line| "  " + line}.join("\n")}
OBSOLETED
          raise Exceptions::ObsoleteDependencySyntax, msg
        end
      end

      def validate_version_constraint(caller_name, dep_name, constraint_str)
        Chef::VersionConstraint.new(constraint_str)
      rescue Chef::Exceptions::InvalidVersionConstraint => e
        Log.debug(e)

        msg=<<-INVALID
The version constraint syntax you are using is not valid. If you recently
upgraded to Chef 0.10.0, be aware that you no may longer use "<<" and ">>" for
'less than' and 'greater than'; use '<' and '>' instead.
Consult http://wiki.opscode.com/display/chef/Metadata for more information.

Called by: #{caller_name} '#{dep_name}', '#{constraint_str}'
Called from:
#{caller[0...5].map {|line| "  " + line}.join("\n")}
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
        if arry.kind_of?(Array)
          arry.each do |choice|
            validate( {:choice => choice}, {:choice => {:kind_of => String}} )
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
          raise ArgumentError, "Default must be one of your choice values!" if options[:choice].index(options[:default]) == nil
        end

        if options[:default].is_a?(Array) && !options[:default].empty?
          options[:default].each do |val|
            raise ArgumentError, "Default values must be a subset of your choice values!" if options[:choice].index(val) == nil
          end
        end
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
      def handle_deprecated_constraints(specification)
        specification.inject(Mash.new) do |acc, (cb, constraints)|
          constraints = Array(constraints)
          acc[cb] = (constraints.empty? || constraints.size > 1) ? [] : constraints.first.gsub(/>>/, '>').gsub(/<</, '<')
          acc
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
