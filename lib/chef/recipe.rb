#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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

autoload :YAML, "yaml"
require_relative "json_compat"
require_relative "dsl/recipe"
require_relative "mixin/from_file"
require_relative "mixin/deprecation"

class Chef
  # == Chef::Recipe
  # A Recipe object is the context in which Chef recipes are evaluated.
  class Recipe
    attr_accessor :cookbook_name, :recipe_name, :recipe, :params, :run_context

    include Chef::DSL::Recipe

    include Chef::Mixin::FromFile
    include Chef::Mixin::Deprecation

    # Parses a potentially fully-qualified recipe name into its
    # cookbook name and recipe short name.
    #
    # For example:
    #   "aws::elastic_ip" returns [:aws, "elastic_ip"]
    #   "aws" returns [:aws, "default"]
    #   "::elastic_ip" returns [ current_cookbook, "elastic_ip" ]
    #--
    # TODO: Duplicates functionality of RunListItem
    def self.parse_recipe_name(recipe_name, current_cookbook: nil)
      case recipe_name
      when /(.+?)::(.+)/
        [ $1.to_sym, $2 ]
      when /^::(.+)/
        raise "current_cookbook is nil, cannot resolve #{recipe_name}" if current_cookbook.nil?

        [ current_cookbook.to_sym, $1 ]
      else
        [ recipe_name.to_sym, "default" ]
      end
    end

    def initialize(cookbook_name, recipe_name, run_context)
      @cookbook_name = cookbook_name
      @recipe_name = recipe_name
      @run_context = run_context
      # TODO: 5/19/2010 cw/tim: determine whether this can be removed
      @params = {}
    end

    # Used in DSL mixins
    def node
      run_context.node
    end

    # This was moved to Chef::Node#tag, redirecting here for compatibility
    def tag(*tags)
      node.tag(*tags)
    end

    # This was moved to Chef::Node#untag, redirecting here for compatibility
    def untag(*tags)
      node.untag(*tags)
    end

    def from_yaml_file(filename)
      self.source_file = filename
      if File.file?(filename) && File.readable?(filename)
        yaml_contents = IO.read(filename)
        # Count document separators instead of using unsafe load_stream
        doc_count = yaml_contents.scan(/^---\s*$/).length
        if doc_count > 1
          raise ArgumentError, "YAML recipe '#{filename}' contains multiple documents, only one is supported"
        end

        from_yaml(yaml_contents)
      else
        raise IOError, "Cannot open or read file '#{filename}'!"
      end
    end

    def from_yaml(string)
      res = ::YAML.safe_load(string, permitted_classes: [Date])
      unless res.is_a?(Hash) && (res.key?("resources") || res.key?("include_recipes"))
        raise ArgumentError, "YAML recipe '#{source_file}' must contain a top-level 'resources' or 'include_recipes' hash (YAML sequence), i.e. 'resources:'"
      end

      from_hash(res)
    end

    def from_json_file(filename)
      self.source_file = filename
      if File.file?(filename) && File.readable?(filename)
        json_contents = IO.read(filename)
        from_json(json_contents)
      else
        raise IOError, "Cannot open or read file '#{filename}'!"
      end
    end

    def from_json(string)
      res = JSONCompat.from_json(string)
      unless res.is_a?(Hash) && (res.key?("resources") || res.key?("include_recipes"))
        raise ArgumentError, "JSON recipe '#{source_file}' must contain a top-level 'resources' or 'include_recipes' hash key"
      end

      from_hash(res)
    end

    def from_hash(hash)
      hash["resources"]&.each do |rhash|
        type = rhash.delete("type").to_sym
        name = rhash.delete("name")
        res = declare_resource(type, name)
        rhash.each do |key, value|
          # FIXME?: we probably need a way to instance_exec a string that contains block code against the property?
          res.send(key, value)
        end
      end
      hash["include_recipes"]&.each do |recipe|
        run_context.include_recipe recipe
      end
    end

    def to_s
      "cookbook: #{cookbook_name || "(none)"}, recipe: #{recipe_name || "(none)"} "
    end

    def inspect
      to_s
    end
  end
end
