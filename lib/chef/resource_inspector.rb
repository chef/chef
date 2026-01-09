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

require_relative "cookbook_loader"
require_relative "cookbook/file_vendor"
require_relative "cookbook/file_system_file_vendor"
require_relative "resource/lwrp_base"
require_relative "run_context"
require_relative "node"
require_relative "resources"
require_relative "json_compat"

# We need to require providers  so that we can resolve
# action documentation that may have been defined on the providers
# instead of the resources.
require_relative "providers"

class Chef
  module ResourceInspector
    def self.get_default(default)
      if default.is_a?(Chef::DelayedEvaluator)
        # ideally we'd get the block we pass to `lazy`, but the best we can do
        # is to get the source location, which then results in reparsing the source
        # code for the resource ourselves and just no
        "lazy default"
      else
        default.is_a?(Symbol) ? default.inspect : default # inspect properly returns symbols
      end
    end

    def self.extract_resource(resource, complete = false)
      data = {}
      data[:description] = resource.description
      data[:target_mode] = resource.target_mode
      data[:default_action] = resource.default_action
      data[:actions] = {}
      resource.allowed_actions.each do |action|
        data[:actions][action] = resource.new(resource.to_s, nil).action_description(action)
      end

      data[:examples] = resource.examples
      data[:introduced] = resource.introduced
      data[:preview] = resource.preview_resource

      properties = unless complete
                     resource.properties.reject { |_, k| k.options[:declared_in] == Chef::Resource || k.options[:skip_docs] }
                   else
                     resource.properties.reject { |_, k| k.options[:skip_docs] }
                   end

      data[:properties] = properties.each_with_object([]) do |(n, k), acc|
        opts = k.options
        acc << { name: n, description: opts[:description],
                 target_mode: opts[:target_mode] || false,
                 introduced: opts[:introduced], is: opts[:is],
                 deprecated: opts[:deprecated] || false,
                 required: opts[:required] || false,
                 default: opts[:default_description] || get_default(opts[:default]),
                 name_property: opts[:name_property] || false,
                 equal_to: sort_equal_to(opts[:equal_to]) }
      end
      data
    end

    def self.sort_equal_to(equal_to)
      Array(equal_to).sort.map(&:inspect)
    rescue ArgumentError
      Array(equal_to).map(&:inspect)
    end

    def self.load_from_resources(resources, complete)
      resources.each_with_object({}) do |r, res|
        pth = r["full_path"]
        # Here we do some magic to extract resources from files where there are multiple resources
        # in a file - to do this, we load the file, and take the delta of which resources
        # exist in object space
        existing_classes = ObjectSpace.each_object(Class).select { |k| k < Chef::Resource }.map { |klass| klass }
        # Load the set of resources from this file
        Chef::Resource::LWRPBase.build_from_file(name, pth, Chef::RunContext.new(Chef::Node.new, nil, nil))
        # Finally, process every new class added to the object space by that
        ObjectSpace.each_object(Class).select { |k| k < Chef::Resource }.each do |klass|
          unless existing_classes.include?(klass)
            # Skip over anything which creates resources that start with exactly this - that happens
            # because if there is no non-classed resource in here, LWRPBase.build_from_file builds a
            # dummy object from it - we don't need that polluting out output!
            next if klass.resource_name.start_with?("Chef__ResourceInspector")

            res[klass.resource_name] = extract_resource(klass, complete)
          end
        end
      end
    end

    def self.extract_cookbook(path, complete)
      path = File.expand_path(path)
      dir, name = File.split(path)
      Chef::Cookbook::FileVendor.fetch_from_disk(path)
      loader = Chef::CookbookLoader.new(dir)
      cookbook = loader.load_cookbook(name)
      load_from_resources(cookbook.files_for(:resources), complete)
    end

    # If we're given no resources, dump all of Chef's built ins
    # otherwise, if we have a path then extract all the resources from the cookbook
    # or else do a list of built in resources
    #
    # @param arguments [Array, String] One of more paths to a cookbook or a resource file to inspect
    # @param complete [TrueClass, FalseClass] Whether to show properties defined in the base Resource class
    # @return [String] JSON formatting of all resources
    def self.inspect(arguments = [], complete: false)
      output = if arguments.empty?
                 ObjectSpace.each_object(Class).select { |k| k < Chef::Resource }.each_with_object({}) { |klass, acc| acc[klass.resource_name] = extract_resource(klass) }
               else
                 Array(arguments).each_with_object({}) do |arg, acc|
                   if File.directory?(arg)
                     extract_cookbook(arg, complete).each { |k, v| acc[k] = v }
                   else
                     r = Chef::ResourceResolver.resolve(arg.to_sym)
                     acc[r.resource_name] = extract_resource(r, complete)
                   end
                 end
               end

      Chef::JSONCompat.to_json_pretty(output)
    end

    def self.start
      puts inspect(ARGV, complete: true)
    end

  end
end
