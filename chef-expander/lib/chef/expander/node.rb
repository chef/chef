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

require 'uuidtools'
require 'amqp'
require 'mq'
require 'open3'

require 'chef/expander/loggable'

module Chef
  module Expander
    class Node

      include Loggable

      def self.from_hash(node_info)
        new(node_info[:guid], node_info[:hostname_f], node_info[:pid])
      end

      def self.local_node
        new(guid, hostname_f, Process.pid)
      end

      def self.guid
        return @guid if @guid
        @guid = UUIDTools::UUID.random_create.to_s
      end

      def self.hostname_f
        @hostname ||= Open3.popen3("hostname -f") {|stdin, stdout, stderr| stdout.read }.strip
      end

      attr_reader :guid

      attr_reader :hostname_f

      attr_reader :pid

      def initialize(guid, hostname_f, pid)
        @guid, @hostname_f, @pid = guid, hostname_f, pid
      end

      def start(&message_handler)
        attach_to_queue(exclusive_control_queue, "exclusive control", &message_handler)
        attach_to_queue(shared_control_queue, "shared_control", &message_handler)
        attach_to_queue(broadcast_control_queue, "broadcast control", &message_handler)
      end

      def attach_to_queue(queue, colloquial_name, &message_handler)
        queue.subscribe(:ack => true) do |headers, payload|
          log.debug { "received message on #{colloquial_name} queue: #{payload}" }
          message_handler.call(payload)
          headers.ack
        end
      end

      def stop
        log.debug { "unsubscribing from broadcast control queue"}
        broadcast_control_queue.unsubscribe(:nowait => false)

        log.debug { "unsubscribing from shared control queue" }
        shared_control_queue.unsubscribe(:nowait => false)

        log.debug { "unsubscribing from exclusive control queue" }
        exclusive_control_queue.unsubscribe(:nowait => false)
      end

      def direct_message(message)
        log.debug { "publishing direct message to node #{identifier}: #{message}" }
        exclusive_control_queue.publish(message)
      end

      def shared_message(message)
        log.debug { "publishing shared message #{message}"}
        shared_control_queue.publish(message)
      end

      def broadcast_message(message)
        log.debug { "publishing broadcast message #{message}" }
        broadcast_control_exchange.publish(message)
      end

      # The exclusive control queue is for point-to-point messaging, i.e.,
      # messages directly addressed to this node
      def exclusive_control_queue
        @exclusive_control_queue ||= begin
          log.debug { "declaring exclusive control queue #{exclusive_control_queue_name}" }
          MQ.queue(exclusive_control_queue_name)
        end
      end

      # The shared control queue is for 1 to (1 of N) messaging, i.e.,
      # messages that can go to any one node.
      def shared_control_queue
        @shared_control_queue ||= begin
          log.debug { "declaring shared control queue #{shared_control_queue_name}" }
          MQ.queue(shared_control_queue_name)
        end
      end

      # The broadcast control queue is for 1 to N messaging, i.e.,
      # messages that go to every node
      def broadcast_control_queue
        @broadcast_control_queue ||= begin
          log.debug { "declaring broadcast control queue #{broadcast_control_queue_name}"}
          q = MQ.queue(broadcast_control_queue_name)
          log.debug { "binding broadcast control queue to broadcast control exchange"}
          q.bind(broadcast_control_exchange)
          q
        end
      end

      def broadcast_control_exchange
        @broadcast_control_exchange ||= begin
          log.debug { "declaring broadcast control exchange opscode-platfrom-control--broadcast" }
          MQ.fanout(broadcast_control_exchange_name, :nowait => false)
        end
      end

      def shared_control_queue_name
        SHARED_CONTROL_QUEUE_NAME
      end

      def broadcast_control_queue_name
        @broadcast_control_queue_name ||= "#{identifier}--broadcast"
      end

      def broadcast_control_exchange_name
        BROADCAST_CONTROL_EXCHANGE_NAME
      end

      def exclusive_control_queue_name
        @exclusive_control_queue_name ||= "#{identifier}--exclusive-control"
      end

      def identifier
        "#{hostname_f}--#{pid}--#{guid}"
      end

      def ==(other)
        other.respond_to?(:guid) && other.respond_to?(:hostname_f) && other.respond_to?(:pid) &&
        (other.guid == guid) && (other.hostname_f == hostname_f) && (other.pid == pid)
      end

      def eql?(other)
        (other.class == self.class) && (other.hash == hash)
      end

      def hash
        identifier.hash
      end

      def to_hash
        {:guid => @guid, :hostname_f => @hostname_f, :pid => @pid}
      end

    end
  end
end
