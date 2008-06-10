#
# Chef::Node::OpenIDRegistration
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


require 'rubygems'
require 'json'

class Chef
  class OpenIDRegistration
    
    attr_accessor :name, :salt, :validated, :password, :couchdb_rev
    
    include Chef::Mixin::ParamsValidate
    
    DESIGN_DOCUMENT = {
      "version" => 3,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
            function(doc) {
              if (doc.chef_type == "openid_registration") {
                emit(doc.name, doc);
              }
            }
          EOJS
        },
        "all_id" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "openid_registration") {
              emit(doc.name, doc.name);
            }
          }
          EOJS
        },
        "validated" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "openid_registration") {
              if (doc.validated == true) {
                emit(doc.name, doc);
              }
            }
          }
          EOJS
        },
        "unvalidated" => {
          "map" => <<-EOJS
          function(doc) {
            if (doc.chef_type == "openid_registration") {
              if (doc.validated == false) {
                emit(doc.name, doc);
              }
            }
          }
          EOJS
        },
      },
    }
    
    # Create a new Chef::OpenIDRegistration object.
    def initialize()
      @name = nil
      @salt = nil
      @password = nil
      @validated = false
      @couchdb_rev = nil
      @couchdb = Chef::CouchDB.new
    end
    
    def name=(n)
      @name = n.gsub(/\./, '_')
    end
    
    # Set the password for this object.
    def set_password(password) 
      @salt = generate_salt
      @password = encrypt_password(@salt, password)      
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
        'validated' => @validated,
        'chef_type' => 'openid_registration',
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
      me.validated = o["validated"]
      me.couchdb_rev = o["_rev"] if o.has_key?("_rev")
      me
    end
    
    # List all the Chef::OpenIDRegistration objects in the CouchDB.  If inflate is set to true, you will get
    # the full list of all registration objects.  Otherwise, you'll just get the IDs
    def self.list(inflate=false)
      rs = Chef::CouchDB.new.list("registrations", inflate)
      if inflate
        rs["rows"].collect { |r| r["value"] }
      else
        rs["rows"].collect { |r| r["key"] }
      end
    end
    
    # Load an OpenIDRegistration by name from CouchDB
    def self.load(name)
      Chef::CouchDB.new.load("openid_registration", name)
    end
    
    # Whether or not there is an OpenID Registration with this key.
    def self.has_key?(name)
      Chef::CouchDB.new.has_key?("openid_registration", name)
    end
    
    # Remove this node from the CouchDB
    def destroy
      @couchdb.delete("openid_registration", @name, @couchdb_rev)
    end
    
    # Save this node to the CouchDB
    def save
      results = @couchdb.store("openid_registration", @name, self)
      @couchdb_rev = results["rev"]
    end
    
    # Set up our CouchDB design document
    def self.create_design_document
      Chef::CouchDB.new.create_design_document("registrations", DESIGN_DOCUMENT)
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