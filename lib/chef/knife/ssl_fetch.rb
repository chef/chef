#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/knife'
require 'chef/config'

class Chef
  class Knife
    class SslFetch < Chef::Knife

      deps do
        require 'pp'
        require 'socket'
        require 'uri'
        require 'openssl'
      end

      banner "knife ssl fetch [URL] (options)"

      def initialize(*args)
        super
        @uri = nil
      end

      def uri
        @uri ||= begin
          Chef::Log.debug("Checking SSL cert on #{given_uri}")
          URI.parse(given_uri)
        end
      end

      def given_uri
        (name_args[0] or Chef::Config.chef_server_url)
      end

      def host
        uri.host
      end

      def port
        uri.port
      end

      def validate_uri
        unless host && port
          invalid_uri!
        end
      rescue URI::Error
        invalid_uri!
      end

      def invalid_uri!
        ui.error("Given URI: `#{given_uri}' is invalid")
        show_usage
        exit 1
      end

      def remote_cert_chain
        tcp_connection = TCPSocket.new(host, port)
        shady_ssl_connection = OpenSSL::SSL::SSLSocket.new(tcp_connection, noverify_peer_ssl_context)
        shady_ssl_connection.connect
        shady_ssl_connection.peer_cert_chain
      end

      def noverify_peer_ssl_context
        @noverify_peer_ssl_context ||= begin
          noverify_peer_context = OpenSSL::SSL::SSLContext.new
          noverify_peer_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          noverify_peer_context
        end
      end


      def cn_of(certificate)
        subject = certificate.subject
        cn_field_tuple = subject.to_a.find {|field| field[0] == "CN" }
        cn_field_tuple[1]
      end

      # Convert the CN of a certificate into something that will work well as a
      # filename. To do so, all `*` characters are converted to the string
      # "wildcard" and then all characters other than alphanumeric and hypen
      # characters are converted to underscores.
      # NOTE: There is some confustion about what the CN will contain when
      # using internationalized domain names. RFC 6125 mandates that the ascii
      # representation be used, but it is not clear whether this is followed in
      # practice.
      # https://tools.ietf.org/html/rfc6125#section-6.4.2
      def normalize_cn(cn)
        cn.gsub("*", "wildcard").gsub(/[^[:alnum:]\-]/, '_')
      end

      def configuration
        Chef::Config
      end

      def trusted_certs_dir
        configuration.trusted_certs_dir
      end

      def write_cert(cert)
        FileUtils.mkdir_p(trusted_certs_dir)
        cn = cn_of(cert)
        filename = File.join(trusted_certs_dir, "#{normalize_cn(cn)}.crt")
        ui.msg("Adding certificate for #{cn} in #{filename}")
        File.open(filename, File::CREAT|File::TRUNC|File::RDWR, 0644) do |f|
          f.print(cert.to_s)
        end
      end

      def run
        validate_uri
        ui.warn(<<-TRUST_TRUST)
Certificates from #{host} will be fetched and placed in your trusted_cert
directory (#{trusted_certs_dir}).

Knife has no means to verify these are the correct certificates. You should
verify the authenticity of these certificates after downloading.

TRUST_TRUST
        remote_cert_chain.each do |cert|
          write_cert(cert)
        end
      rescue OpenSSL::SSL::SSLError => e
        # 'unknown protocol' usually means you tried to connect to a non-ssl
        # service. We handle that specially here, any other error we let bubble
        # up (probably a bug of some sort).
        raise unless e.message.include?("unknown protocol")

        ui.error("The service at the given URI (#{uri}) does not accept SSL connections")

        if uri.scheme == "http"
          https_uri = uri.to_s.sub(/^http/, 'https')
          ui.error("Perhaps you meant to connect to '#{https_uri}'?")
        end
        exit 1
      end


    end
  end
end

