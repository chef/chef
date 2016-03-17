#--
# Author:: Lamont Granquist (<lamont@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
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

require "net/http/persistent"
require "singleton"
require "forwardable"

class Chef
  class HTTP
    class ClientCache
      include Singleton
      extend Forwardable

      attr_accessor :config
      attr_accessor :logger
      attr_accessor :caches
      attr_accessor :read_timeout
      attr_accessor :open_timeout
      attr_accessor :max_requests
      attr_accessor :idle_timeout

      def initialize
        reset!
      end

      # Changing the SSL policy on a Net::HTTP::Persistent object invalidates all of the
      # connections, so we create a cache of them based on SSL policy
      def for_ssl_policy(ssl_policy, opts = {})
        set_opts(opts)
        caches[ssl_policy.hash] ||=
          begin
            logger.debug "Creating new Net::HTTP::Persistent object for #{ssl_policy}"
            cache = new_cache
            ssl_policy.apply_to(cache, config: config) if ssl_policy
            cache
          end
      end

      def set_opts(opts)
        opts ||= {}
        @config = opts[:config] if opts[:config]
        @logger = opts[:logger] if opts[:logger]
      end

      def config=(hash)
        reset_vars!
        @config = hash
      end

      def config
        @config ||= Chef::Config
      end

      def logger
        @logger ||= Chef::Log.logger
      end

      def shutdown
        logger.debug "Shutting down Net::HTTP::Persistent caches"
        caches.each_value do |cache|
          cache.shutdown
        end
        reset!
      end

      def reset_vars!
        @read_timeout = nil
        @open_timeout = nil
        @max_requests = nil
        @idle_timeout = nil
      end

      def reset!
        logger.debug "Releasing Net::HTTP::Persistent cache objects"
        @caches = {}
      end

      def read_timeout
        @read_timeout ||= config[:rest_timeout]
      end

      def open_timeout
        @open_timeout ||= config[:rest_timeout]
      end

      def max_requests
        @max_requests ||= config[:max_requests]
      end

      def idle_timeout
        @idle_timeout ||= config[:idle_timeout]
      end

      private

      def new_cache
        cache = Net::HTTP::Persistent.new
        cache.read_timeout = read_timeout
        cache.open_timeout = open_timeout
        cache.max_requests = max_requests
        cache.idle_timeout = idle_timeout
        cache
      end
    end
  end
end
