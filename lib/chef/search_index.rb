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
    
    attr_reader :index
    
    def initialize
      @index = Ferret::Index::Index.new(
        :path => Chef::Config[:search_index_path],
        :key => [ :id ]
      )
    end
    
    def add(new_object)
      index_hash = create_index_object(new_object)
      Chef::Log.debug("Indexing #{index_hash[:index_name]} with #{index_hash.inspect}")
      @index.add_document(index_hash)
    end
    
    def create_index_object(new_object)
      index_hash = nil
      
      if new_object.respond_to?(:to_index)
        index_hash = new_object.to_index
      elsif new_object.kind_of?(Hash)
        index_hash = new_object
      else
        raise Chef::Exception::SearchIndex, "Cannot transform argument to a Hash!" 
      end
      
      unless index_hash.has_key?(:index_name) || index_hash.has_key?("index_name")
        raise Chef::Exception::SearchIndex, "Cannot index without an index_name key: #{index_hash.inspect}"
      end
      
      unless index_hash.has_key?(:id) || index_hash.has_key?("id")
        raise Chef::Exception::SearchIndex, "Cannot index without an id key: #{index_hash.inspect}"
      end
      
      index_hash.each do |k,v|
        unless k.kind_of?(Symbol)
          index_hash[k.to_sym] = v
          index_hash.delete(k)
        end
      end
      
      index_hash
    end
        
    def delete(index_obj)
      to_delete = create_index_object(index_obj)
      Chef::Log.debug("Removing #{to_delete.inspect} from the #{to_delete[:index_name]} index")
      @index.delete(to_delete[:id])
    end
    
    def commit
      @index.commit
    end
    
  end
end
