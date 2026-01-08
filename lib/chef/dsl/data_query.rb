#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "../search/query"
Chef.autoload :DataBag, File.expand_path("../data_bag", __dir__)
Chef.autoload :DataBagItem, File.expand_path("../data_bag_item", __dir__)
require_relative "../encrypted_data_bag_item"
require_relative "../encrypted_data_bag_item/check_encrypted"

class Chef
  module DSL

    # Provides DSL helper methods for querying the search interface, data bag
    # interface or node interface.
    #
    module DataQuery
      include Chef::EncryptedDataBagItem::CheckEncrypted

      def search(*args, &block)
        # If you pass a block, or have at least the start argument, do raw result parsing
        #
        # Otherwise, do the iteration for the end user
        if Kernel.block_given? || args.length >= 4
          Chef::Search::Query.new.search(*args, &block)
        else
          results = []
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

      def data_bag_item(bag, item, secret = nil)
        DataBag.validate_name!(bag.to_s)
        DataBagItem.validate_id!(item)

        item = DataBagItem.load(bag, item)
        if encrypted?(item.raw_data)
          Log.debug("Data bag item looks encrypted: #{bag.inspect} #{item.inspect}")

          # Try to load the data bag item secret, if secret is not provided.
          # Chef::EncryptedDataBagItem.load_secret may throw a variety of errors.
          begin
            secret ||= EncryptedDataBagItem.load_secret
            item = EncryptedDataBagItem.new(item.raw_data, secret)
          rescue Exception
            Log.error("Failed to load secret for encrypted data bag item: #{bag.inspect} #{item.inspect}")
            raise
          end
        end

        item
      rescue Exception
        Log.error("Failed to load data bag item: #{bag.inspect} #{item.inspect}")
        raise
      end

      #
      # Note that this is mixed into the Universal DSL so access to the node needs to be done
      # through the run_context and not accessing the node method directly, since the node method
      # is not as universal as the run_context.
      #

      # True if all the tags are set on the node.
      #
      # @param [Array<String>] tags to check against
      # @return boolean
      #
      def tagged?(*tags)
        tags.each do |tag|
          return false unless run_context.node.tags.include?(tag)
        end
        true
      end

    end
  end
end
