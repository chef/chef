#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
      raise ArgumentError, "You must supply a name when declaring a #{type} resource" if name.nil?

      @resource = resource_class.new(name, run_context)
      if resource.resource_name.nil?
        raise Chef::Exceptions::InvalidResourceSpecification, "#{resource}.resource_name is `nil`!  Did you forget to put `provides :blah` or `resource_name :blah` in your resource class?"
      end
      resource.source_line = created_at
      resource.declared_type = type

      # If we have a resource like this one, we want to steal its state
      # This behavior is very counter-intuitive and should be removed.
      # See CHEF-3694, https://tickets.opscode.com/browse/CHEF-3694
      # Moved to this location to resolve CHEF-5052, https://tickets.opscode.com/browse/CHEF-5052
      if prior_resource
        resource.load_from(prior_resource)
      end

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

      # emit a cloned resource warning if it is warranted
      if prior_resource
        if is_trivial_resource?(prior_resource) && identicalish_resources?(prior_resource, resource)
          emit_harmless_cloning_debug
        else
          emit_cloned_resource_warning
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

    def is_trivial_resource?(resource)
      trivial_resource = resource_class.new(name, run_context)
      # force un-lazy the name property on the created trivial resource
      name_property = resource_class.properties.find { |sym, p| p.name_property? }
      trivial_resource.send(name_property[0]) unless name_property.nil?
      identicalish_resources?(trivial_resource, resource)
    end

    # this is an equality test specific to checking for 3694 cloning warnings
    def identicalish_resources?(first, second)
      skipped_ivars = [ :@source_line, :@cookbook_name, :@recipe_name, :@params, :@elapsed_time, :@declared_type ]
      checked_ivars = ( first.instance_variables | second.instance_variables ) - skipped_ivars
      non_matching_ivars = checked_ivars.reject do |iv|
        if iv == :@action && ( [first.instance_variable_get(iv)].flatten == [:nothing] || [second.instance_variable_get(iv)].flatten == [:nothing] )
          # :nothing action on either side of the comparison always matches
          true
        else
          first.instance_variable_get(iv) == second.instance_variable_get(iv)
        end
      end
      Chef::Log.debug("ivars which did not match with the prior resource: #{non_matching_ivars}")
      non_matching_ivars.empty?
    end

    def emit_cloned_resource_warning
      message = "Cloning resource attributes for #{resource} from prior resource (CHEF-3694)"
      message << "\nPrevious #{prior_resource}: #{prior_resource.source_line}" if prior_resource.source_line
      message << "\nCurrent  #{resource}: #{resource.source_line}" if resource.source_line
      Chef.log_deprecation(message)
    end

    def emit_harmless_cloning_debug
      Chef::Log.debug("Harmless resource cloning from #{prior_resource}:#{prior_resource.source_line} to #{resource}:#{resource.source_line}")
    end

    def prior_resource
      @prior_resource ||=
        begin
          key = "#{type}[#{name}]"
          run_context.resource_collection.lookup_local(key)
        rescue Chef::Exceptions::ResourceNotFound
          nil
        end
    end

  end
end

require "chef/exceptions"
require "chef/resource"
require "chef/log"
