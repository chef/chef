require "chef-licensing"
require_relative "log"
require_relative "licensing_config"
# To use platform helpers
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  class Licensing
    # License acceptance values that indicate the user has accepted the license
    CHEF_LICENSE_ACCEPT_VALUES = %w{accept accept-silent accept-no-persist}.freeze

    class << self
      def fetch_and_persist
        Chef::Log.info "Fetching and persisting license..."
        # Skip license validation in CI/testing environments and when CHEF_LICENSE is explicitly set.
        # This covers GitHub Actions, Buildkite, Test Kitchen, generic CI, and direct license acceptance
        # via the CHEF_LICENSE environment variable (e.g. CHEF_LICENSE=accept-no-persist).
        if skip_license_validation?
          Chef::Log.info "****Skipping license validation..."
          return
        end
        license_keys = ChefLicensing.fetch_and_persist
      rescue ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError
        Chef::Log.error "Chef Infra cannot execute without valid licenses." # TODO: Replace Infra with the product name dynamically
        Chef::Application.exit! "License not set", 174 # 174 is the exit code for LICENSE_NOT_SET defined in lib/chef/application/exit_code.rb
      rescue ChefLicensing::SoftwareNotEntitled
        Chef::Log.error "License is not entitled to use Chef Infra."
        Chef::Application.exit! "License not entitled", 173 # 173 is the exit code for LICENSE_NOT_ENTITLED defined in lib/chef/application/exit_code.rb
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # Generic failure
      end

      def check_software_entitlement!
        Chef::Log.info "Checking software entitlement..."
        # Skip entitlement check in the same environments where fetch_and_persist is skipped,
        # since no license keys would have been persisted in those environments.
        if skip_license_validation?
          Chef::Log.info "****Skipping software entitlement check..."
          return
        end
        ChefLicensing.check_software_entitlement!
      rescue ChefLicensing::SoftwareNotEntitled
        Chef::Log.error "License is not entitled to use Chef Infra."
        Chef::Application.exit! "License not entitled", 173 # 173 is the exit code for LICENSE_NOT_ENTITLED defined in lib/chef/application/exit_code.rb
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # Generic failure
      end

      def check_software_entitlement_compliance_phase!
        Chef::Log.info "Checking software entitlement for compliance phase..."
        # set the chef_entitlement_id to the value for Compliance Phase entitlement (i.e. InSpec's entitlement ID)
        ChefLicensing::Config.chef_entitlement_id = Chef::LicensingConfig::COMPLIANCE_ENTITLEMENT_ID
        ChefLicensing.check_software_entitlement!
      rescue ChefLicensing::SoftwareNotEntitled
        raise EntitlementError, "License not entitled"
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # Generic failure
      ensure
        # reset the chef_entitlement_id to the default value of Infra
        ChefLicensing::Config.chef_entitlement_id = Chef::LicensingConfig::INFRA_ENTITLEMENT_ID
      end

      def licensing_help
        <<~FOOTER

          Chef Infra has three tiers of licensing:

            * Free-Tier
              Users are limited to audit maximum of 10 nodes
              Entitled for personal or non-commercial use

            * Trial
              Entitled for unlimited number of nodes
              Entitled for 30 days only
              Entitled for commercial use

            * Commercial
              Entitled for purchased number of nodes
              Entitled for period of subscription purchased
              Entitled for commercial use

            For more information please visit:
            www.chef.io/licensing/faqs

        FOOTER
      end

      def license_list
        ChefLicensing.list_license_keys_info
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # Generic failure
      end

      def license_add
        ChefLicensing.add_license
      rescue ChefLicensing::LicenseKeyFetcher::LicenseKeyAddNotAllowed => e
        Chef::Log.error e.message
        Chef::Application.exit! "License not set", 174 # 174 is the exit code for LICENSE_NOT_SET defined in lib/chef/application/exit_code.rb
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # Generic failure
      end

      private

      # Returns true when license validation should be skipped.
      # Skips in CI environments (GitHub Actions, Buildkite, Test Kitchen, generic CI)
      # and when CHEF_LICENSE is explicitly set to an acceptance value.
      # Does NOT skip when running inside Docker containers managed by Test Kitchen
      # (those are tested separately via chef-test-kitchen-enterprise).
      def skip_license_validation?
        ci_environment? || chef_license_accepted?
      end

      def ci_environment?
        (ENV["TEST_KITCHEN"] || ENV["GITHUB_ACTIONS"] || ENV["BUILDKITE"] || ENV["CI"]) &&
          !ChefUtils.docker?
      end

      def chef_license_accepted?
        CHEF_LICENSE_ACCEPT_VALUES.include?(ENV["CHEF_LICENSE"])
      end
    end

    class EntitlementError < StandardError
    end
  end
end
