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
  class Search
    
    attr_reader :index
    
    def initialize
      @index = Ferret::Index::Index.new(:path => Chef::Config[:search_index_path])
    end
    
    def search(type, query, &block)
      search_query = build_search_query(type, query)
      start_time = Time.now
      result = Array.new
      
      if Kernel.block_given?
        result = @index.search_each(search_query, :limit => :all) do |id, score|
          block.call(build_hash(@index.doc(id)))
        end
      else
        @index.search_each(search_query, :limit => :all) do |id, score|          
          result << build_hash(@index.doc(id))
        end
      end
      Chef::Log.debug("Search #{search_query} complete in #{Time.now - start_time} seconds")
      result
    end
    
    def list_indexes
      indexes = Hash.new
      @index.search_each("index_name:*", :limit => :all) do |id, score|
        indexes[@index.doc(id)["index_name"]] = true
      end
      indexes.keys
    end
    
    def has_index?(index)
      list_indexes.detect { |i| i == index }
    end
    
    private
      def build_search_query(type, query)
        "index_name:#{type} AND (#{query})"
      end
    
      def build_hash(doc)
        result = Hash.new
        doc.fields.each do |f|
          result[f] = doc[f]
        end
        result
      end
  end
end