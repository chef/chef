#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuo@opscode.com>)
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

require 'chef/config'
require 'chef/mixin/params_validate'
require 'chef/couchdb'
require 'digest/sha1'
require 'rubygems'
require 'json'

class Chef
  class WebUIUser
    
    attr_accessor :name, :salt, :validated, :password, :couchdb_rev, :admin, :openid
    
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 3,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
            function(doc) {
              if (doc.chef_type == "webui_user") {
                emit(doc.name, doc);
              }
            }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "webui_user") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        },
      },
    }
    
    # Create a new Chef::WebUIUser object.
    def initialize()
      @name = nil
      @salt = nil
      @password = nil
      @admin = false
      @openid = nil
      @couchdb_rev = nil
      @couchdb = Chef::CouchDB.new
    end
    
    def name=(n)
      @name = n.gsub(/\./, '_')
    end
    
    # Set the password for this object.
    def set_password(password) 
      raise ArgumentError, "Password must be a minimum of 6 characters" if password.length < 6
      @salt = generate_salt
      @password = encrypt_password(@salt, password)      
    end
    
    def set_openid(given_openid)
      @openid = given_openid
    end 
    
    def verify_password(given_password)
      encrypt_password(@salt, given_password) == @password ? true : false
    end 
    
    # Serialize this object as a hash 
    def to_json(*a)
      attributes = Hash.new
      recipes = Array.new
      result = {
        'name' => @name,
        'json_class' => self.class.name,
        'salt' => @salt,
        'password' => @password,
        'openid' => @openid,
        'admin' => @admin,
        'chef_type' => 'webui_user',
      }
      result["_rev"] = @couchdb_rev if @couchdb_rev
      result.to_json(*a)
    end
    
    # Create a Chef::Node from JSON
    def self.json_create(o)
      me = new
      me.name = o["name"]
      me.salt = o["salt"]
      me.password = o["password"]
      me.openid = o["openid"]
      me.admin = o["admin"]
      me.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      me
    end
    
    # List all the Chef::WebUIUser objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all registration objects.  Otherwise, you'll just get the IDs
    def self.list(inflate=false)
      rs = Chef::CouchDB.new.list("users", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end
    
    # Load an WebUIUser by name from CouchDB
    def self.load(name)
      Chef::CouchDB.new.load("webui_user", name)
    end
    
    # Whether or not there is an WebUIUser with this key.
    def self.has_key?(name)
      Chef::CouchDB.new.has_key?("webui_user", name)
    end
    
    # Remove this WebUIUser from the CouchDB
    def destroy
      @couchdb.delete("webui_user", @name, @couchdb_rev)
    end
    
    # Save this WebUIUser to the CouchDB
    def save
      results = @couchdb.store("webui_user", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      Chef::CouchDB.new.create_design_document("users", DESIGN_DOCUMENT)
    end
    
    protected
    
      def generate_salt
        salt = Time.now.to_s
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        1.upto(30) { |i| salt << chars[rand(chars.size-1)] }
        salt
      end
    
      def encrypt_password(salt, password)
        Digest::SHA1.hexdigest("--#{salt}--#{password}--")
      end
    
  end
end
