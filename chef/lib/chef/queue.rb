#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/mixin/params_validate'
require 'json'
require 'stomp'

class Chef
  class Queue

    @client = nil
    @queue_retry_delay = Chef::Config[:queue_retry_delay]
    @queue_retry_count = Chef::Config[:queue_retry_count]

    class << self
      include Chef::Mixin::ParamsValidate

      def connect
        queue_user     = Chef::Config[:queue_user]
        queue_password = Chef::Config[:queue_password]
        queue_host = Chef::Config[:queue_host]
        queue_port = Chef::Config[:queue_port]
        queue_retries = 1 unless queue_retries

        # Connection.open(login = "", passcode = "", host='localhost', port=61613, reliable=FALSE, reconnectDelay=5)
        @client = Stomp::Connection.open(queue_user, queue_password, queue_host, queue_port, false)

      rescue Errno::ECONNREFUSED
        Chef::Log.error("Connection refused connecting to stomp queue at #{queue_host}:#{queue_port}, retry #{queue_retries}/#{@queue_retry_count}")
        sleep(@queue_retry_delay)
        retry if (queue_retries += 1) < @queue_retry_count
        raise Errno::ECONNREFUSED, "Connection refused connecting to stomp queue at #{queue_host}:#{queue_port}, giving up"
      rescue Timeout::Error
        Chef::Log.error("Timeout connecting to stomp queue at #{queue_host}:#{queue_port}, retry #{queue_retries}/#{@queue_retry_count}")
        sleep(@queue_retry_delay)
        retry if (queue_retries += 1) < @queue_retry_count
        raise Timeout::Error, "Timeout connecting to stomp queue at #{queue_host}:#{queue_port}, giving up"
      else
        queue_retries = 1 # reset the number of retries on success
      end

      def make_url(type, name)
        validate(
          {
            :queue_type => type.to_sym,
            :queue_name => name.to_sym,
          },
          {
            :queue_type => {
              :equal_to => [ :topic, :queue ],
            },
            :queue_name => {
              :kind_of => [ String, Symbol ],
            }
          }
        )
        if Chef::Config[:queue_prefix]
	        queue_prefix = Chef::Config[:queue_prefix]
          queue_url = "/#{type}/#{queue_prefix}/chef/#{name}"
	      else
	        queue_url = "/#{type}/chef/#{name}"
	      end
	      queue_url
      end

      def subscribe(type, name)
        queue_url = make_url(type, name)
        Chef::Log.debug("Subscribing to #{queue_url}")
        connect if @client == nil
        @client.subscribe(queue_url)
      end

      def send_msg(type, name, msg)
        queue_retries = 1 unless queue_retries
        validate(
          {
            :message => msg,
          },
          {
            :message => {
              :respond_to => :to_json
            }
          }
        )
        queue_url = make_url(type, name)
        json = msg.to_json
        connect if @client == nil
        Chef::Log.debug("Sending to #{queue_url}: #{json}")
        begin
          @client.send(queue_url, json)
        rescue Errno::EPIPE
          Chef::Log.debug("Lost connection to stomp queue, reconnecting")
          connect
          retry if (queue_retries += 1) < @queue_retry_count
          raise Errno::EPIPE, "Lost connection to stomp queue, giving up"
        else
          queue_retries = 1 # reset the number of retries on success
        end
      end

      def receive_msg
        connect if @client == nil
        begin
          raw_msg = @client.receive()
          Chef::Log.debug("Received Message from #{raw_msg.headers["destination"]} containing: #{raw_msg.body}")
        rescue
          Chef::Log.debug("Received nil message from stomp, retrying")
          retry
        end
        msg = JSON.parse(raw_msg.body)
        return msg, raw_msg.headers
      end

      def poll_msg
        connect if @client == nil
        raw_msg = @client.poll()
        if raw_msg
          msg = JSON.parse(raw_msg.body)
        else
          nil
        end
      end

      def disconnect
        raise ArgumentError, "You must call connect before you can disconnect!" unless @client
        @client.disconnect
      end
    end
  end
end
