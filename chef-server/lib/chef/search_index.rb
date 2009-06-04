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
        raise Chef::Exceptions::SearchIndex, "Cannot transform argument to a Hash!" 
      end
      
      unless index_hash.has_key?(:index_name) || index_hash.has_key?("index_name")
        raise Chef::Exceptions::SearchIndex, "Cannot index without an index_name key: #{index_hash.inspect}"
      end
      
      unless index_hash.has_key?(:id) || index_hash.has_key?("id")
        raise Chef::Exceptions::SearchIndex, "Cannot index without an id key: #{index_hash.inspect}"
      end
     
      sanitized_hash = Hash.new
      index_hash.each do |k,v|
        sanitized_hash[k.to_sym] = v
      end
    
      sanitized_hash
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
