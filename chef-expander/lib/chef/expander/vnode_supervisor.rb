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

require 'yajl'
require 'eventmachine'
require 'amqp'
require 'mq'
require 'chef/expander/version'
require 'chef/expander/loggable'
require 'chef/expander/node'
require 'chef/expander/vnode'
require 'chef/expander/vnode_table'
require 'chef/expander/configuration'

module ::AMQP
  def self.hard_reset!
    MQ.reset rescue nil
    stop
    EM.stop rescue nil
    Thread.current[:mq], @conn = nil, nil
  end
end

module Chef
  module Expander
    class VNodeSupervisor
      include Loggable
      extend  Loggable

      COULD_NOT_CONNECT = /Could not connect to server/.freeze

      def self.start_cluster_worker
        @vnode_supervisor = new
        @original_ppid = Process.ppid
        trap_signals

        vnodes = Expander.config.vnode_numbers

        $0 = "chef-expander#{Expander.config.ps_tag} worker ##{Expander.config.index} (vnodes #{vnodes.min}-#{vnodes.max})"

        AMQP.start(Expander.config.amqp_config) do
          start_consumers
          await_parent_death
        end
      end

      def self.await_parent_death
        @awaiting_parent_death = EM.add_periodic_timer(1) do
          unless Process.ppid == @original_ppid
            @awaiting_parent_death.cancel
            stop_immediately("master process death")
          end
        end
      end

      def self.start
        @vnode_supervisor = new
        trap_signals

        Expander.init_config(ARGV)

        log.info("Chef Search Expander #{Expander.version} starting up.")

        begin
          AMQP.start(Expander.config.amqp_config) do
            start_consumers
          end
        rescue AMQP::Error => e
          if e.message =~ COULD_NOT_CONNECT
            log.error { "Could not connect to rabbitmq. Make sure it is running and correctly configured." }
            log.error { e.message }

            AMQP.hard_reset!

            sleep 5
            retry
          else
            raise
          end
        end
      end

      def self.start_consumers
        log.debug { "Setting prefetch count to 1"}
        MQ.prefetch(1)

        vnodes = Expander.config.vnode_numbers
        log.info("Starting Consumers for vnodes #{vnodes.min}-#{vnodes.max}")
        @vnode_supervisor.start(vnodes)
      end

      def self.trap_signals
        Kernel.trap(:INT)  { stop_immediately(:INT) }
        Kernel.trap(:TERM) { stop_gracefully(:TERM) }
      end

      def self.stop_immediately(signal)
        log.info { "Initiating immediate shutdown on signal (#{signal})" }
        @vnode_supervisor.stop
        EM.add_timer(1) do
          AMQP.stop
          EM.stop
        end
      end

      def self.stop_gracefully(signal)
        log.info { "Initiating graceful shutdown on signal (#{signal})" }
        @vnode_supervisor.stop
        wait_for_http_requests_to_complete
      end

      def self.wait_for_http_requests_to_complete
        if Expander::Solrizer.http_requests_active?
          log.info { "waiting for in progress HTTP Requests to complete"}
          EM.add_timer(1) do
            wait_for_http_requests_to_complete
          end
        else
          log.info { "HTTP requests completed, shutting down"}
          AMQP.stop
          EM.stop
        end
      end

      attr_reader :vnode_table

      attr_reader :local_node

      def initialize
        @vnodes = {}
        @vnode_table = VNodeTable.new(self)
        @local_node  = Node.local_node
        @queue_name, @guid = nil, nil
      end

      def start(vnode_ids)
        @local_node.start do |message|
          process_control_message(message)
        end

        #start_vnode_table_publisher

        Array(vnode_ids).each { |vnode_id| spawn_vnode(vnode_id) }
      end

      def stop
        @local_node.stop

        #log.debug { "stopping vnode table updater" }
        #@vnode_table_publisher.cancel

        log.info { "Stopping VNode queue subscribers"}
        @vnodes.each do |vnode_number, vnode|
          log.debug { "Stopping consumer on VNode #{vnode_number}"}
          vnode.stop
        end

      end

      def vnode_added(vnode)
        log.debug { "vnode #{vnode.vnode_number} registered with supervisor" }
        @vnodes[vnode.vnode_number.to_i] = vnode
      end

      def vnode_removed(vnode)
        log.debug { "vnode #{vnode.vnode_number} unregistered from supervisor" }
        @vnodes.delete(vnode.vnode_number.to_i)
      end

      def vnodes
        @vnodes.keys.sort
      end

      def spawn_vnode(vnode_number)
        VNode.new(vnode_number, self).start
      end

      def release_vnode
        # TODO
      end

      def process_control_message(message)
        control_message = parse_symbolic(message)
        case control_message[:action]
        when "claim_vnode"
          spawn_vnode(control_message[:vnode_id])
        when "recover_vnode"
          recover_vnode(control_message[:vnode_id])
        when "release_vnodes"
          raise "todo"
          release_vnode()
        when "update_vnode_table"
          @vnode_table.update_table(control_message[:data])
        when "vnode_table_publish"
          publish_vnode_table
        when "status"
          publish_status_to(control_message[:rsvp])
        when "set_log_level"
          set_log_level(control_message[:level], control_message[:rsvp])
        else
          log.error { "invalid control message #{control_message.inspect}" }
        end
      rescue Exception => e
        log.error { "Error processing a control message."}
        log.error { "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}" }
      end


      def start_vnode_table_publisher
        @vnode_table_publisher = EM.add_periodic_timer(10) { publish_vnode_table }
      end

      def publish_vnode_table
        status_update = @local_node.to_hash
        status_update[:vnodes] = vnodes
        status_update[:update] = :add
        @local_node.broadcast_message(Yajl::Encoder.encode({:action => :update_vnode_table, :data => status_update}))
      end

      def publish_status_to(return_queue)
        status_update = @local_node.to_hash
        status_update[:vnodes] = vnodes
        MQ.queue(return_queue).publish(Yajl::Encoder.encode(status_update))
      end

      def set_log_level(level, rsvp_to)
        log.info { "setting log level to #{level} due to command from #{rsvp_to}" }
        new_log_level = (Expander.config.log_level = level.to_sym)
        reply = {:level => new_log_level, :node => @local_node.to_hash}
        MQ.queue(rsvp_to).publish(Yajl::Encoder.encode(reply))
      end

      def recover_vnode(vnode_id)
        if @vnode_table.local_node_is_leader?
          log.debug { "Recovering vnode: #{vnode_id}" }
          @local_node.shared_message(Yajl::Encoder.encode({:action => :claim_vnode, :vnode_id => vnode_id}))
        else
          log.debug { "Ignoring :recover_vnode message because this node is not the leader" }
        end
      end

      def parse_symbolic(message)
        Yajl::Parser.new(:symbolize_keys => true).parse(message)
      end

    end
  end
end
