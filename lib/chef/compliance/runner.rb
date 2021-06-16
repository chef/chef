autoload :Inspec, "inspec"

require_relative "default_attributes"

class Chef
  module Compliance
    class Runner < EventDispatch::Base
      extend Forwardable

      SUPPORTED_REPORTERS = %w{chef-automate chef-server-automate json-file audit-enforcer cli}.freeze
      SUPPORTED_FETCHERS = %w{chef-automate chef-server}.freeze

      attr_accessor :run_id
      attr_reader :node
      def_delegators :node, :logger

      def enabled?
        return false if @node.nil?

        # Did we parse the libraries file from the audit cookbook?  This class dates back to when Chef Automate was
        # renamed from Chef Visibility in 2017, so should capture all modern versions of the audit cookbook.
        audit_cookbook_present = defined?(::Reporter::ChefAutomate)

        logger.debug("#{self.class}##{__method__}: #{Inspec::Dist::PRODUCT_NAME} profiles? #{inspec_profiles.any?}")
        logger.debug("#{self.class}##{__method__}: audit cookbook? #{audit_cookbook_present}")
        logger.debug("#{self.class}##{__method__}: compliance phase attr? #{node["audit"]["compliance_phase"]}")

        if node["audit"]["compliance_phase"].nil?
          inspec_profiles.any? && !audit_cookbook_present
        else
          node["audit"]["compliance_phase"]
        end
      end

      def node=(node)
        @node = node
        node.default["audit"] = Chef::Compliance::DEFAULT_ATTRIBUTES.merge(node.default["audit"])
      end

      def node_load_completed(node, _expanded_run_list, _config)
        self.node = node
      end

      def run_started(run_status)
        self.run_id = run_status.run_id
      end

      def converge_start(run_context)
        # With all attributes - including cookbook - loaded, we now have enough data to validate
        # configuration.  Because the converge is best coupled with the associated compliance run, these validations
        # will raise (and abort the converge) if the compliance phase configuration is incorrect/will
        # prevent compliance phase from completing and submitting its report to all configured reporters.
        # can abort the converge if the compliance phase configuration (node attributes and client config)
        load_and_validate!
      end

      def run_completed(_node, _run_status)
        return unless enabled?

        logger.debug("#{self.class}##{__method__}: enabling Compliance Phase")

        report
      end

      def run_failed(_exception, _run_status)
        # If the run has failed because our own validation of compliance
        # phase configuration has failed, we don't want to submit a report
        # because we're still not configured correctly.
        return unless enabled? && @validation_passed

        logger.debug("#{self.class}##{__method__}: enabling Compliance Phase")

        report
      end

      ### Below code adapted from audit cookbook's files/default/handler/audit_report.rb

      DEPRECATED_CONFIG_VALUES = %w{
        attributes_save
        fail_if_not_present
        inspec_gem_source
        inspec_version
        interval
        owner
        raise_if_unreachable
      }.freeze

      def warn_for_deprecated_config_values!
        deprecated_config_values = (node["audit"].keys & DEPRECATED_CONFIG_VALUES)

        if deprecated_config_values.any?
          values = deprecated_config_values.sort.map { |v| "'#{v}'" }.join(", ")
          logger.warn "audit cookbook config values #{values} are not supported in #{ChefUtils::Dist::Infra::PRODUCT}'s Compliance Phase."
        end
      end

      def report(report = nil)
        logger.info "Starting Chef Infra Compliance Phase"
        report ||= generate_report
        # This is invoked at report-time instead of with the normal validations at node loaded,
        # because we want to ensure that it is visible in the output - and not lost in back-scroll.
        warn_for_deprecated_config_values!

        if report.empty?
          logger.error "Compliance report was not generated properly, skipped reporting"
          return
        end

        Array(node["audit"]["reporter"]).each do |reporter_type|
          logger.info "Reporting to #{reporter_type}"
          @reporters[reporter_type].send_report(report)
        end
        logger.info "Chef Infra Compliance Phase Complete"
      end

      def inspec_opts
        inputs = node["audit"]["attributes"].to_h
        if node["audit"]["chef_node_attribute_enabled"]
          inputs["chef_node"] = node.to_h
          inputs["chef_node"]["chef_environment"] = node.chef_environment
        end

        {
          backend_cache: node["audit"]["inspec_backend_cache"],
          inputs: inputs,
          logger: logger,
          output: node["audit"]["quiet"] ? ::File::NULL : STDOUT,
          report: true,
          reporter: ["json-automate"],
          reporter_backtrace_inclusion: node["audit"]["result_include_backtrace"],
          reporter_message_truncation: node["audit"]["result_message_limit"],
          waiver_file: Array(node["audit"]["waiver_file"]),
        }
      end

      def inspec_profiles
        profiles = node["audit"]["profiles"]
        unless profiles.respond_to?(:map) && profiles.all? { |_, p| p.respond_to?(:transform_keys) && p.respond_to?(:update) }
          raise "CMPL010: #{Inspec::Dist::PRODUCT_NAME} profiles specified in an unrecognized format, expected a hash of hashes."
        end

        profiles.map do |name, profile|
          profile.transform_keys(&:to_sym).update(name: name)
        end
      end

      def load_fetchers!
        case node["audit"]["fetcher"]
        when "chef-automate"
          require_relative "fetcher/automate"
        when "chef-server"
          require_relative "fetcher/chef_server"
        when nil
          # intentionally blank
        end
      end

      def generate_report(opts: inspec_opts, profiles: inspec_profiles)
        load_fetchers!

        logger.debug "Options are set to: #{opts}"
        runner = ::Inspec::Runner.new(opts)

        if profiles.empty?
          failed_report("No #{Inspec::Dist::PRODUCT_NAME} profiles are defined.")
          return
        end

        profiles.each { |target| runner.add_target(target) }

        logger.info "Running profiles from: #{profiles.inspect}"
        runner.run
        runner.report.tap do |r|
          logger.debug "Compliance Report #{r}"
        end
      rescue Inspec::FetcherFailure => e
        failed_report("Cannot fetch all profiles: #{profiles}. Please make sure you're authenticated and the server is reachable. #{e.message}")
      rescue => e
        failed_report(e.message)
      end

      # In case InSpec raises a runtime exception without providing a valid report,
      # we make one up and add two new fields to it: `status` and `status_message`
      def failed_report(err)
        logger.error "#{Inspec::Dist::PRODUCT_NAME} has raised a runtime exception. Generating a minimal failed report."
        logger.error err
        {
          "platform": {
            "name": "unknown",
            "release": "unknown",
          },
          "profiles": [],
          "statistics": {
            "duration": 0.0000001,
          },
          "version": Inspec::VERSION,
          "status": "failed",
          "status_message": err,
        }
      end

      # extracts relevant node data
      def node_info
        chef_server_uri = URI(Chef::Config[:chef_server_url])

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

      def reporter(reporter_type)
        case reporter_type
        when "chef-automate"
          require_relative "reporter/automate"
          opts = {
            control_results_limit: node["audit"]["control_results_limit"],
            entity_uuid: node["chef_guid"],
            insecure: node["audit"]["insecure"],
            node_info: node_info,
            run_id: run_id,
            run_time_limit: node["audit"]["run_time_limit"],
          }
          Chef::Compliance::Reporter::Automate.new(opts)
        when "chef-server-automate"
          require_relative "reporter/chef_server_automate"
          opts = {
            control_results_limit: node["audit"]["control_results_limit"],
            entity_uuid: node["chef_guid"],
            insecure: node["audit"]["insecure"],
            node_info: node_info,
            run_id: run_id,
            run_time_limit: node["audit"]["run_time_limit"],
            url: chef_server_automate_url,
          }
          Chef::Compliance::Reporter::ChefServerAutomate.new(opts)
        when "json-file"
          require_relative "reporter/json_file"
          path = node.dig("audit", "json_file", "location")
          Chef::Compliance::Reporter::JsonFile.new(file: path)
        when "audit-enforcer"
          require_relative "reporter/compliance_enforcer"
          Chef::Compliance::Reporter::ComplianceEnforcer.new
        when "cli"
          require_relative "reporter/cli"
          Chef::Compliance::Reporter::Cli.new
        end
      end

      def chef_server_automate_url
        url = if node["audit"]["server"]
                URI(node["audit"]["server"])
              else
                URI(Chef::Config[:chef_server_url]).tap do |u|
                  u.path = ""
                end
              end

        org = Chef::Config[:chef_server_url].split("/").last
        url.path = File.join(url.path, "organizations/#{org}/data-collector")
        url
      end

      # Load the resources required for this runner, and validate configuration
      # is correct to proceed. Requires node state to be loaded.
      # Will raise exception if fetcher is not valid, if a reporter is not valid,
      # or the configuration required by a reporter is not provided.
      def load_and_validate!
        return unless enabled?

        @reporters = {}
        # Note that the docs don't say you can use an array, but our implementation
        # supports it.
        Array(node["audit"]["reporter"]).each do |type|
          unless SUPPORTED_REPORTERS.include? type
            raise "CMPL003: '#{type}' found in node['audit']['reporter'] is not a supported reporter for Compliance Phase. Supported reporters are: #{SUPPORTED_REPORTERS.join(", ")}. For more information, see the documentation at https://docs.chef.io/chef_compliance_phase#reporters"
          end

          @reporters[type] = reporter(type)
          @reporters[type].validate_config!
        end

        unless (fetcher = node["audit"]["fetcher"]).nil?
          unless SUPPORTED_FETCHERS.include? fetcher
            raise "CMPL002: Unrecognized Compliance Phase fetcher (node['audit']['fetcher'] = #{fetcher}). Supported fetchers are: #{SUPPORTED_FETCHERS.join(", ")}, or nil. For more information, see the documentation at https://docs.chef.io/chef_compliance_phase#fetch-profiles"
          end
        end
        @validation_passed = true
      end
    end
  end
end
