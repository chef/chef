#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

# Wrapper class for interacting with JSON.

require 'json'
require 'yajl'

class Chef
  class JSONCompat
    JSON_MAX_NESTING = 1000

    JSON_CLASS = "json_class".freeze

    CHEF_APICLIENT          = "Chef::ApiClient".freeze
    CHEF_COOKBOOKVERSION    = "Chef::CookbookVersion".freeze
    CHEF_DATABAG            = "Chef::DataBag".freeze
    CHEF_DATABAGITEM        = "Chef::DataBagItem".freeze
    CHEF_ENVIRONMENT        = "Chef::Environment".freeze
    CHEF_NODE               = "Chef::Node".freeze
    CHEF_ROLE               = "Chef::Role".freeze
    CHEF_SANDBOX            = "Chef::Sandbox".freeze
    CHEF_RESOURCE           = "Chef::Resource".freeze
    CHEF_RESOURCECOLLECTION = "Chef::ResourceCollection".freeze
    CHEF_WEBUIUSER          = "Chef::WebUIUser".freeze
    CHEF_OPENIDREGISTRAION  = "Chef::OpenIDRegistration".freeze

    class <<self
      # See CHEF-1292/PL-538. Increase the max nesting for JSON, which defaults
      # to 19, and isn't enough for some (for example, a Node within a Node)
      # structures.
      def opts_add_max_nesting(opts)
        if opts.nil? || !opts.has_key?(:max_nesting)
          opts = opts.nil? ? Hash.new : opts.clone
          opts[:max_nesting] = JSON_MAX_NESTING
        end
        opts
      end

      # Just call the JSON gem's parse method with a modified :max_nesting field
      def from_json(source, opts = {})
        obj = ::Yajl::Parser.parse(source)

        unless obj.kind_of?(Hash) || obj.kind_of?(Array)
          raise JSON::ParserError, "Top level JSON object must be a Hash or Array (actual: #{obj.class})"
        end

        # The old default in the json gem (which we are mimicing because we
        # sadly rely on this misfeature) is to "create additions" i.e., convert
        # JSON objects into ruby objects. Explicit :create_additions => false
        # is required to turn it off.
        if opts[:create_additions].nil? || opts[:create_additions]
          map_to_rb_obj(obj)
        else
          obj
        end
      rescue Yajl::ParseError => e
        raise JSON::ParserError, e.message
      end

      # Look at an object that's a basic type (from json parse) and convert it
      # to an instance of Chef classes if desired.
      def map_to_rb_obj(json_obj)
        res = case json_obj
        when Hash
          mapped_hash = map_hash_to_rb_obj(json_obj)
          if json_obj.has_key?(JSON_CLASS) && (class_to_inflate = class_for_json_class(json_obj[JSON_CLASS]))
            class_to_inflate.json_create(mapped_hash)
          else
            mapped_hash
          end
        when Array
          json_obj.map {|e| map_to_rb_obj(e) }
        else
          json_obj
        end
        res
      end

      def map_hash_to_rb_obj(json_hash)
        json_hash.each do |key, value|
          json_hash[key] = map_to_rb_obj(value)
        end
        json_hash
      end

      def to_json(obj, opts = nil)
        obj.to_json(opts_add_max_nesting(opts))
      end

      def to_json_pretty(obj, opts = nil)
        ::JSON.pretty_generate(obj, opts_add_max_nesting(opts))
      end


      def class_for_json_class(json_class)
        case json_class
        when CHEF_APICLIENT
          Chef::ApiClient
        when CHEF_COOKBOOKVERSION
          Chef::CookbookVersion
        when CHEF_DATABAG
          Chef::DataBag
        when CHEF_DATABAGITEM
          Chef::DataBagItem
        when CHEF_ENVIRONMENT
          Chef::Environment
        when CHEF_NODE
          Chef::Node
        when CHEF_ROLE
          Chef::Role
        when CHEF_SANDBOX
          Chef::Sandbox
        when CHEF_RESOURCE
          Chef::Resource
        when CHEF_RESOURCECOLLECTION
          Chef::ResourceCollection
        when CHEF_WEBUIUSER
          Chef::WebUIUser
        when CHEF_OPENIDREGISTRAION
          Chef::OpenIDRegistration
        when /^Chef::Resource/
          Chef::Resource.find_subclass_by_name(json_class)
        else
          raise JSON::ParserError, "Unsupported `json_class` type '#{json_class}'"
        end
      end

    end
  end
end

