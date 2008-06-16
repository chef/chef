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

require 'rubygems'
require 'facter'

class Chef
  class Client
    
    attr_accessor :node, :registration, :safe_name
    
    def initialize()
      @node = nil
      @safe_name = nil
      @registration = nil
      @rest = Chef::REST.new(Chef::Config[:registration_url])
    end
    
    def run
      build_node
      register
      authenticate
      save_node
      converge
    end
    
    def build_node(node_name=nil)
      node_name ||= Facter["fqdn"].value ? Facter["fqdn"].value : Facter["hostname"].value
      @safe_name = node_name.gsub(/\./, '_')
      begin
        @node = @rest.get_rest("nodes/#{@safe_name}")
      rescue Net::HTTPServerException => e
        unless e.message =~ /^404/
          raise e
        end
      end
      unless @node
        @node ||= Chef::Node.new
        @node.name(node_name)
      end
      Facter.each do |field, value|
        @node[field] = value
      end
      @node
    end
    
    def register 
      @registration = nil
      begin
        @registration = @rest.get_rest("registrations/#{@safe_name}")
      rescue Net::HTTPServerException => e
        unless e.message =~ /^404/
          raise e
        end
      end
      
      if @registration
        reg = Chef::FileStore.load("registration", @safe_name)
        @secret = reg["secret"]
      else
        create_registration
      end
    end
    
    def create_registration
      @secret = random_password(40)
      Chef::FileStore.store("registration", @safe_name, { "secret" => @secret })
      @rest.post_rest("registrations", { :id => @safe_name, :password => @secret })
    end
    
    def authenticate
      response = @rest.post_rest('openid/consumer/start', { 
        "openid_identifier" => "#{Chef::Config[:openid_url]}/openid/server/node/#{@safe_name}",
        "submit" => "Verify"
      })
      @rest.post_rest(
        "#{Chef::Config[:openid_url]}#{response["action"]}",
        { "password" => @secret }
      )
    end
    
    def save_node
      @rest.put_rest("nodes/#{@safe_name}", @node)
    end
    
    def converge
      results = @rest.get_rest("nodes/#{@safe_name}/compile")
      results["collection"].resources.each do |r|
        r.collection = results["collection"]
      end
      cr = Chef::Runner.new(results["node"], results["collection"])
      cr.converge
    end
    
    protected
      def random_password(len)
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newpass = ""
        1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
        newpass
      end

  end
end