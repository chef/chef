class Chef
  module Audit
    module Reporter
      #
      # Used to send inspec reports to Chef Automate via the data_collector service
      #
      class Automate
        def initialize(opts)
          @entity_uuid           = opts[:entity_uuid]
          @run_id                = opts[:run_id]
          @node_name             = opts[:node_info][:node]
          @environment           = opts[:node_info][:environment]
          @roles                 = opts[:node_info][:roles]
          @recipes               = opts[:node_info][:recipes]
          @insecure              = opts[:insecure]
          @chef_tags             = opts[:node_info][:chef_tags]
          @policy_group          = opts[:node_info][:policy_group]
          @policy_name           = opts[:node_info][:policy_name]
          @source_fqdn           = opts[:node_info][:source_fqdn]
          @organization_name     = opts[:node_info][:organization_name]
          @ipaddress             = opts[:node_info][:ipaddress]
          @fqdn                  = opts[:node_info][:fqdn]
          @run_time_limit        = opts[:run_time_limit]
          @control_results_limit = opts[:control_results_limit]
          @timestamp             = opts.fetch(:timestamp) { Time.now }

          @url = Chef::Config[:data_collector][:server_url]
          @token = Chef::Config[:data_collector][:token]
        end

        # Method used in order to send the inspec report to the data_collector server
        def send_report(report)
          unless @entity_uuid && @run_id
            Chef::Log.error "entity_uuid(#{@entity_uuid}) or run_id(#{@run_id}) can't be nil, not sending report to Chef Automate"
            return false
          end

          unless @url && @token
            Chef::Log.warn "data_collector.token and data_collector.server_url must be defined in client.rb!"
            Chef::Log.warn "Further information: https://github.com/chef-cookbooks/audit#direct-reporting-to-chef-automate"
            return false
          end

          headers = {
            "Content-Type" => "application/json",
            "x-data-collector-auth" => "version=1.0",
            "x-data-collector-token" => @token,
          }

          all_report_shas = report.fetch(:profiles, []).map { |p| p[:sha256] }
          missing_report_shas = missing_automate_profiles(headers, all_report_shas)

          full_report = truncate_controls_results(enriched_report(report), @control_results_limit)

          # If the Automate backend has the profile metadata for at least one profile, proceed with metadata stripping
          full_report = strip_profiles_meta(full_report, missing_report_shas, 1) if missing_report_shas.length < all_report_shas.length
          json_report = full_report.to_json

          report_size = json_report.bytesize
          # Automate GRPC currently has a message limit of ~4MB
          # https://github.com/chef/automate/issues/1417#issuecomment-541908157
          if report_size > 4 * 1024 * 1024
            Chef::Log.warn "Compliance report size is #{(report_size / (1024 * 1024.0)).round(2)} MB."
            Chef::Log.warn "Automate has an internal 4MB limit that is not currently configurable."
          end

          unless json_report
            Chef::Log.warn "Something went wrong, report can't be nil"
            return false
          end

          begin
            Chef::Log.info "Report to Chef Automate: #{@url}"
            Chef::Log.debug "Audit Report: #{json_report}"
            http_client.post(nil, json_report, headers)
            true
          rescue => e
            Chef::Log.error "send_report: POST to #{@url} returned: #{e.message}"
            false
          end
        end

        def http_client(url = @url)
          if @insecure
            Chef::HTTP.new(url, ssl_verify_mode: :verify_none)
          else
            Chef::HTTP.new(url)
          end
        end

        # ***************************************************************************************
        # TODO: We could likely simplify/remove some of the extra logic we have here with a small
        # revamp of the Automate expected input.
        # ***************************************************************************************

        def enriched_report(final_report)
          # Remove nil profiles if any
          final_report[:profiles].select! { |p| p }

          # Label this content as an inspec_report
          final_report[:type] = "inspec_report"

          final_report[:node_name]         = @node_name
          final_report[:end_time]          = @timestamp.utc.strftime("%FT%TZ")
          final_report[:node_uuid]         = @entity_uuid
          final_report[:environment]       = @environment
          final_report[:roles]             = @roles
          final_report[:recipes]           = @recipes
          final_report[:report_uuid]       = @run_id
          final_report[:source_fqdn]       = @source_fqdn
          final_report[:organization_name] = @organization_name
          final_report[:policy_group]      = @policy_group
          final_report[:policy_name]       = @policy_name
          final_report[:chef_tags]         = @chef_tags
          final_report[:ipaddress]         = @ipaddress
          final_report[:fqdn]              = @fqdn

          final_report
        end

        CONTROL_RESULT_SORT_ORDER = %w{ failed skipped passed }.freeze

        # Truncates the number of results per control in the report when they exceed max_results.
        # The truncation prioritizes failed and skipped results over passed ones.
        # Controls where results have been truncated will get a new object 'removed_results_counts'
        # with the status counts of the truncated results
        def truncate_controls_results(report, max_results)
          return report unless max_results.is_a?(Integer) && max_results > 0

          report.fetch(:profiles, []).each do |profile|
            profile.fetch(:controls, []).each do |control|
              # Only bother with truncation if the number of results exceed max_results
              next unless control[:results].length > max_results

              res = control[:results]
              res.sort_by! { |r| CONTROL_RESULT_SORT_ORDER.index(r[:status]) }

              # Count the results that will be truncated
              truncated = { failed: 0, skipped: 0, passed: 0 }
              (max_results..res.length - 1).each do |i|
                case res[i][:status]
                when "failed"
                  truncated[:failed] += 1
                when "skipped"
                  truncated[:skipped] += 1
                when "passed"
                  truncated[:passed] += 1
                end
              end
              # Truncate the results array now
              control[:results] = res[0..max_results - 1]
              control[:removed_results_counts] = truncated
            end
          end
          report
        end

        # Contacts the metasearch Automate API to check which of the inspec profile sha256 ids
        # passed in via `report_shas` are missing from the Automate profiles metadata database.
        def missing_automate_profiles(headers, report_shas)
          Chef::Log.debug "Checking the Automate profiles metadata for: #{report_shas}"
          meta_url = URI(@url)
          meta_url.path = "/compliance/profiles/metasearch"
          response_str = http_client(meta_url.to_s).post(nil, "{\"sha256\": #{report_shas}}", headers)
          missing_shas = JSON.parse(response_str)["missing_sha256"]
          unless missing_shas.empty?
            Chef::Log.info "Automate is missing metadata for the following profile ids: #{missing_shas}"
          end
          missing_shas
        rescue => e
          Chef::Log.error "missing_automate_profiles error: #{e.message}"
          # If we get an error it's safer to assume none of the profile shas exist in Automate
          report_shas
        end
      end
    end
  end
end
