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

class Chef
  module DSL

    # ==Chef::DSL::DataQuery
    # Provides DSL for querying data from the chef-server via search or data
    # bag.
    module DataQuery

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

      def data_bag_item(bag, item, secret=nil)
        DataBag.validate_name!(bag.to_s)
        DataBagItem.validate_id!(item)
        item = DataBagItem.load(bag, item)
        if encrypted?(item.raw_data)
          Log.debug("Data bag item looks encrypted: #{bag.inspect} #{item.inspect}")
          secret ||= EncryptedDataBagItem.load_secret
          item = EncryptedDataBagItem.new(item.raw_data, secret)
        end
        item
      rescue Exception => e
        Log.error("Failed to load data bag item: #{bag.inspect} #{item.inspect}")
        raise
      end

      private

      # Tries to autodetect if the item's raw hash appears to be encrypted.
      def encrypted?(data)
        data.each do |key, value|
          next if key == "id"
          return false unless looks_like_encrypted?(value)
        end
        true
      end

      # Checks if data looks like it has been encrypted by
      # Chef::EncryptedDataBagItem::Encryptor::VersionXEncryptor. Returns
      # true only when there is an exact match between the VersionXEncryptor
      # keys and the hash's keys.
      def looks_like_encrypted?(data)
        return false unless data.is_a?(Hash) && data.has_key?("version")
        case data["version"]
        when 1
          Chef::EncryptedDataBagItem::Encryptor::Version1Encryptor.encryptor_keys.sort == data.keys.sort
        when 2
          Chef::EncryptedDataBagItem::Encryptor::Version2Encryptor.encryptor_keys.sort == data.keys.sort
        when 3
          Chef::EncryptedDataBagItem::Encryptor::Version3Encryptor.encryptor_keys.sort == data.keys.sort
        else
          false # version means something else... assume not encrypted.
        end
      end
    end
  end
end

# **DEPRECATED**
# This used to be part of chef/mixin/language. Load the file to activate the deprecation code.
require 'chef/mixin/language'
