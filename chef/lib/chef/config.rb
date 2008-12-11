#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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
      :solo  => false,
      :cookbook_path => [ "/etc/chef/site-cookbook", "/etc/chef/cookbook" ],
      :validation_token => nil,
      :merb_root => "/var/chef/merb",
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
      :search_url => "http://localhost:4000",
      :couchdb_database => "chef",
      :openid_store_path => "/var/chef/openid/db",
      :openid_cstore_path => "/var/chef/openid/cstore",
      :file_cache_path => "/var/chef/cache",
      :node_name => nil,
      :executable_path => ENV['PATH'] ? ENV['PATH'].split(File::PATH_SEPARATOR) : [],
      :http_retry_delay => 5,
      :http_retry_count => 5,
      :queue_retry_delay => 5,
      :queue_retry_count => 5,
      :queue_retry_delay => 5,
      :queue_retry_count => 5,
      :queue_user => "",
      :queue_password => "",
      :queue_host => "localhost",
      :queue_port => 61613
    }
    
    class << self
      include Chef::Mixin::FromFile
      
      # Pass Chef::Config.configure() a block, and it will yield @configuration.
      #
      # === Parameters
      # <block>:: A block that takes @configure as it's argument
      def configure(&block)
        yield @configuration
      end
      
      # Get the value of a configuration option
      #
      # === Parameters
      # config_option<Symbol>:: The configuration option to return
      #
      # === Returns
      # value:: The value of the configuration option
      #
      # === Raises
      # <ArgumentError>:: If the configuration option does not exist
      def [](config_option)
        if @configuration.has_key?(config_option.to_sym)
          @configuration[config_option.to_sym]
        else
          raise ArgumentError, "Cannot find configuration option #{config_option.to_s}"
        end
      end
      
      # Set the value of a configuration option
      #
      # === Parameters
      # config_option<Symbol>:: The configuration option to set (within the [])
      # value:: The value for the configuration option
      #
      # === Returns
      # value:: The new value of the configuration option
      def []=(config_option, value)
        @configuration[config_option.to_sym] = value
      end
      
      # Check if Chef::Config has a configuration option.
      #
      # === Parameters
      # key<Symbol>:: The configuration option to check for
      #
      # === Returns
      # <True>:: If the configuration option exists
      # <False>:: If the configuration option does not exist
      def has_key?(key)
        @configuration.has_key?(key.to_sym)
      end
      
      # Allows for simple lookups and setting of configuration options via method calls
      # on Chef::Config.  If there any arguments to the method, they are used to set
      # the value of the configuration option.  Otherwise, it's a simple get operation.
      #
      # === Parameters
      # method_symbol<Symbol>:: The method called.  Must match a configuration option.
      # *args:: Any arguments passed to the method
      #
      # === Returns
      # value:: The value of the configuration option.
      #
      # === Raises
      # <ArgumentError>:: If the method_symbol does not match a configuration option.
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
