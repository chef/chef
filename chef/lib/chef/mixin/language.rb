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

class Chef
  module Mixin
    module Language

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
        result = nil
        
        platform_hash.each_pair do |key, value|
          if key.is_a?(Array)
            key.each { |array_key| platform_hash[array_key] = value }
            platform_hash.delete(key)
          end
        end
        if platform_hash.has_key?(@node[:platform])
          if platform_hash[@node[:platform]].has_key?(@node[:platform_version])
            result = platform_hash[@node[:platform]][@node[:platform_version]]
          elsif platform_hash[@node[:platform]].has_key?("default")
            result = platform_hash[@node[:platform]]["default"]
          end
        end
  
        unless result
          if platform_hash.has_key?("default")
            result = platform_hash["default"]
          end
        end  
  
        result
      end

      # Given a list of platforms, returns true if the current recipe is being run on a node with
      # that platform, false otherwise.
      #
      # === Parameters
      # args:: A list of platforms
      #
      # === Returns
      # true:: If the current platform is in the list
      # false:: If the current platform is not in the list
      def platform?(*args)
        has_platform = false
  
        args.flatten.each do |platform|
          has_platform = true if platform == @node[:platform]
        end
  
        has_platform
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
        rbag = Chef::DataBag.load(bag)
        rbag.keys
      end

      def data_bag_item(bag, item)
        Chef::DataBagItem.load(bag, item)
      end

    end
  end
end
