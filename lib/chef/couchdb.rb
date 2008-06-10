require File.join(File.dirname(__FILE__), "mixin", "params_validate")
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
      unless @database_list.detect { |db| db == "chef" }
        response = @rest.put_rest("chef", Hash.new)
      end
      "chef"
    end
    
    def create_design_document(name, data)
      to_update = true
      begin
        old_doc = @rest.get_rest("chef/_design%2F#{name}")
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
        @rest.put_rest("chef/_design%2F#{name}", data)
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
      @rest.put_rest("chef/#{obj_type}_#{safe_name(name)}", object)
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
      @rest.get_rest("chef/#{obj_type}_#{safe_name(name)}")
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
        last_obj = @rest.get_rest("chef/#{obj_type}_#{safe_name(name)}")
        if last_obj.respond_to?(:couchdb_rev)
          rev = last_obj.couchdb_rev
        else
          rev = last_obj['_rev']
        end
      end
      @rest.delete_rest("chef/#{obj_type}_#{safe_name(name)}?rev=#{rev}")
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
        @rest.get_rest("chef/_view/#{view}/all")
      else
        @rest.get_rest("chef/_view/#{view}/all_id")
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
        @rest.get_rest("chef/#{obj_type}_#{safe_name(name)}")
        true
      rescue
        false
      end
    end
    
    private
      def safe_name(name)
        name.gsub(/\./, "_")
      end

  end
end