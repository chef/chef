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