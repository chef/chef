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

require 'ffi_yajl'
require 'ffi_yajl/json_gem'  # XXX: parts of chef require JSON gem's Hash#to_json monkeypatch

class Chef
  class JSONCompat
    JSON_MAX_NESTING = 1000

    JSON_CLASS = "json_class".freeze

    CHEF_APICLIENT          = "Chef::ApiClient".freeze
    CHEF_CHECKSUM           = "Chef::Checksum".freeze
    CHEF_COOKBOOKVERSION    = "Chef::CookbookVersion".freeze
    CHEF_DATABAG            = "Chef::DataBag".freeze
    CHEF_DATABAGITEM        = "Chef::DataBagItem".freeze
    CHEF_ENVIRONMENT        = "Chef::Environment".freeze
    CHEF_NODE               = "Chef::Node".freeze
    CHEF_ROLE               = "Chef::Role".freeze
    CHEF_SANDBOX            = "Chef::Sandbox".freeze
    CHEF_RESOURCE           = "Chef::Resource".freeze
    CHEF_RESOURCECOLLECTION = "Chef::ResourceCollection".freeze

    class <<self

      # opts_add_max_nesting() removed -- libyajl does not have a configurable max nesting depth

      # Just call the JSON gem's parse method with a modified :max_nesting field
      def from_json(source, opts = {})
        obj = ::FFI_Yajl::Parser.parse(source)

        # JSON gem requires top level object to be a Hash or Array (otherwise
        # you get the "must contain two octets" error). Yajl doesn't impose the
        # same limitation. For compatibility, we re-impose this condition.
        unless obj.kind_of?(Hash) or obj.kind_of?(Array)
          raise JSON::ParserError, "Top level JSON object must be a Hash or Array. (actual: #{obj.class})"
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
      end

      # Look at an object that's a basic type (from json parse) and convert it
      # to an instance of Chef classes if desired.
      def map_to_rb_obj(json_obj)
        case json_obj
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
      end

      def map_hash_to_rb_obj(json_hash)
        json_hash.each do |key, value|
          json_hash[key] = map_to_rb_obj(value)
        end
        json_hash
      end

      def to_json(obj, opts = nil)
        obj.to_json(opts)
      end

      def to_json_pretty(obj, opts = nil)
        ::JSON.pretty_generate(obj, opts)
      end


      # Map +json_class+ to a Class object. We use a +case+ instead of a Hash
      # assigned to a constant because otherwise this file could not be loaded
      # until all the constants were defined, which means you'd have to load
      # the world to get json, which would make knife very slow.
      def class_for_json_class(json_class)
        case json_class
        when CHEF_APICLIENT
          Chef::ApiClient
        when CHEF_CHECKSUM
          Chef::Checksum
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
          # a falsey return here will disable object inflation/"create
          # additions" in the caller. In Chef 11 this is correct, we just have
          # a dummy Chef::Sandbox class for compat with Chef 10 servers.
          false
        when CHEF_RESOURCE
          Chef::Resource
        when CHEF_RESOURCECOLLECTION
          Chef::ResourceCollection
        when /^Chef::Resource/
          Chef::Resource.find_subclass_by_name(json_class)
        else
          raise JSON::ParserError, "Unsupported `json_class` type '#{json_class}'"
        end
      end

    end
  end
end
