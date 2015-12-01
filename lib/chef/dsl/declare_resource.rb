#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009-2015 Chef Software, Inc.
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

require 'chef/exceptions'

class Chef
  module DSL
    module DeclareResource

      #
      # Instantiates a resource (via #build_resource), then adds it to the
      # resource collection. Note that resource classes are looked up directly,
      # so this will create the resource you intended even if the method name
      # corresponding to that resource has been overridden.
      #
      # @param type [Symbol] The type of resource (e.g. `:file` or `:package`)
      # @param name [String] The name of the resource (e.g. '/x/y.txt' or 'apache2')
      # @param created_at [String] The caller of the resource.  Use `caller[0]`
      #   to get the caller of your function.  Defaults to the caller of this
      #   function.
      # @param resource_attrs_block A block that lets you set attributes of the
      #   resource (it is instance_eval'd on the resource instance).
      #
      # @return [Chef::Resource] The new resource.
      #
      # @example
      #   declare_resource(:file, '/x/y.txy', caller[0]) do
      #     action :delete
      #   end
      #   # Equivalent to
      #   file '/x/y.txt' do
      #     action :delete
      #   end
      #
      def declare_resource(type, name, created_at=nil, run_context: self.run_context, create_if_missing: false, &resource_attrs_block)
        created_at ||= caller[0]

        if create_if_missing
          begin
            resource = run_context.resource_collection.find(type => name)
            return resource
          rescue Chef::Exceptions::ResourceNotFound
          end
        end

        resource = build_resource(type, name, created_at, &resource_attrs_block)

        run_context.resource_collection.insert(resource, resource_type: type, instance_name: name)
        resource
      end

      #
      # Instantiate a resource of the given +type+ with the given +name+ and
      # attributes as given in the +resource_attrs_block+.
      #
      # The resource is NOT added to the resource collection.
      #
      # @param type [Symbol] The type of resource (e.g. `:file` or `:package`)
      # @param name [String] The name of the resource (e.g. '/x/y.txt' or 'apache2')
      # @param created_at [String] The caller of the resource.  Use `caller[0]`
      #   to get the caller of your function.  Defaults to the caller of this
      #   function.
      # @param resource_attrs_block A block that lets you set attributes of the
      #   resource (it is instance_eval'd on the resource instance).
      #
      # @return [Chef::Resource] The new resource.
      #
      # @example
      #   build_resource(:file, '/x/y.txy', caller[0]) do
      #     action :delete
      #   end
      #
      def build_resource(type, name, created_at=nil, run_context: self.run_context, &resource_attrs_block)
        created_at ||= caller[0]
        Thread.exclusive do
          require 'chef/resource_builder' unless defined?(Chef::ResourceBuilder)
        end

        Chef::ResourceBuilder.new(
          type:                type,
          name:                name,
          created_at:          created_at,
          params:              @params,
          run_context:         run_context,
          cookbook_name:       cookbook_name,
          recipe_name:         recipe_name,
          enclosing_provider:  self.is_a?(Chef::Provider) ? self :  nil
        ).build(&resource_attrs_block)
      end
    end
  end
end
