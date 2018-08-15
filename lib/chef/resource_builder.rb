#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2017, Chef Software Inc.
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

# NOTE: this was extracted from the Recipe DSL mixin, relevant specs are in spec/unit/recipe_spec.rb

class Chef
  class ResourceBuilder
    attr_reader :type
    attr_reader :name
    attr_reader :created_at
    attr_reader :params
    attr_reader :run_context
    attr_reader :cookbook_name
    attr_reader :recipe_name
    attr_reader :enclosing_provider
    attr_reader :resource

    # FIXME (ruby-2.1 syntax): most of these are mandatory
    def initialize(type: nil, name: nil, created_at: nil, params: nil, run_context: nil, cookbook_name: nil, recipe_name: nil, enclosing_provider: nil)
      @type               = type
      @name               = name
      @created_at         = created_at
      @params             = params
      @run_context        = run_context
      @cookbook_name      = cookbook_name
      @recipe_name        = recipe_name
      @enclosing_provider = enclosing_provider
    end

    def build(&block)
      @resource = resource_class.new(name, run_context)
      if resource.resource_name.nil?
        raise Chef::Exceptions::InvalidResourceSpecification, "#{resource}.resource_name is `nil`!  Did you forget to put `provides :blah` or `resource_name :blah` in your resource class?"
      end
      resource.source_line = created_at
      resource.declared_type = type

      resource.cookbook_name = cookbook_name
      resource.recipe_name = recipe_name
      # Determine whether this resource is being created in the context of an enclosing Provider
      resource.enclosing_provider = enclosing_provider

      # XXX: this is required for definition params inside of the scope of a
      # subresource to work correctly.
      resource.params = params

      # Evaluate resource attribute DSL
      if block_given?
        resource.resource_initializing = true
        begin
          resource.instance_eval(&block)
        ensure
          resource.resource_initializing = false
        end
      end

      # Run optional resource hook
      resource.after_created

      resource
    end

    private

    def resource_class
      # Checks the new platform => short_name => resource mapping initially
      # then fall back to the older approach (Chef::Resource.const_get) for
      # backward compatibility
      @resource_class ||= Chef::Resource.resource_for_node(type, run_context.node)
    end

  end
end

require "chef/exceptions"
require "chef/resource"
require "chef/log"
