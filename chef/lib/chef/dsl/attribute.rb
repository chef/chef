#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/exceptions'
require 'chef/mixin/from_file'
require 'chef/dsl/include_attribute'

class Chef
  module DSL

    # == Chef::DSL::Attribute
    # Chef::DSL::Attribute is a wrapper around evaluating attributes files. It
    # is composed of a run_context and node, and implements attribute file
    # loading.
    #
    # Chef::DSL::Attribute is _mostly_ a proxy around the Node object, and
    # unknown methods are unconditionally forwarded to the node.
    class Attribute

      attr_reader :node
      attr_reader :run_context

      include Chef::Mixin::FromFile

      def initialize(node, run_context)
        @node = node
        @run_context = run_context
      end

      def cookbook_collection
        run_context.cookbook_collection
      end

      # Loads the attribute file specified by the short name of the
      # file, e.g., loads specified cookbook's
      #   "attributes/mailservers.rb"
      # if passed
      #   "mailservers"
      def eval_attribute(cookbook_name, attr_file_name)
        cookbook = cookbook_collection[cookbook_name]
        unless cookbook
          raise Chef::Exceptions::CookbookNotFound, "could not find cookbook #{cookbook_name} trying to load attribute #{cookbook_name}::#{attr_file_name}" 
        end

        attribute_filename = cookbook.attribute_filenames_by_short_filename[attr_file_name]
        unless attribute_filename
          raise Chef::Exceptions::AttributeNotFound, "could not find attribute file #{cookbook_name}::#{attr_file_name}"
        end

        self.from_file(attribute_filename)
        self
      end

      def method_missing(method_name, *args, &block)
        node.send(method_name, *args, &block)
      end

    end
  end
end
