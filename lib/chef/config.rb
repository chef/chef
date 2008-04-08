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
      :log_level => :info,
      :log_location => STDOUT
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