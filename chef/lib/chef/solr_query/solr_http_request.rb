#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009-2011 Opscode, Inc.
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

require 'net/http'
require 'uri'
require 'chef/json_compat'
require 'chef/config'

class Chef
  class SolrQuery
    class SolrHTTPRequest
      CLASS_FOR_METHOD = {:GET => Net::HTTP::Get, :POST => Net::HTTP::Post}

      TEXT_XML = {"Content-Type" => "text/xml"}

      def self.solr_url=(solr_url)
        @solr_url = solr_url
        @http_client = nil
        @url_prefix = nil
      end

      def self.solr_url
        @solr_url || Chef::Config[:solr_url]
      end

      def self.http_client
        @http_client ||= begin
          uri = URI.parse(solr_url)
          Net::HTTP.new(uri.host, uri.port)
        end
      end

      def self.url_prefix
        @url_prefix ||= begin
          uri = URI.parse(solr_url)
          if uri.path == ""
            "/solr"
          else
            uri.path.gsub(%r{/$}, '')
          end
        end
      end

      def self.select(params={})
        url = "#{url_prefix}/select?#{url_join(params)}"
        Chef::Log.debug("Sending #{url} to Solr")
        request = new(:GET, url)
        json_response = request.run("Search Query to Solr '#{solr_url}#{url}'")
        Chef::JSONCompat.from_json(json_response)
      end

      def self.update(doc)
        url = "#{url_prefix}/update"
        Chef::Log.debug("POSTing document to SOLR:\n#{doc}")
        request = new(:POST, url, TEXT_XML) { |req| req.body = doc.to_s }
        request.run("POST to Solr '#{solr_url}#{url}', data: #{doc}")
      end

      def self.url_join(params_hash={})
        params = params_hash.inject("") do |param_str, params|
          param_str << "#{params[0]}=#{escape(params[1])}&"
        end
        params.chop! # trailing &
        params
      end

      def self.escape(s)
        s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
          '%'+$1.unpack('H2'*$1.size).join('%').upcase
        }.tr(' ', '+')
      end

      def initialize(method, url, headers=nil)
        args = headers ? [url, headers] : url
        @request = CLASS_FOR_METHOD[method].new(*args)
        yield @request if block_given?
      end

      def http_client
        self.class.http_client
      end

      def solr_url
        self.class.solr_url
      end

      def run(description="HTTP Request to Solr")
        response = http_client.request(@request)
        request_failed!(response, description) unless response.kind_of?(Net::HTTPSuccess)
        response.body
      rescue NoMethodError => e
        # http://redmine.ruby-lang.org/issues/show/2708
        # http://redmine.ruby-lang.org/issues/show/2758
        if e.to_s =~ /#{Regexp.escape(%q|undefined method 'closed?' for nil:NilClass|)}/
          Chef::Log.fatal("#{description} failed.  Chef::Exceptions::SolrConnectionError exception: Errno::ECONNREFUSED (net/http undefined method closed?) attempting to contact #{solr_url}")
          Chef::Log.debug("Rescued error in http connect, treating it as Errno::ECONNREFUSED to hide bug in net/http")
          Chef::Log.debug(e.backtrace.join("\n"))
          raise Chef::Exceptions::SolrConnectionError, "Errno::ECONNREFUSED: Connection refused attempting to contact #{solr_url}"
        else
          raise
        end
      end

      def request_failed!(response, description='HTTP call')
        Chef::Log.fatal("#{description} failed (#{response.class} #{response.code} #{response.message})")
        response.error!
      rescue Timeout::Error, Errno::EINVAL, EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::ETIMEDOUT => e
        Chef::Log.debug(e.backtrace.join("\n"))
        raise Chef::Exceptions::SolrConnectionError, "#{e.class.name}: #{e.to_s}"
      end

    end
  end
end
