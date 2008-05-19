#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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