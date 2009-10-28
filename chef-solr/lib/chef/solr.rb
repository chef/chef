#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'rubygems'
require 'chef/log'
require 'chef/config'
require 'chef/couchdb'
require 'chef/role'
require 'chef/node'
require 'chef/data_bag'
require 'chef/data_bag_item'
require 'net/http'
require 'libxml'
require 'uri'

class Chef
  class Solr

    attr_accessor :solr_url, :http

    def initialize(solr_url=Chef::Config[:solr_url])
      @solr_url = solr_url
      uri = URI.parse(@solr_url)
      @http = Net::HTTP.new(uri.host, uri.port)
    end

    def solr_select(database, type, options={})
      options[:wt] = :ruby
      options[:indent] = "off"
      if type.kind_of?(Array)
        options[:fq] = "+X_CHEF_database_CHEF_X:#{database} +X_CHEF_type_CHEF_X:#{type[0]} +data_bag:#{type[1]}"
      else
        options[:fq] = "+X_CHEF_database_CHEF_X:#{database} +X_CHEF_type_CHEF_X:#{type}"
      end
      select_url = "/solr/select?#{to_params(options)}"
      Chef::Log.debug("Sending #{select_url} to Solr")
      req = Net::HTTP::Get.new(select_url)
      res = @http.request(req)
      unless res.kind_of?(Net::HTTPSuccess)
        res.error!
      end
      eval(res.body)
    end

    def post_to_solr(doc)
      req = Net::HTTP::Post.new("/solr/update", "Content-Type" => "text/xml")
      req.body = doc.to_s
      res = @http.request(req)
      unless res.kind_of?(Net::HTTPSuccess)
        res.error!
      end
      res
    end

    def solr_add(data)
      data = [data] unless data.is_a?(Array)

      xml_document = LibXML::XML::Document.new
      xml_add = LibXML::XML::Node.new("add")
      data.each do |doc|
        xml_doc = LibXML::XML::Node.new("doc")
        doc.each do |field, values|
          values = [values] unless values.kind_of?(Array)
          values.each do |v|
            xml_field = LibXML::XML::Node.new("field")
            xml_field["name"] = field
            xml_field.content = v.to_s
            xml_doc << xml_field
          end
        end
        xml_add << xml_doc
      end
      xml_document.root = xml_add
      post_to_solr(xml_document.to_s(:indent => false))
    end

    def solr_commit(opts={})
      post_to_solr(generate_single_element("commit", opts))
    end
    
    def solr_optimize(opts={})
      post_to_solr(generate_single_element("optimize", opts))
    end
    
    def solr_rollback
      post_to_solr(generate_single_element("rollback"))
    end
    
    def solr_delete_by_id(ids)
      post_to_solr(generate_delete_document("id", ids))
    end
    
    def solr_delete_by_query(queries)
      post_to_solr(generate_delete_document("query", queries))
    end

    def rebuild_index(url=Chef::Config[:couchdb_url], db=Chef::Config[:couchdb_database])
      solr_delete_by_query("X_CHEF_database_CHEF_X:#{db}")
      couchdb = Chef::CouchDB.new(url, db)
      Chef::Node.cdb_list(true).each { |i| i.cdb_save }  
      Chef::Role.cdb_list(true).each { |i| i.cdb_save }  
      Chef::DataBag.cdb_list(true).each { |i| i.cdb_save; i.list(true).each { |x| x.cdb_save } }  
      true
    end

    private 

      def generate_single_element(elem, opts={})
        xml_document = LibXML::XML::Document.new
        xml_elem = LibXML::XML::Node.new(elem)
        opts.each { |k,v| xml_elem[k.to_s] = v.to_s }
        xml_document.root = xml_elem
        xml_document.to_s(:indent => false)
      end

      def generate_delete_document(type, list)
        list = [list] unless list.is_a?(Array)
        xml_document = LibXML::XML::Document.new
        xml_delete = LibXML::XML::Node.new("delete")
        xml_document.root = xml_delete
        list.each do |id|
          xml_id = LibXML::XML::Node.new(type)
          xml_id.content = id.to_s
          xml_delete << xml_id
        end
        xml_document.to_s(:indent => false)
      end

      # Thanks to Merb!
      def to_params(params_hash)
        params = ''
        stack = []

        params_hash.each do |k, v|
          if v.is_a?(Hash)
            stack << [k,v]
          else
            params << "#{k}=#{escape(v)}&"
          end
        end

        stack.each do |parent, hash|
          hash.each do |k, v|
            if v.is_a?(Hash)
              stack << ["#{parent}[#{k}]", escape(v)]
            else
              params << "#{parent}[#{k}]=#{escape(v)}&"
            end
          end
        end

        params.chop! # trailing &
        params
      end

      # escapes a query key/value for http
      # Thanks to RSolr!
      def escape(s)
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+') 
      end

  end
end

