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

require 'bunny'
require 'yajl'
require 'eventmachine'
require 'amqp'
require 'mq'
require 'highline'

require 'chef/expander/node'
require 'chef/expander/configuration'

require 'pp'

module Chef
  module Expander
    class Control

      def self.run(argv)
        remaining_args_after_opts = Expander.init_config(ARGV)
        new(remaining_args_after_opts).run
      end

      def self.desc(description)
        @desc = description
      end

      def self.option(*args)
        #TODO
      end

      def self.arg(*args)
        #TODO
      end

      def self.descriptions
        @descriptions ||= []
      end

      def self.method_added(method_name)
        if @desc
          descriptions << [method_name, method_name.to_s.gsub('_', '-'), @desc]
          @desc = nil
        end
      end

      #--
      # TODO: this is confusing and unneeded. Just whitelist the methods
      # that map to commands and use +send+
      def self.compile
        run_method = "def run; case @argv.first;"
        descriptions.each do |method_name, command_name, desc|
          run_method << "when '#{command_name}';#{method_name};"
        end
        run_method << "else; help; end; end;"
        class_eval(run_method, __FILE__, __LINE__)
      end

      def initialize(argv)
        @argv = argv.dup
      end

      desc "Show this message"
      def help
        puts "Chef Expander #{Expander.version}"
        puts "Usage: chef-expanderctl COMMAND"
        puts
        puts "Commands:"
        self.class.descriptions.each do |method_name, command_name, desc|
          puts "  #{command_name}".ljust(15) + desc
        end
      end

      desc "display the aggregate queue backlog"
      def queue_depth
        h = HighLine.new
        message_counts = []

        amqp_client = Bunny.new(Expander.config.amqp_config)
        amqp_client.start

        0.upto(VNODES - 1) do |vnode|
          q = amqp_client.queue("vnode-#{vnode}", :durable => true)
          message_counts << q.status[:message_count]
        end
        total_messages = message_counts.inject(0) { |sum, count| sum + count }
        max = message_counts.max
        min = message_counts.min

        avg = total_messages.to_f / message_counts.size.to_f

        puts "  total messages:       #{total_messages}"
        puts "  average queue depth:  #{avg}"
        puts "  max queue depth:      #{max}"
        puts "  min queue depth:      #{min}" 
      ensure
        amqp_client.stop if defined?(amqp_client) && amqp_client
      end

      desc "show the backlog and consumer count for each vnode queue"
      def queue_status
        h = HighLine.new
        queue_status = [h.color("VNode", :bold), h.color("Messages", :bold), h.color("Consumers", :bold)]

        total_messages = 0

        amqp_client = Bunny.new(Expander.config.amqp_config)
        amqp_client.start

        0.upto(VNODES - 1) do |vnode|
          q = amqp_client.queue("vnode-#{vnode}", :durable => true)
          status = q.status
          # returns {:message_count => method.message_count, :consumer_count => method.consumer_count}
          queue_status << vnode.to_s << status[:message_count].to_s << status[:consumer_count].to_s
          total_messages += status[:message_count]
        end
        puts "  total messages: #{total_messages}"
        puts
        puts h.list(queue_status, :columns_across, 3)
      ensure
        amqp_client.stop if defined?(amqp_client) && amqp_client
      end

      desc "show the status of the nodes in the cluster"
      def node_status
        status_mutex = Mutex.new
        h = ::HighLine.new
        node_status = [h.color("Host", :bold), h.color("PID", :bold), h.color("GUID", :bold), h.color("Vnodes", :bold)]

        print("Collecting status info from the cluster...")

        AMQP.start(Expander.config.amqp_config) do
          node = Expander::Node.local_node
          node.exclusive_control_queue.subscribe do |header, message|
            status = Yajl::Parser.parse(message)
            status_mutex.synchronize do
              node_status << status["hostname_f"]
              node_status << status["pid"].to_s
              node_status << status["guid"]
              # BIG ASSUMPTION HERE that nodes only have contiguous vnode ranges
              # will not be true once vnode recovery is implemented
              node_status << "#{status["vnodes"].min}-#{status["vnodes"].max}"
            end
          end
          node.broadcast_message(Yajl::Encoder.encode(:action => :status, :rsvp => node.exclusive_control_queue_name))
          EM.add_timer(2) { AMQP.stop;EM.stop }
        end

        puts "done"
        puts
        puts h.list(node_status, :columns_across, 4)
        puts
      end

      desc "sets the log level of all nodes in the cluster"
      def log_level
        @argv.shift
        level = @argv.first
        acceptable_levels = %w{debug info warn error fatal}
        unless acceptable_levels.include?(level)
          puts "Log level must be one of #{acceptable_levels.join(', ')}"
          exit 1
        end

        h = HighLine.new
        response_mutex = Mutex.new
        
        responses = [h.color("Host", :bold), h.color("PID", :bold), h.color("GUID", :bold), h.color("Log Level", :bold)]
        AMQP.start(Expander.config.amqp_config) do
          node = Expander::Node.local_node
          node.exclusive_control_queue.subscribe do |header, message|
            reply = Yajl::Parser.parse(message)
            n = reply['node']
            response_mutex.synchronize do
              responses << n["hostname_f"] << n["pid"].to_s << n["guid"] << reply["level"]
            end
          end
          node.broadcast_message(Yajl::Encoder.encode({:action => :set_log_level, :level => level, :rsvp => node.exclusive_control_queue_name}))
          EM.add_timer(2) { AMQP.stop; EM.stop }
        end
        puts h.list(responses, :columns_across, 4)
      end


      compile
    end
  end
end
