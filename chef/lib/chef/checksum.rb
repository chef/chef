#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/log'
require 'uuidtools'

class Chef
  # == Chef::Checksum
  # Checksum for an individual file; e.g., used for sandbox/cookbook uploading
  # to track which files the system already manages.
  class Checksum
    attr_accessor :checksum, :create_time
    attr_accessor :couchdb_id, :couchdb_rev
    
    DESIGN_DOCUMENT = {
      "version" => 1,
      "language" => "javascript",
      "views" => {
        "all" => {
          "map" => <<-EOJS
          function(doc) { 
            if (doc.chef_type == "checksum") {
              emit(doc.checksum, doc);
            }
          }
          EOJS
        },
      }
    }
    
    # Creates a new Chef::Checksum object.
    # === Arguments
    # checksum::: the MD5 content hash of the file
    # couchdb::: An instance of Chef::CouchDB
    #
    # === Returns
    # object<Chef::Checksum>:: Duh. :)
    def initialize(checksum=nil, couchdb=nil)
      @create_time = Time.now.iso8601
      @checksum = checksum
    end
    
    def to_json(*a)
      result = {
        :checksum => checksum,
        :create_time => create_time,
        :json_class => self.class.name,
        :chef_type => 'checksum',

        # For Chef::CouchDB (id_to_name, name_to_id)
        :name => checksum
      }
      result.to_json(*a)
    end

    def self.json_create(o)
      checksum = new(o['checksum'])
      checksum.create_time = o['create_time']

      if o.has_key?('_rev')
        checksum.couchdb_rev = o["_rev"]
        o.delete("_rev")
      end
      if o.has_key?("_id")
        checksum.couchdb_id = o["_id"]
        o.delete("_id")
      end
      checksum
    end

    ##
    # Couchdb
    ##

    def self.create_design_document(couchdb=nil)
      (couchdb || Chef::CouchDB.new).create_design_document("checksums", DESIGN_DOCUMENT)
    end
    
    def self.cdb_list(inflate=false, couchdb=nil)
      rs = (couchdb || Chef::CouchDB.new).list("checksums", inflate)
      lookup = (inflate ? "value" : "key")
      rs["rows"].collect { |r| r[lookup] }        
    end
    
    def self.cdb_all_checksums(couchdb = nil)
      rs = (couchdb || Chef::CouchDB.new).list("checksums", true)
      rs["rows"].inject({}) { |hash_result, r| hash_result[r['key']] = 1; hash_result }
    end

    def self.cdb_load(checksum, couchdb=nil)
      # Probably want to look for a view here at some point
      (couchdb || Chef::CouchDB.new).load("checksum", checksum)
    end

    def cdb_destroy(couchdb=nil)
      (couchdb || Chef::CouchDB.new).delete("checksum", checksum, @couchdb_rev)
    end

    def cdb_save(couchdb=nil)
      @couchdb_rev = (couchdb || Chef::CouchDB.new).store("checksum", checksum, self)["rev"]
    end

  end
end
