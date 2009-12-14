#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009 Daniel DeLeo
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

class Chef
  module IndexQueue
    class AmqpClient
      include Singleton

      def initialize
        reset!
      end

      def reset!
        @amqp_client && amqp_client.connected? && amqp_client.stop
        @amqp_client = nil
        @exchange = nil
        @queue = nil
      end
      
      def stop
        @queue && @queue.subscription && @queue.unsubscribe
        @amqp_client && @amqp_client.stop
      end
      
      def amqp_client
        unless @amqp_client
          @amqp_client = Bunny.new(amqp_opts)
          @amqp_client.start
          @amqp_client.qos(:prefetch_count => 1)
        end
        @amqp_client
      end

      def exchange
        @exchange ||= amqp_client.exchange("chef-indexer", :durable => true, :type => :fanout)
      end
      
      def queue
        unless @queue
          @queue = amqp_client.queue("chef-index-consumer-" + UUIDTools::UUID.random_create.to_s)
          @queue.bind(exchange)
        end
        @queue
      end

      def send_action(action, data)
        exchange.publish({"action" => action.to_s, "payload" => data}.to_json)
      end

      private

      def amqp_opts
        { :spec   => '08',
          :host   => Chef::Config[:amqp_host],
          :port   => Chef::Config[:amqp_port],
          :user   => Chef::Config[:amqp_user],
          :pass   => Chef::Config[:amqp_pass],
          :vhost  => Chef::Config[:amqp_vhost]}
      end

    end
  end
end