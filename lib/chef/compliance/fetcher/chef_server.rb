require "uri" unless defined?(URI)
require "plugins/inspec-compliance/lib/inspec-compliance"

# This class implements an InSpec fetcher for Chef Server. The implementation
# is based on the Chef Compliance fetcher and only adapts the calls to redirect
# the requests via Chef Server.
#
# This implementation depends on chef-client runtime, therefore it is only executable
# inside of a chef-client run

class Chef
  module Compliance
    module Fetcher
      class ChefServer < ::InspecPlugins::Compliance::Fetcher
        name "chef-server"

        # it positions itself before `compliance` fetcher
        # only load it, if the Chef Server is integrated with Chef Compliance
        priority 501

        CONFIG = { "insecure" => true }.freeze

        # Accepts URLs to compliance profiles in one of two forms:
        # * a String URL with a compliance scheme, like "compliance://namespace/profile_name"
        # * a Hash with a key of `compliance` and a value like "compliance/profile_name" and optionally a `version` key with a String value
        def self.resolve(target)
          profile_uri = get_target_uri(target)
          return nil if profile_uri.nil?

          organization = Chef::Config[:chef_server_url].split("/").last
          owner = profile_uri.user ? "#{profile_uri.user}@#{profile_uri.host}" : profile_uri.host
          version = target[:version] if target.respond_to?(:key?)

          path_parts = [""]
          path_parts << "compliance" if chef_server_reporter? || chef_server_fetcher?
          path_parts << "organizations"
          path_parts << organization
          path_parts << "owners"
          path_parts << owner
          path_parts << "compliance"
          path_parts << profile_uri.path
          path_parts << "version/#{version}" if version
          path_parts << "tar"

          target_url = URI(Chef::Config[:chef_server_url])
          target_url.path = File.join(path_parts)
          Chef::Log.info("Fetching profile from: #{target_url}")

          new(target_url, CONFIG)
        rescue URI::Error => _e
          nil
        end

        #
        # We want to save compliance: in the lockfile rather than url: to
        # make sure we go back through the ComplianceAPI handling.
        #
        def resolved_source
          { compliance: chef_server_url }
        end

        # Downloads archive to temporary file using a Chef::ServerAPI
        # client so that Chef Server's header-based authentication can be
        # used.
        def download_archive_to_temp
          return @temp_archive_path unless @temp_archive_path.nil?

          rest = Chef::ServerAPI.new(@target, Chef::Config.merge(ssl_verify_mode: :verify_none))
          archive = with_http_rescue do
            rest.streaming_request(@target)
          end
          @archive_type = ".tar.gz"

          if archive.nil?
            path = @target.respond_to?(:path) ? @target.path : path
            raise Inspec::FetcherFailure, "Unable to find requested profile on path: '#{path}' on the #{ChefUtils::Dist::Automate::PRODUCT} system."
          end

          Inspec::Log.debug("Archive stored at temporary location: #{archive.path}")
          @temp_archive_path = archive.path
        end

        def with_http_rescue
          response = yield
          if response.respond_to?(:code)
            # handle non 200 error codes, they are not raised as Net::HTTPClientException
            handle_http_error_code(response.code) if response.code.to_i >= 300
          end
          response
        rescue Net::HTTPClientException => e
          Chef::Log.error e
          handle_http_error_code(e.response.code)
        end

        def handle_http_error_code(code)
          case code
          when /401|403/
            Chef::Log.error "Auth issue: see the Compliance Phase troubleshooting documentation (http://docs.chef.io/chef_compliance_phase/#troubleshooting)."
          when /404/
            Chef::Log.error "Object does not exist on remote server."
          when /413/
            Chef::Log.error "You most likely hit the erchef request size in #{ChefUtils::Dist::Server::PRODUCT} that defaults to ~2MB. To increase this limit see the Compliance Phase troubleshooting documentation (http://docs.chef.io/chef_compliance_phase/#troubleshooting) or the Chef Infra Server configuration documentation (https://docs.chef.io/server/config_rb_server/)"
          when /429/
            Chef::Log.error "This error typically means the data sent was larger than #{ChefUtils::Dist::Automate::PRODUCT}'s limit (4 MB). Run InSpec locally to identify any controls producing large diffs."
          end
          msg = "Received HTTP error #{code}"
          Chef::Log.error msg
          raise Inspec::FetcherFailure, msg
        end

        def to_s
          "#{ChefUtils::Dist::Server::PRODUCT}/Compliance Profile Loader"
        end

        CHEF_SERVER_REPORTERS = %w{chef-server chef-server-compliance chef-server-visibility chef-server-automate}.freeze
        def self.chef_server_reporter?
          (Array(Chef.node.attributes["audit"]["reporter"]) & CHEF_SERVER_REPORTERS).any?
        end

        CHEF_SERVER_FETCHERS = %w{chef-server chef-server-compliance chef-server-visibility chef-server-automate}.freeze
        def self.chef_server_fetcher?
          CHEF_SERVER_FETCHERS.include?(Chef.node.attributes["audit"]["fetcher"])
        end

        private

        def chef_server_url
          m = %r{^#{@config['server']}/owners/(?<owner>[^/]+)/compliance/(?<id>[^/]+)/tar$}.match(@target)
          "#{m[:owner]}/#{m[:id]}"
        end
      end
    end
  end
end
