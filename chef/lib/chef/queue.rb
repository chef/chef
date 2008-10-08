#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "mixin", "params_validate")

class Chef
  class Queue
    require 'stomp'
    
    @client = nil
    
    class << self
      include Chef::Mixin::ParamsValidate
      
      def connect
        @client = Stomp::Connection.open(
          Chef::Config.has_key?(:queue_user) ? Chef::Config[:queue_user] : "", 
          Chef::Config.has_key?(:queue_password) ? Chef::Config[:queue_password] : "",
          Chef::Config.has_key?(:queue_host) ? Chef::Config[:queue_host] : "localhost",
          Chef::Config.has_key?(:queue_port) ? Chef::Config[:queue_port] : 61613,
          false
        )
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
        queue_url = "/#{type}/chef/#{name}"
      end

      def subscribe(type, name)
        queue_url = make_url(type, name)
        Chef::Log.debug("Subscribing to #{queue_url}")
        connect if @client == nil
        @client.subscribe(queue_url)
      end

      def send_msg(type, name, msg)
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
        @client.send(queue_url, json)
      end

      def receive_msg
        connect if @client == nil
        raw_msg = @client.receive()
        Chef::Log.debug("Received Message from #{raw_msg.headers["destination"]} containing: #{raw_msg.body}")
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