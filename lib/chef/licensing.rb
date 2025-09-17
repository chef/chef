require "chef-licensing"
require_relative "log"
require_relative "licensing_config"
# To use platform helpers
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  class Licensing
    class << self
      def fetch_and_persist
        Chef::Log.info "Fetching and persisting license..."
        # This is a temporary arrangement to continue end-to-end recipe testing of Chef.
        # Windows, Mac, Linux VMs on vagrant will be tested using legacy test-kitchen
        # whereas Linux docker containers will be tested using chef-test-kitchen-enterprise (habitat)
        # Reason: chef-test-kitchen-enterprise currently supports only kitchen-dokken driver and is available only for Linux x86_64
        # So for now we skip license validation on Mac, Windows, Linux distributions which run using test kitchen.
        if ENV["TEST_KITCHEN"] && !ChefUtils.docker?
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
    end

    class EntitlementError < StandardError
    end
  end
end
