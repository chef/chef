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

require 'chef/mixin/params_validate'
require 'chef/config'
require 'chef/rest'
require 'chef/log'
require 'digest/sha2'
require 'json'

class Chef
  class CouchDB
    include Chef::Mixin::ParamsValidate
    
    def initialize(url=nil)
      url ||= Chef::Config[:couchdb_url]
      @rest = Chef::REST.new(url)
    end
    
    def create_db
      @database_list = @rest.get_rest("_all_dbs")
      unless @database_list.detect { |db| db == Chef::Config[:couchdb_database] }
        response = @rest.put_rest(Chef::Config[:couchdb_database], Hash.new)
      end
      Chef::Config[:couchdb_database]
    end
    
    def create_design_document(name, data)
      create_db
      to_update = true
      begin
        old_doc = @rest.get_rest("#{Chef::Config[:couchdb_database]}/_design%2F#{name}")
        if data["version"] != old_doc["version"]
          data["_rev"] = old_doc["_rev"]
          Chef::Log.debug("Updating #{name} views")
        else
          to_update = false
        end
      rescue
        Chef::Log.debug("Creating #{name} views for the first time")
      end
      if to_update
        @rest.put_rest("#{Chef::Config[:couchdb_database]}/_design%2F#{name}", data)
      end
      true
    end

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
      @rest.put_rest("#{Chef::Config[:couchdb_database]}/#{obj_type}_#{safe_name(name)}", object)
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
      @rest.get_rest("#{Chef::Config[:couchdb_database]}/#{obj_type}_#{safe_name(name)}")
    end
  
    def delete(obj_type, name, rev=nil)
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
      unless rev
        last_obj = @rest.get_rest("#{Chef::Config[:couchdb_database]}/#{obj_type}_#{safe_name(name)}")
        if last_obj.respond_to?(:couchdb_rev)
          rev = last_obj.couchdb_rev
        else
          rev = last_obj['_rev']
        end
      end
      @rest.delete_rest("#{Chef::Config[:couchdb_database]}/#{obj_type}_#{safe_name(name)}?rev=#{rev}")
    end
  
    def list(view, inflate=false)
      validate(
        { 
          :view => view,
        },
        {
          :view => { :kind_of => String }
        }
      )
      if inflate
        @rest.get_rest(view_uri(view, "all"))
      else
        @rest.get_rest(view_uri(view, "all_id"))
      end
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
      begin
        @rest.get_rest("#{Chef::Config[:couchdb_database]}/#{obj_type}_#{safe_name(name)}")
        true
      rescue
        false
      end
    end
    
    def view_uri(design, view)
      Chef::Config[:couchdb_version] ||= @rest.run_request(:GET, URI.parse(@rest.url + "/"), false, 10, false)["version"].gsub(/-.+/,"").to_f
      case Chef::Config[:couchdb_version]
      when 0.9
        "#{Chef::Config[:couchdb_database]}/_design/#{design}/_view/#{view}"
      when 0.8
        "#{Chef::Config[:couchdb_database]}/_view/#{design}/#{view}"
      end
    end
    
    private
    
    def safe_name(name)
      name.gsub(/\./, "_")
    end
      
  end
end
