#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
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

require 'chef/mixin/from_file'
require 'chef/mixin/params_validate'
require 'chef/mixin/check_helper'
require 'chef/log'
require 'chef/cookbook/metadata/version'

class Chef
  class Cookbook
    class Metadata
    
      include Chef::Mixin::CheckHelper
      include Chef::Mixin::ParamsValidate
      include Chef::Mixin::FromFile

      attr_accessor :cookbook, 
                    :platforms,
                    :dependencies,
                    :recommendations,
                    :suggestions,
                    :conflicting,
                    :providing,
                    :replacing,
                    :attributes,
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
      def initialize(cookbook=nil, maintainer='Your Name', maintainer_email='youremail@example.com', license='Apache v2.0')
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
        @recipes = Mash.new
        @version = Version.new "0.0.0"
        if cookbook
          @recipes = cookbook.recipes.inject({}) do |r, e| 
            e = self.name if e =~ /::default$/ 
            r[e] = ""
            self.provides e
            r
          end
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
          @version = Version.new(arg)
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
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def supports(platform, *versions)
        versions.each { |v| _check_version_expression(v) }
        @platforms[platform] = versions
        @platforms[platform]
      end

      # Adds a dependency on another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook 
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def depends(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @dependencies[cookbook] = versions
        @dependencies[cookbook]
      end

      # Adds a recommendation for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook 
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def recommends(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @recommendations[cookbook] = versions
        @recommendations[cookbook]
      end

      # Adds a suggestion for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook 
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def suggests(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @suggestions[cookbook] = versions
        @suggestions[cookbook] 
      end

      # Adds a conflict for another cookbook, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook 
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def conflicts(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @conflicting[cookbook] = versions
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
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def provides(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @providing[cookbook] = versions
        @providing[cookbook] 
      end

      # Adds a cookbook that is replaced by this one, with version checking strings.
      #
      # === Parameters
      # cookbook<String>:: The cookbook we replace 
      # *versions<String>:: A list of versions matching << <= = >= >> followed by a version. 
      #
      # === Returns
      # versions<Array>:: Returns the list of versions for the platform 
      def replaces(cookbook, *versions)
        versions.each { |v| _check_version_expression(v) }
        @replacing[cookbook] = versions
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

      # Adds an attribute that a user needs to configure for this cookbook. Takes
      # a name (with the / notation for a nested attribute), followed by any of
      # these options
      #
      #   display_name<String>:: What a UI should show for this attribute
      #   description<String>:: A hint as to what this attr is for
      #   multiple_values<True>,<False>:: Whether it supports multiple values
      #   type<String>:: "string", "hash" or "array" - default is "string"
      #   required<True>,<False>:: Whether this attr is required - default false
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
            :multiple_values => { :equal_to => [ true, false ], :default => false },
            :type => { :equal_to => [ "string", "array", "hash" ], :default => "string" },
            :required => { :equal_to => [ true, false ], :default => false },
            :recipes => { :kind_of => [ Array ], :default => [] },
            :default => { :kind_of => [ String, Array, Hash ] }
          }
        )
        @attributes[name] = options 
        @attributes[name]
      end

      def _check_version_expression(version_string)
        if version_string =~ /^(>>|>=|=|<=|<<) (.+)$/
          [ $1, $2 ]
        else
          raise ArgumentError, "Version expression #{version_string} is invalid!"
        end
      end

      def to_json(*a)
        result = {
          :name => self.name,
          :description => self.description,
          :long_description => self.long_description,
          :maintainer => self.maintainer,
          :maintainer_email => self.maintainer_email,
          :license => self.license,
          :platforms => self.platforms,
          :dependencies => self.dependencies,
          :recommendations => self.recommendations,
          :suggestions => self.suggestions,
          :conflicting => self.conflicting,
          :providing => self.providing,
          :replacing => self.replacing,
          :attributes => self.attributes,
          :recipes => self.recipes,
          :version => self.version
        }
        result.to_json(*a)
      end

      def self.from_hash(o)
        cm = self.new() 
        cm.from_hash(o)
        cm
      end

      def from_hash(o)
        self.name o['name'] if o.has_key?('name')
        self.description o['description'] if o.has_key?('description')
        self.long_description o['long_description'] if o.has_key?('long_description')
        self.maintainer o['maintainer'] if o.has_key?('maintainer')
        self.maintainer_email o['maintainer_email'] if o.has_key?('maintainer_email')
        self.license o['license'] if o.has_key?('license')
        self.platforms = o['platforms'] if o.has_key?('platforms')
        self.dependencies = o['dependencies'] if o.has_key?('dependencies')
        self.recommendations = o['recommendations'] if o.has_key?('recommendations')
        self.suggestions = o['suggestions'] if o.has_key?('suggestions')
        self.conflicting = o['conflicting'] if o.has_key?('conflicting')
        self.providing = o['providing'] if o.has_key?('providing')
        self.replacing = o['replacing'] if o.has_key?('replacing')
        self.attributes = o['attributes'] if o.has_key?('attributes')
        self.recipes = o['recipes'] if o.has_key?('recipes')
        self.version = o['version'] if o.has_key?('version')
        self
      end

      def self.from_json(string)
        o = JSON.parse(string)
        self.from_hash(o)
      end

      def from_json(string)
        o = JSON.parse(string)
        from_hash(o)
      end

    end
  end
end
