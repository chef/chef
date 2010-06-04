#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/log'
require 'chef/config'
require 'chef/solr'
require 'chef/solr/index'
require 'chef/node'
require 'chef/role'
require 'chef/rest'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'chef/api_client'
require 'chef/couchdb'
require 'chef/index_queue'

class Chef
  class Solr
    class IndexQueueConsumer
      include Chef::IndexQueue::Consumer

      expose :add, :delete
      
      def add(payload)
        index = Chef::Solr::Index.new
        Chef::Log.debug("Dequeued item for indexing: #{payload.inspect}")

        begin
          pitem = payload["item"].to_hash                  
          response = generate_response { index.add(payload["id"], payload["database"], payload["type"], pitem) }                  
        rescue NoMethodError
          response = generate_response() { raise ArgumentError, "Payload item does not respond to :keys or :to_hash, cannot index!" }
        end
        
        msg = "Indexing #{payload["type"]} #{payload["id"]} from #{payload["database"]} status #{status_message(response)}}"
        Chef::Log.info(msg)
        response 
      end

      def delete(payload)
        response = generate_response { Chef::Solr::Index.new.delete(payload["id"]) }
        Chef::Log.info("Removed #{payload["id"]} from the index")
        response
      end
      
      private

      def generate_response(&block)
        response = {}
        begin
          block.call
        rescue => e
          response[:status] = :error
          response[:error] = e
        else
          response[:status] = :ok
        end
        response
      end

      def status_message(response)
        msg = response[:status].to_s
        msg << ' ' + response[:error].to_s if response[:status] == :error
        msg
      end

    end
  end
end

