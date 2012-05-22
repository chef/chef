#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/search/query'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/encrypted_data_bag_item'
require 'chef/version_constraint'

class Chef
  module Mixin
    module Language

      # Container class for values determined by platform_version constraints of
      # a specific platform
      class PlatformConstraintContainer
        attr_reader :platform_name
        attr_reader :default_values
        attr_reader :constraints_map

        def initialize(platform_name, value_hash)
          value_hash = Mash.from_hash(value_hash)
          @platform_name = platform_name.to_s
          @default_values = nil

          if value_hash.has_key?("default")
            @default_values = value_hash["default"]
            value_hash.delete("default")
          end

          self.constraints_map = value_hash
        end

        private

          def constraints_map=(value_hash)
            constraints_map = hash_keys_to_version_constraints(value_hash)
            assert_not_conflicting_constraints(constraints_map)

            @constraints_map = constraints_map
          end

          def hash_keys_to_version_constraints(hash)
            hash.inject({}) do |new_hash, key_value|
              keys, value = *key_value
              Array(keys).each do |key|
                new_hash[Chef::VersionConstraint.new(key.to_s)] = value
              end
              new_hash
            end
          end

          def assert_not_conflicting_constraints(constraints_map)
            constraints_map.each_key do |key|
              constraints_map.each_key.each do |ver_constraint|
                if ver_constraint.include?(key) && ver_constraint != key
                  raise Chef::Exceptions::VersionConstraintConflict
                end
              end
            end
          end
      end

      # Implementation class for determining platform dependent values
      class PlatformDependentValue
        attr_reader :constraint_containers
        attr_reader :default_values

        # Create a platform dependent value object.
        # === Arguments
        # platform_hash (Hash) a hash of the same structure as Chef::Platform,
        # like this:
        #   {
        #     :debian => {:default => 'the value for all debian'}
        #     [:centos, :redhat, :fedora] => {:default => "value for all EL variants"}
        #     :ubuntu => { :default => "default for ubuntu", '10.04' => "value for 10.04 only"},
        #     :default => "the default when nothing else matches"
        #   }
        # * platforms can be specified as Symbols or Strings
        # * multiple platforms can be grouped by using an Array as the key
        # * values for platforms need to be Hashes of the form:
        #   {platform_version => value_for_that_version}
        # * the exception to the above is the default value, which is given as
        #   :default => default_value
        # * platform_versions must be in SemVer (x.y.z) format or an abbreviated SemVer format (x.y)
        def initialize(platform_hash)
          @constraint_containers = Hash.new
          @default_values = nil
          platform_hash = Mash.from_hash(platform_hash)

          if platform_hash.has_key?("default")
            @default_values = platform_hash["default"]
            platform_hash.delete("default")
          end

          platform_hash.each do |platforms, value_hash|
            assert_valid_platform_values!(platforms, value_hash)

            Array(platforms).each do |platform_name|
              @constraint_containers[platform_name.to_sym] = PlatformConstraintContainer.new(platform_name, value_hash)
            end
          end
        end

        def value_for_node(node)
          platform_name, platform_version = node[:platform].to_s, node[:platform_version].to_s

          satisfy_version(platform_name, platform_version) || 
            default_platform_values(platform_name) || 
            default_values
        end

        private

          def satisfy_version(platform, version)
            constraint_container = constraint_containers[platform.to_sym]
            return nil unless constraint_container

            constraint_container.constraints_map.each do |constraint, value|
              begin
                return value if constraint.include?(version)
              rescue Chef::Exceptions::InvalidCookbookVersion; end
            end

            nil
          end

          def default_platform_values(platform)
            constraint_container = constraint_containers[platform.to_sym]
            return nil unless constraint_container

            constraint_container.default_values
          end

          def assert_valid_platform_values!(platforms, value)
            unless value.kind_of?(Hash)
              msg = "platform dependent values must be specified in the format :platform => {:version => value} "
              msg << "you gave a value #{value.inspect} for platform(s) #{platforms}"
              raise ArgumentError, msg
            end
          end
      end

      # Given a hash similar to the one we use for Platforms, select a value from the hash.  Supports
      # per platform defaults, along with a single base default. Arrays may be passed as hash keys and
      # will be expanded.
      #
      # === Parameters
      # platform_hash:: A platform-style hash.
      #
      # === Returns
      # value:: Whatever the most specific value of the hash is.
      def value_for_platform(platform_hash)
        PlatformDependentValue.new(platform_hash).value_for_node(node)
      end 

      # Given a list of platforms, returns true if the current recipe is being run on a node with
      # that platform, false otherwise.
      #
      # === Parameters
      # args:: A list of platforms. Each platform can be in string or symbol format.
      #
      # === Returns
      # true:: If the current platform is in the list
      # false:: If the current platform is not in the list
      def platform?(*args)
        has_platform = false

        args.flatten.each do |platform|
          has_platform = true if platform.to_s == node[:platform]
        end

        has_platform
      end



     # Implementation class for determining platform family dependent values
      class PlatformFamilyDependentValue

        # Create a platform family dependent value object.
        # === Arguments
        # platform_family_hash (Hash) a map of platform families to values. 
        # like this:
        #   {
        #     :rhel => "value for all EL variants"
        #     :fedora =>  "value for fedora variants fedora and amazon" ,
	#     [:fedora, :rhel] => "value for all known redhat variants"
        #     :debian =>  "value for debian variants including debian, ubuntu, mint" ,
        #     :default => "the default when nothing else matches"
        #   }
        # * platform families can be specified as Symbols or Strings
        # * multiple platform families can be grouped by using an Array as the key
        # * values for platform families can be any object, with no restrictions. Some examples: 
	#   - [:stop, :start]
	#   - "mysql-devel"
        #   - { :key => "value" }
        def initialize(platform_family_hash)
          @values = {}
	  @values["default"] = nil
          platform_family_hash.each { |platform_families, value| set(platform_families, value)}
        end

        def value_for_node(node)
	  if node.key?(:platform_family)
            platform_family = node[:platform_family].to_s
            if @values.key?(platform_family)
              @values[platform_family]
	    else
              @values["default"]
            end
	  else
            @values["default"]
	  end
        end

        private

        def set(platform_family, value)
          if platform_family.to_s == 'default'
            @values["default"] = value
          else
            Array(platform_family).each { |family| @values[family.to_s] = value }
            value
          end
        end
      end


      # Given a hash mapping platform families to values, select a value from the hash. Supports a single
      # base default if platform family is not in the map. Arrays may be passed as hash keys and will be 
      # expanded.  
      #
      # === Parameters
      # platform_family_hash:: A hash in the form { platform_family_name => value } 
      #
      # === Returns
      # value:: Whatever the most specific value of the hash is.
      def value_for_platform_family(platform_family_hash) 
        PlatformFamilyDependentValue.new(platform_family_hash).value_for_node(node)
      end
      
      # Given a list of platform families, returns true if the current recipe is being run on a 
      # node within that platform family, false otherwise. 
      #
      # === Parameters
      # args:: A list of platform families. Each platform family can be in string or symbol format.  
      #
      # === Returns
      # true:: if the current node platform family is in the list. 
      # false:: if the current node platform family is not in the list. 
      def platform_family?(*args)
        has_pf = false
        args.flatten.each do |platform_family|
	  has_pf = true if platform_family.to_s == node[:platform_family] 
        end 
        has_pf
      end	
      
      def search(*args, &block)
        # If you pass a block, or have at least the start argument, do raw result parsing
        #
        # Otherwise, do the iteration for the end user
        if Kernel.block_given? || args.length >= 4
          Chef::Search::Query.new.search(*args, &block)
        else
          results = Array.new
          Chef::Search::Query.new.search(*args) do |o|
            results << o
          end
          results
        end
      end

      def data_bag(bag)
        DataBag.validate_name!(bag.to_s)
        rbag = DataBag.load(bag)
        rbag.keys
      rescue Exception
        Log.error("Failed to list data bag items in data bag: #{bag.inspect}")
        raise
      end

      def data_bag_item(bag, item)
        DataBag.validate_name!(bag.to_s)
        DataBagItem.validate_id!(item)
        DataBagItem.load(bag, item)
      rescue Exception
        Log.error("Failed to load data bag item: #{bag.inspect} #{item.inspect}")
        raise
      end

    end
  end
end
