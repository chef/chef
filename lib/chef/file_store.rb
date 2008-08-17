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

require File.join(File.dirname(__FILE__), "mixin", "params_validate")
require 'digest/sha2'
require 'json'

class Chef
  class FileStore
    class << self
      include Chef::Mixin::ParamsValidate
  
      def store(obj_type, name, object)
        validate(
          {
            :obj_type => obj_type,
            :name => name,
            :object => object,
          },
          {
            :object => { :respond_to => :to_json },
          }
        )
      
        store_path = create_store_path(obj_type, name)
        io = File.open(store_path, "w")
        io.puts object.to_json
        io.close
      end
    
      def load(obj_type, name)
        validate(
          {
            :obj_type => obj_type,
            :name => name,
          },
          {
            :obj_type => { :kind_of => String },
            :name => { :kind_of => String },
          }
        )
        store_path = create_store_path(obj_type, name)
        raise "Cannot find #{store_path} for #{obj_type} #{name}!" unless File.exists?(store_path)
        object = JSON.parse(IO.read(store_path))
      end
      
      def delete(obj_type, name)
        validate(
          {
            :obj_type => obj_type,
            :name => name,
          },
          {
            :obj_type => { :kind_of => String },
            :name => { :kind_of => String },
          }
        )
        store_path = create_store_path(obj_type, name)
        if File.exists?(store_path)
          File.unlink(store_path)
        end
      end
      
      def list(obj_type, inflate=false)
        validate(
          { 
            :obj_type => obj_type,
          },
          {
            :obj_type => { :kind_of => String }
          }
        )
        keys = Array.new
        Dir[File.join(Chef::Config[:file_store_path], obj_type, '**', '*')].each do |f|
          if File.file?(f)
            if inflate
              keys << load(obj_type, File.basename(f))
            else
              keys << File.basename(f)
            end
          end
        end
        keys
      end
      
      def has_key?(obj_type, name)
        validate(
          {
            :obj_type => obj_type,
            :name => name,
          },
          {
            :obj_type => { :kind_of => String },
            :name => { :kind_of => String },
          }
        )
        Dir[File.join(Chef::Config[:file_store_path], obj_type, '**', '*')].each do |f|
          if File.file?(f)
            return true if File.basename(f) == name
          end
        end
        return false
      end
      
      def create_store_path(obj_type, key)
        shadigest = Digest::SHA2.hexdigest("#{obj_type}#{key}")
        
        file_path = [
          Chef::Config[:file_store_path],
          obj_type,
          shadigest[0,1],
          shadigest[1,3]
        ]
        file_path.each_index do |i|
          create_path = File.join(file_path[0, i + 1])
          Dir.mkdir(create_path) unless File.directory?(create_path) 
        end
        file_path << key
        File.join(*file_path)
      end
  
    end
  end
end