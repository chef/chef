autoload :Inspec, "inspec"

require_relative "default_attributes"
require_relative "fetcher/automate"
require_relative "fetcher/chef_server"
require_relative "reporter/audit_enforcer"
require_relative "reporter/automate"
require_relative "reporter/chef_server_automate"
require_relative "reporter/json_file"

class Chef
  module Audit
    class Runner < EventDispatch::Base
      extend Forwardable

      attr_reader :run_status
      def_delegators :run_status, :node, :run_context, :run_id
      def_delegators :node, :logger

      def enabled?
        cookbook_collection = run_context.cookbook_collection

        logger.info("#{self.class}##{__method__}: inspec profiles? #{inspec_profiles.any?}")
        logger.info("#{self.class}##{__method__}: audit cookbook? #{cookbook_collection.key?("audit")}")

        inspec_profiles.any? && !cookbook_collection.key?("audit")
      end

      def run_completed(_node, run_status)
        @run_status = run_status

        return unless enabled?

        logger.info("#{self.class}##{__method__}: enabling audit mode")

        report
      end

# TODO: handle error reports
=begin
      # Called at the end of a failed Chef run.
      def run_failed(exception, run_status); end

      # Called after Chef client has loaded the node data.
      # Default and override attrs from roles have been computed, but not yet applied.
      # Normal attrs from JSON have been added to the node.
      def node_load_completed(node, expanded_run_list, config); end
=end

      ### Below code adapted from audit cookbook's files/default/handler/audit_report.rb

      def report(report = generate_report)
        if report.empty?
          Chef::Log.error "Audit report was not generated properly, skipped reporting"
          return
        end

        Array(audit_attributes["reporter"]).each do |reporter|
          send_report(reporter, report)
        end
      end

      def inspec_opts
        waivers = Array(audit_attributes["waiver_file"]).select do |file|
          return true if File.exist?(file)

          Chef::Log.error "The specified InSpec waiver file #{file} is missing, skipping it..."
          false
        end

        {
          "report" => true,
          "format" => "json-automate", # TODO: Remove this? Deprecation notice in audit cookbook
          "reporter" => ["json-automate"],
          "output" => audit_attributes["quiet"] ? ::File::NULL : STDOUT,
          "logger" => Chef::Log,
          backend_cache: audit_attributes["inspec_backend_cache"],
          attributes: audit_attributes["attributes"],
          waiver_file: waivers,
          reporter_message_truncation: audit_attributes["result_message_limit"],
          reporter_backtrace_inclusion: audit_attributes["result_include_backtrace"],
        }
      end

      def audit_attributes
        @audit_attributes ||= Chef::Audit::DefaultAttributes::DEFAULTS.merge(node["audit"] || {})
      end

      def inspec_profiles
        audit_attributes["profiles"].map do |name, profile|
          profile.transform_keys(&:to_sym).update(name: name)
        end
      end

      def generate_report(opts: inspec_opts, profiles: inspec_profiles)
        Chef::Log.debug "Options are set to: #{opts}"
        runner = ::Inspec::Runner.new(opts)

        if profiles.empty?
          failed_report("No audit profiles are defined.")
          return
        end

        profiles.each { |target| runner.add_target(target, opts) }

        Chef::Log.info "Running profiles from: #{profiles.inspect}"
        runner.run
        r = runner.report
        Chef::Log.debug "Audit Report #{r}"
        r
=begin
      rescue Inspec::FetcherFailure => e
        err = "Cannot fetch all profiles: #{profiles}. Please make sure you're authenticated and the server is reachable. #{e.message}"
        failed_report(err)
      rescue => e
        failed_report(e.message)
=end
      end

      # In case InSpec raises a runtime exception without providing a valid report,
      # we make one up and add two new fields to it: `status` and `status_message`
      def failed_report(err)
        Chef::Log.error "InSpec has raised a runtime exception. Generating a minimal failed report."
        Chef::Log.error err
        {
          "platform": {
            "name": "unknown",
            "release": "unknown",
          },
          "profiles": [],
          "statistics": {
            "duration": 0.0000001,
          },
          "version": "4.22.0",
          "status": "failed",
          "status_message": err,
        }
      end

      # extracts relevant node data
      def node_info
        runlist_roles = node.run_list.select { |item| item.type == :role }.map(&:name)
        runlist_recipes = node.run_list.select { |item| item.type == :recipe }.map(&:name)
        {
          node: node.name,
          os: {
            release: node["platform_version"],
            family: node["platform"],
          },
          environment: node.environment,
          roles: runlist_roles,
          recipes: runlist_recipes,
          policy_name: node.policy_name || "",
          policy_group: node.policy_group || "",
          chef_tags: node.tags,
          organization_name: chef_server_uri.path.split("/").last || "",
          source_fqdn: chef_server_uri.host || "",
          ipaddress: node["ipaddress"],
          fqdn: node["fqdn"],
        }
      end

      def send_report(reporter, report)
        Chef::Log.info "Reporting to #{reporter}"

        insecure = audit_attributes["insecure"]
        run_time_limit = audit_attributes["run_time_limit"]
        control_results_limit = audit_attributes["control_results_limit"]

        case reporter
        when "chef-automate"
          opts = {
            entity_uuid: node["chef_guid"],
            run_id: run_id,
            node_info: node_info,
            insecure: insecure,
            run_time_limit: run_time_limit,
            control_results_limit: control_results_limit,
          }
          Chef::Audit::Reporter::Automate.new(opts).send_report(report)
        when "chef-server-automate"
          chef_url = audit_attributes["server"] || base_chef_server_url
          chef_org = Chef::Config[:chef_server_url].split("/").last
          if chef_url
            url = construct_url(chef_url, File.join("organizations", chef_org, "data-collector"))
            opts = {
              entity_uuid: node["chef_guid"],
              run_id: run_id,
              node_info: node_info,
              insecure: insecure,
              url: url,
              run_time_limit: run_time_limit,
              control_results_limit: control_results_limit,
            }
            Chef::Audit::Reporter::ChefServer.new(opts).send_report(report)
          else
            Chef::Log.warn "unable to determine chef-server url required by inspec report collector '#{reporter}'. Skipping..."
          end
        when "json-file"
          path = audit_attributes["json_file"]["location"]
          Chef::Log.info "Writing report to #{path}"
          Chef::Audit::Reporter::JsonFile.new(file: path).send_report(report)
        when "audit-enforcer"
          Chef::Audit::Reporter::AuditEnforcer.new.send_report(report)
        else
          Chef::Log.warn "#{reporter} is not a supported InSpec report collector"
        end
      end
    end
  end
end
