require_relative "automate"

class Chef
  module Compliance
    module Reporter
      #
      # Used to send inspec reports to Chef Automate server via Chef Server
      #
      class ChefServerAutomate < Chef::Compliance::Reporter::Automate
        attr_reader :url

        def initialize(opts)
          @entity_uuid           = opts[:entity_uuid]
          @run_id                = opts[:run_id]
          @node_name             = opts[:node_info][:node]
          @insecure              = opts[:insecure]
          @environment           = opts[:node_info][:environment]
          @roles                 = opts[:node_info][:roles]
          @recipes               = opts[:node_info][:recipes]
          @url                   = opts[:url]
          @chef_tags             = opts[:node_info][:chef_tags]
          @policy_group          = opts[:node_info][:policy_group]
          @policy_name           = opts[:node_info][:policy_name]
          @source_fqdn           = opts[:node_info][:source_fqdn]
          @organization_name     = opts[:node_info][:organization_name]
          @ipaddress             = opts[:node_info][:ipaddress]
          @fqdn                  = opts[:node_info][:fqdn]
          @control_results_limit = opts[:control_results_limit]
          @timestamp             = opts.fetch(:timestamp) { Time.now }
        end

        def send_report(report)
          automate_report = truncate_controls_results(enriched_report(report), @control_results_limit)

          report_size = Chef::JSONCompat.to_json(automate_report, validate_utf8: false).bytesize
          # this is set to slightly less than the oc_erchef limit
          if report_size > 900 * 1024
            Chef::Log.warn "Generated report size is #{(report_size / (1024 * 1024.0)).round(2)} MB. #{ChefUtils::Dist::Server::PRODUCT} < 13.0 defaults to a limit of ~1MB, 13.0+ defaults to a limit of ~2MB."
          end

          Chef::Log.info "Report to #{ChefUtils::Dist::Automate::PRODUCT} via #{ChefUtils::Dist::Server::PRODUCT}: #{@url}"
          with_http_rescue do
            http_client.post(@url, automate_report)
            return true
          end
          false
        end

        def validate_config!
          unless @entity_uuid
            raise "CMPL007: chef_server_automate reporter: chef_guid is not available and must be provided. Aborting because we cannot report the scan"
          end

          unless @run_id
            raise "CMPL008: chef_server_automate reporter: run_id is not available, aborting because we cannot report the scan."
          end
        end

        def http_client
          config = if @insecure
                     Chef::Config.merge(ssl_verify_mode: :verify_none)
                   else
                     Chef::Config
                   end

          Chef::ServerAPI.new(@url, config)
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
            Chef::Log.error "You most likely hit the request size limit in #{ChefUtils::Dist::Server::PRODUCT} that defaults to ~2MB. To increase this limit see the Compliance Phase troubleshooting documentation (http://docs.chef.io/chef_compliance_phase/#troubleshooting) or the Chef Infra Server configuration documentation (https://docs.chef.io/server/config_rb_server/)"
          when /429/
            Chef::Log.error "This error typically means the data sent was larger than #{ChefUtils::Dist::Automate::PRODUCT}'s limit (4 MB). Run InSpec locally to identify any controls producing large diffs."
          end
          msg = "Received HTTP error #{code}"
          Chef::Log.error msg
          raise msg
        end
      end
    end
  end
end
