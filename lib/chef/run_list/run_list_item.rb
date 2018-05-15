#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

class Chef
  class RunList
    class RunListItem
      QUALIFIED_RECIPE             = %r{^recipe\[([^\]@]+)(@([0-9]+(\.[0-9]+){1,2}))?\]$}
      QUALIFIED_ROLE               = %r{^role\[([^\]]+)\]$}
      VERSIONED_UNQUALIFIED_RECIPE = %r{^([^@]+)(@([0-9]+(\.[0-9]+){1,2}))$}
      FALSE_FRIEND                 = %r{[\[\]]}

      attr_reader :name, :type, :version

      def initialize(item)
        @version = nil
        case item
        when Hash
          assert_hash_is_valid_run_list_item!(item)
          @type = (item["type"] || item[:type]).to_sym
          @name = item["name"] || item[:name]
          if item.has_key?("version") || item.has_key?(:version)
            @version = item["version"] || item[:version]
          end
        when String
          if match = QUALIFIED_RECIPE.match(item)
            # recipe[recipe_name]
            # recipe[recipe_name@1.0.0]
            @type = :recipe
            @name = match[1]
            @version = match[3] if match[3]
          elsif match = QUALIFIED_ROLE.match(item)
            # role[role_name]
            @type = :role
            @name = match[1]
          elsif match = VERSIONED_UNQUALIFIED_RECIPE.match(item)
            # recipe_name@1.0.0
            @type = :recipe
            @name = match[1]
            @version = match[3] if match[3]
          elsif match = FALSE_FRIEND.match(item)
            # Recipe[recipe_name]
            # roles[role_name]
            name = match[1]
            raise ArgumentError, "Unable to create #{self.class} from #{item.class}:#{item.inspect}: must be recipe[#{name}] or role[#{name}]"

          else
            # recipe_name
            @type = :recipe
            @name = item
          end
        else
          raise ArgumentError, "Unable to create #{self.class} from #{item.class}:#{item.inspect}: must be a Hash or String"
        end
      end

      def to_s
        "#{@type}[#{@name}#{@version ? "@#{@version}" : ""}]"
      end

      def role?
        @type == :role
      end

      def recipe?
        @type == :recipe
      end

      def ==(other)
        if other.kind_of?(String)
          to_s == other.to_s
        else
          other.respond_to?(:type) && other.respond_to?(:name) && other.respond_to?(:version) && other.type == @type && other.name == @name && other.version == @version
        end
      end

      def assert_hash_is_valid_run_list_item!(item)
        unless (item.key?("type") || item.key?(:type)) && (item.key?("name") || item.key?(:name))
          raise ArgumentError, "Initializing a #{self.class} from a hash requires that it have a 'type' and 'name' key"
        end
      end

    end
  end
end
