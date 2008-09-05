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

require File.join(File.dirname(__FILE__), "mixin", "check_helper")
require File.join(File.dirname(__FILE__), "mixin", "from_file")

# Chef::Config[:variable]
# @config = Chef::Config.new()
#
# Chef::ConfigFast << Chef::Config
#
# Chef::Config.from_file(foo)
# Chef::Resource.from_file (NoMethodError)
# Chef::Config[:cookbook_path]
# Chef::Config.cookbook_path
# Chef::Config.cookbook_path "one", "two"

class Chef
  class Config
    include Chef::Mixin::CheckHelper
  
    @configuration = {
      :cookbook_path => [ "/etc/chef/site-cookbook", "/etc/chef/cookbook" ],
      :node_path => "/etc/chef/node",
      :file_store_path => "/var/chef/store",
      :search_index_path => "/var/chef/search_index",
      :log_level => :info,
      :log_location => STDOUT,
      :merb_log_path => "/var/log/chef/merb.log",
      :openid_providers => nil,
      :ssl_verify_mode => :verify_none,
      :rest_timeout => 60,
      :couchdb_url => "http://localhost:5984",
      :registration_url => "http://localhost:4000",
      :openid_url => "http://localhost:4001",
      :template_url => "http://localhost:4000",
      :remotefile_url => "http://localhost:4000",
      :couchdb_database => "chef",
      :openid_store_path => "/var/chef/openid/db",
      :openid_cstore_path => "/var/chef/openid/cstore",
      :executable_path => ENV['PATH'] ? ENV['PATH'].split(File::PATH_SEPARATOR) : []
    }
    
    class << self
      include Chef::Mixin::FromFile
      
      def configure(&block)
        yield @configuration
      end
      
      def [](config_option)
        if @configuration.has_key?(config_option.to_sym)
          @configuration[config_option.to_sym]
        else
          raise ArgumentError, "Cannot find configuration option #{config_option.to_s}"
        end
      end
      
      def []=(config_option, value)
        @configuration[config_option.to_sym] = value
      end
      
      def has_key?(key)
        @configuration.has_key?(key.to_sym)
      end
    
      def method_missing(method_symbol, *args)
        if @configuration.has_key?(method_symbol)
          if args.length == 1
            @configuration[method_symbol] = args[0]
          elsif args.length > 1
            @configuration[method_symbol] = args
          end
          return @configuration[method_symbol]
        else
          raise ArgumentError, "Cannot find configuration option #{method_symbol.to_s}"
        end
      end
      
    end # class << self
  end
end