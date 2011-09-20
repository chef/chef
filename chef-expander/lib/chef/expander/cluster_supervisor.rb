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

require 'chef/expander/loggable'
require 'chef/expander/daemonizable'
require 'chef/expander/version'
require 'chef/expander/configuration'
require 'chef/expander/vnode_supervisor'

module Chef
  module Expander
    #==ClusterSupervisor
    # Manages a cluster of chef-expander processes. Usually this class will
    # be instantiated from the chef-expander-cluster executable.
    #
    # ClusterSupervisor works by forking the desired number of processes, then
    # running VNodeSupervisor.start_cluster_worker within the forked process.
    # ClusterSupervisor keeps track of the process ids of its children, and will
    # periodically attempt to reap them in a non-blocking call. If they are
    # reaped, ClusterSupervisor knows they died and need to be respawned.
    #
    # The child processes are responsible for checking on the master process and
    # dying if the master has died (VNodeSupervisor does this when started in 
    # with start_cluster_worker).
    #
    #===TODO:
    # * This implementation currently assumes there is only one cluster, so it
    #   will claim all of the vnodes. It may be advantageous to allow multiple
    #   clusters.
    # * There is no heartbeat implementation at this time, so a zombified child
    #   process will not be automatically killed--This behavior is left to the
    #   meatcloud for now.
    class ClusterSupervisor
      include Loggable
      include Daemonizable

      def initialize
        @workers = {}
        @running = true
        @kill    = :TERM
      end

      def start
        trap(:INT)  { stop(:INT) }
        trap(:TERM) { stop(:TERM)}
        Expander.init_config(ARGV)

        log.info("Chef Expander #{Expander.version} starting cluster with #{Expander.config.node_count} nodes")
        configure_process
        start_workers
        maintain_workers
        release_locks
      rescue Configuration::InvalidConfiguration => e
        log.fatal {"Configuration Error: " + e.message}
        exit(2)
      rescue Exception => e
        raise if SystemExit === e

        log.fatal {e}
        exit(1)
      end

      def start_workers
        Expander.config.node_count.times do |i|
          start_worker(i + 1)
        end
      end

      def start_worker(index)
        log.info { "Starting cluster worker #{index}" }
        worker_params = {:index => index}
        child_pid = fork do
          Expander.config.index = index
          VNodeSupervisor.start_cluster_worker
        end
        @workers[child_pid] = worker_params
      end

      def stop(signal)
        log.info { "Stopping cluster on signal (#{signal})" }
        @running = false
        @kill    = signal
      end

      def maintain_workers
        while @running
          sleep 1
          workers_to_replace = {}
          @workers.each do |process_id, worker_params|
            if result = Process.waitpid2(process_id, Process::WNOHANG)
              log.error { "worker #{worker_params[:index]} (PID: #{process_id}) died with status #{result[1].exitstatus || '(no status)'}"}
              workers_to_replace[process_id] = worker_params
            end
          end
          workers_to_replace.each do |dead_pid, worker_params|
            @workers.delete(dead_pid)
            start_worker(worker_params[:index])
          end
        end

        @workers.each do |pid, worker_params|
          log.info { "Stopping worker #{worker_params[:index]} (PID: #{pid})"}
          Process.kill(@kill, pid)
        end
        @workers.each do |pid, worker_params|
          Process.waitpid2(pid)
        end

      end

    end
  end
end
