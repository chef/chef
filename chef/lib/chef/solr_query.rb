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

require 'chef/mixin/xml_escape'
require 'chef/log'
require 'chef/config'
require 'chef/couchdb'
require 'net/http'
require 'libxml'
require 'uri'

class Chef
  class SolrQuery

    include Chef::Mixin::XMLEscape

    attr_accessor :solr_url, :http

    ID_KEY = "X_CHEF_id_CHEF_X"
    
    # Create a new Query object - takes the solr_url and optional
    # Chef::CouchDB object to inflate objects into.
    def initialize(solr_url=Chef::Config[:solr_url], couchdb = nil)
      @solr_url = solr_url
      uri = URI.parse(@solr_url)
      @http = Net::HTTP.new(uri.host, uri.port)

      if couchdb.nil?
        @database = Chef::Config[:couchdb_database]
        @couchdb = Chef::CouchDB.new(nil, Chef::Config[:couchdb_database])
      else
        unless couchdb.kind_of?(Chef::CouchDB)
          Chef::Log.warn("Passing the database name to Chef::Solr::Query initialization is deprecated. Please pass in the Chef::CouchDB object instead.")
          @database = couchdb
          @couchdb = Chef::CouchDB.new(nil, couchdb)
        else
          @database = couchdb.couchdb_database
          @couchdb = couchdb
        end
      end 
    end

    # A raw query against CouchDB - takes the type of object to find, and raw
    # Solr options.
    #
    # You'll wind up having to page things yourself.
    def raw(type, options={})
      qtype = case options[:type].to_s
              when "role","node","client","environment"
                options[:type]
              else
                [ "data_bag_item", options[:type] ]
              end
      results = solr_select(@database, qtype, options)
      Chef::Log.debug("Searching #{@database} #{qtype.inspect} for #{options.inspect} with results:\n#{results.inspect}") 
      objects = if results["response"]["docs"].length > 0
                  bulk_objects = @couchdb.bulk_get( results["response"]["docs"].collect { |d| d[ID_KEY] } )
                  Chef::Log.debug("bulk get of objects: #{bulk_objects.inspect}")
                  bulk_objects
                else
                  []
                end
      [ objects, results["response"]["start"], results["response"]["numFound"], results["responseHeader"] ] 
    end

    # Search Solr for objects of a given type, for a given query. If
    # you give it a block, it will handle the paging for you
    # dynamically.
    def search(params, &block)
      defaults = Mash.new({:q => "*:*", :start => 0, :rows => 1000})
      options = defaults.merge(params)
      options[:sort] = "#{ID_KEY} asc" if options[:sort].nil? || options[:sort].empty?
      options[:q] = transform_search_query(options[:q])
      objects, start, total, response_header = raw(options)
      if block
        objects.each { |o| block.call(o) }
        unless (start + objects.length) >= total
          nstart = start + rows
          search(type, query, sort, nstart, rows, &block)
        end
        true
      else
        [ objects, start, total ]
      end
    end

    # Constants used for search query transformation
    FLD_SEP = "\001"
    SPC_SEP = "\002"
    QUO_SEP = "\003"
    QUO_KEY = "\004"

    def transform_search_query(q)
      return q if q == "*:*"

      # handled escaped quotes
      q = q.gsub(/\\"/, QUO_SEP)

      # handle quoted strings
      i = 1
      quotes = {}
      q = q.gsub(/([^ \\+()]+):"([^"]+)"/) do |m|
        key = QUO_KEY + i.to_s
        quotes[key] = "content#{FLD_SEP}\"#{$1}__=__#{$2}\""
        i += 1
        key
      end

      # a:[* TO *] => a*
      q = q.gsub(/\[\*[+ ]TO[+ ]\*\]/, '*')

      keyp = '[^ \\+()]+'
      lbrak = '[\[{]'
      rbrak = '[\]}]'

      # a:[blah TO zah] =>
      # content\001[a__=__blah\002TO\002a__=__zah]
      # includes the cases a:[* TO zah] and a:[blah TO *], but not
      # [* TO *]; that is caught above
      q = q.gsub(/(#{keyp}):(#{lbrak})([^\]}]+)[+ ]TO[+ ]([^\]}]+)(#{rbrak})/) do |m|
        if $3 == "*"
          "content#{FLD_SEP}#{$2}#{$1}__=__#{SPC_SEP}TO#{SPC_SEP}#{$1}__=__#{$4}#{$5}"
        elsif $4 == "*"
          "content#{FLD_SEP}#{$2}#{$1}__=__#{$3}#{SPC_SEP}TO#{SPC_SEP}#{$1}__=__\\ufff0#{$5}"
        else
          "content#{FLD_SEP}#{$2}#{$1}__=__#{$3}#{SPC_SEP}TO#{SPC_SEP}#{$1}__=__#{$4}#{$5}"
        end
      end

      # foo:bar => content:foo__=__bar
      q = q.gsub(/([^ \\+()]+):([^ +]+)/) { |m| "content:#{$1}__=__#{$2}" }

      # /002 => ' '
      q = q.gsub(/#{SPC_SEP}/, ' ')

      # replace quoted query chunks
      quotes.keys.each do |key|
        q = q.gsub(key, quotes[key])
      end

      # replace escaped quotes
      q = q.gsub(QUO_SEP, '\"')

      # /001 => ':'
      q = q.gsub(/#{FLD_SEP}/, ':')
      q
    end


    def solr_select(database, type, options={})
      options[:wt] = :ruby
      options[:indent] = "off"
      options[:fq] = if type.kind_of?(Array)
                       "+X_CHEF_database_CHEF_X:#{database} +X_CHEF_type_CHEF_X:#{type[0]} +data_bag:#{type[1]}"
                     else
                       "+X_CHEF_database_CHEF_X:#{database} +X_CHEF_type_CHEF_X:#{type}"
                     end
      select_url = "/solr/select?#{to_params(options)}"
      Chef::Log.debug("Sending #{select_url} to Solr")
      req = Net::HTTP::Get.new(select_url)

      description = "Search Query to Solr '#{solr_url}#{select_url}'"

      res = http_request_handler(req, description)
      Chef::Log.debug("Parsing Solr result set:\n#{res.body}")
      eval(res.body)
    end

    def post_to_solr(doc)
      Chef::Log.debug("POSTing document to SOLR:\n#{doc}")
      req = Net::HTTP::Post.new("/solr/update", "Content-Type" => "text/xml")
      req.body = doc.to_s

      description = "POST to Solr '#{solr_url}'"

      http_request_handler(req, description)
    end

    START_XML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<add><doc>"
    END_XML   = "</doc></add>\n"
    FIELD_ATTR = '<field name="'
    FIELD_ATTR_END = '">'
    CLOSE_FIELD = "</field>"

    def solr_add(data)
      Chef::Log.debug("adding to SOLR: #{data.inspect}")

      xml = ""
      xml << START_XML

      data.each do |field, values|
        values.each do |v|
          xml << FIELD_ATTR
          xml << field
          xml << FIELD_ATTR_END
          xml <<  xml_escape(v)
          xml << CLOSE_FIELD
        end
      end
      xml << END_XML
      xml

      post_to_solr(xml)
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
      solr_commit

      results = {}
      [Chef::ApiClient, Chef::Node, Chef::Role].each do |klass|
        results[klass.name] = reindex_all(klass) ? "success" : "failed"
      end
      databags = Chef::DataBag.cdb_list(true)
      Chef::Log.info("Reloading #{databags.size.to_s} #{Chef::DataBag} objects into the indexer")
      databags.each { |i| i.add_to_index; i.list(true).each { |x| x.add_to_index } }
      results[Chef::DataBag.name] = "success"
      results
    end

    private

    def reindex_all(klass, metadata={})
      begin
        items = klass.cdb_list(true)
        Chef::Log.info("Reloading #{items.size.to_s} #{klass.name} objects into the indexer")
        items.each { |i| i.add_to_index }
      rescue Net::HTTPServerException => e
        # 404s are okay, there might not be any of that kind of object...
        if e.message =~ /Not Found/
          Chef::Log.warn("Could not load #{klass.name} objects from couch for re-indexing (this is ok if you don't have any of these)")
          return false
        else
          raise e
        end
      rescue Exception => e
        Chef::Log.fatal("Chef encountered an error while attempting to load #{klass.name} objects back into the index")
        raise e
      end
      true
    end

    def generate_single_element(elem, opts={})
      xml_document = LibXML::XML::Document.new
      xml_elem = LibXML::XML::Node.new(elem)
      opts.each { |k,v| xml_elem[k.to_s] = xml_escape(v.to_s) }
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
    
    # handles multiple net/http exceptions and no method closed? bug
    def http_request_handler(req, description='HTTP call')
      res = @http.request(req)
      unless res.kind_of?(Net::HTTPSuccess)
        Chef::Log.fatal("#{description} failed (#{res.class} #{res.code} #{res.message})")
        res.error!
      end
      res
    rescue Timeout::Error, Errno::EINVAL, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT, NoMethodError => e
      # http://redmine.ruby-lang.org/issues/show/2708
      # http://redmine.ruby-lang.org/issues/show/2758
      if e.to_s =~ /#{Regexp.escape(%q|undefined method 'closed?' for nil:NilClass|)}/
        Chef::Log.fatal("#{description} failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED (net/http undefined method closed?) attempting to contact #{@solr_url}")
        Chef::Log.debug("rescued error in http connect, treating it as Errno::ECONNREFUSED to hide bug in net/http")
        Chef::Log.debug(e.backtrace.join("\n"))
        raise Chef::Exceptions::SolrConnectionError, "Errno::ECONNREFUSED: Connection refused attempting to contact #{@solr_url}"
      end

      Chef::Log.fatal("#{description} failed.  Chef::Exceptions::SolrConnectionError exception: #{e.class.name}: #{e.to_s} attempting to contact #{@solr_url}")
      Chef::Log.debug(e.backtrace.join("\n"))

      raise Chef::Exceptions::SolrConnectionError, "#{e.class.name}: #{e.to_s}"
    end


  end
end
