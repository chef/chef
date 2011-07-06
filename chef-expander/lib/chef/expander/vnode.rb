#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'eventmachine'
require 'amqp'
require 'mq'

require 'chef/expander/loggable'
require 'chef/expander/solrizer'

module Chef
  module Expander
    class VNode
      include Loggable

      attr_reader :vnode_number

      attr_reader :supervise_interval

      def initialize(vnode_number, supervisor, opts={})
        @vnode_number = vnode_number.to_i
        @supervisor   = supervisor
        @queue    = nil
        @stopped  = false
        @supervise_interval = opts[:supervise_interval] || 30
      end

      def start
        @supervisor.vnode_added(self)

        subscription_confirmed = Proc.new do
          abort_on_multiple_subscribe
          supervise_consumer_count
        end

        queue.subscribe(:ack => true, :confirm => subscription_confirmed) do |headers, payload|
          log.debug {"got #{payload} size(#{payload.size} bytes) on queue #{queue_name}"}
          solrizer = Solrizer.new(payload) { headers.ack }
          solrizer.run
        end

      rescue MQ::Error => e
        log.error {"Failed to start subscriber on #{queue_name} #{e.class.name}: #{e.message}"}
      end

      def supervise_consumer_count
        EM.add_periodic_timer(supervise_interval) do
          abort_on_multiple_subscribe
        end
      end

      def abort_on_multiple_subscribe
        queue.status do |message_count, subscriber_count|
          if subscriber_count.to_i > 1
            log.error { "Detected extra consumers (#{subscriber_count} total) on queue #{queue_name}, cancelling subscription" }
            stop
          end
        end
      end

      def stop
        log.debug {"Cancelling subscription on queue #{queue_name.inspect}"}
        queue.unsubscribe if queue.subscribed?
        @supervisor.vnode_removed(self)
        @stopped = true
      end

      def stopped?
        @stopped
      end

      def queue
        @queue ||= begin
          log.debug { "declaring queue #{queue_name}" }
          MQ.queue(queue_name, :passive => false, :durable => true)
        end
      end

      def queue_name
        "vnode-#{@vnode_number}"
      end

      def control_queue_name
        "#{queue_name}-control"
      end

    end
  end
end
