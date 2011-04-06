#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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
#
require 'chef/json_compat'

class Chef
  module IndexQueue
    module Indexable
      
      module ClassMethods
        
        def index_object_type(explicit_type_name=nil)
          @index_object_type = explicit_type_name.to_s if explicit_type_name
          @index_object_type
        end
        
        # Resets all metadata used for indexing to nil. Used for testing
        def reset_index_metadata!
          @index_object_type = nil
        end
        
      end

      def self.included(including_class)
        including_class.send(:extend, ClassMethods)
      end
      
      attr_accessor :index_id
      
      def index_object_type
        self.class.index_object_type || Mixin::ConvertToClassName.snake_case_basename(self.class.name)
      end
      
      def with_indexer_metadata(indexer_metadata={})
        # changing input param symbol keys to strings, as the keys in hash that goes to solr are expected to be strings [cb]
        # Ruby 1.9 hates you, cb [dan]
        with_metadata = {}
        indexer_metadata.each_key do |key|
          with_metadata[key.to_s] = indexer_metadata[key]
        end

        with_metadata["type"]     ||= self.index_object_type
        with_metadata["id"]       ||= self.index_id
        with_metadata["database"] ||= Chef::Config[:couchdb_database]
        with_metadata["item"]     ||= self.to_hash
        with_metadata["enqueued_at"] ||= Time.now.utc.to_i

        raise ArgumentError, "Type, Id, or Database missing in index operation: #{with_metadata.inspect}" if (with_metadata["id"].nil? or with_metadata["type"].nil?)
        with_metadata        
      end

      def add_to_index(metadata={})
       Chef::Log.debug("Pushing item to index queue for addition: #{self.with_indexer_metadata(metadata)}")
       object_with_metadata = with_indexer_metadata(metadata)
       obj_id = object_with_metadata["id"]
       obj = {:action => :add, :payload => self.with_indexer_metadata(metadata)}

       publish_object(obj_id, obj)
      end

      def delete_from_index(metadata={})
        Chef::Log.debug("Pushing item to index queue for deletion: #{self.with_indexer_metadata(metadata)}")
        object_with_metadata = with_indexer_metadata(metadata)
        obj_id = object_with_metadata["id"]
        obj = {:action => :delete, :payload => self.with_indexer_metadata(metadata)}

        publish_object(obj_id, obj)
      end

      private

      # Uses the publisher to update the object's queue. If
      # Chef::Config[:persistent_queue] is true, the update is wrapped
      # in a transaction.
      def publish_object(object_id, object)
        publisher = AmqpClient.instance
        begin
          publisher.amqp_client.tx_select if Chef::Config[:persistent_queue]
          publisher.queue_for_object(object_id) do |queue|
            queue.publish(Chef::JSONCompat.to_json(object), :persistent => Chef::Config[:persistent_queue])
          end
          publisher.amqp_client.tx_commit if Chef::Config[:persistent_queue]
        rescue
          publisher.amqp_client.tx_rollback if Chef::Config[:persistent_queue]
          raise
        end

        true
      end

    end
  end
end
