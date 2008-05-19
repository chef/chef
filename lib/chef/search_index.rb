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
require 'ferret'

class Chef
  class SearchIndex
    
    def initialize
      @index = Ferret::Index::Index.new(
        :path => Chef::Config[:search_index_path],
        :key => [ :id ]
      )
    end
    
    def add(to_index)
      type = check_type(to_index)
      result = self.send("_prepare_#{type}", to_index)
      Chef::Log.debug("Indexing #{type} with #{result.inspect}")
      @index.add_document(result)
    end
    
    def delete(index_obj)
      type = check_type(index_obj)
      to_index = self.send("_prepare_#{type}", index_obj)
      Chef::Log.debug("Removing #{type} with #{to_index.inspect}")
      @index.delete(:id => "#{to_index[:id]}")
    end
    
    private
    
      def check_type(to_check)
        type = nil
        case to_check
        when Chef::Node
          type = "node"
        end
      end
    
      def _prepare_node(node)
        result = Hash.new
        result[:id] = "node-#{node.name}"
        result[:type] = "node"
        result[:name] = node.name
        node.each_attribute do |k,v|
          result[k.to_sym] = v
        end
        result[:recipe] = node.recipes
        result
      end
  end
end