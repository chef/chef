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

require 'rubygems'
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
require 'nanite/actor'

class Chef
  class Solr
    class IndexActor
      include ::Nanite::Actor

      expose :add, :delete, :commit, :optimize

      def add(payload)
        index = Chef::Solr::Index.new

        pitem = nil
        if payload["item"].respond_to?(:keys)
          pitem = payload["item"]
        elsif payload["item"].respond_to?(:to_hash)
          pitem = payload["item"].to_hash
        else
          return generate_response() { raise ArgumentError, "Payload item does not respond to :keys or :to_hash, cannot index!" }
        end
        response = generate_response { index.add(payload["id"], payload["database"], payload["type"], pitem) }
        Chef::Log.info("Indexing #{payload["type"]} #{payload["id"]} from #{payload["database"]} status #{response[:status]}#{response[:status] == :error ? ' ' + response[:error] : ''}")
        response 
      end

      def delete(payload)
        index = Chef::Solr::Index.new
        generate_response { index.delete(payload["id"]) }
        Chef::Log.info("Removed #{payload["id"]} from the index")
      end

      def commit(payload)
        index = Chef::Solr::Index.new
        generate_response { index.solr_commit }
        Chef::Log.info("Committed the index")
      end

      def optimize(payload)
        index = Chef::Solr::Index.new
        generate_response { index.solr_optimize }
        Chef::Log.info("Optimized the index")
      end

      private
        def generate_response(&block)
          response = {}
          begin
            block.call
          rescue
            response[:status] = :error
            response[:error] = $!
          else
            response[:status] = :ok
          end
          response
        end

    end
  end
end

