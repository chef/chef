require "chef-licensing"
require_relative "log"
require_relative "licensing_config"

class Chef
  class Licensing
    class << self
      def fetch_and_persist
        puts "Fetching and persisting license..."
        license_keys = ChefLicensing.fetch_and_persist
      rescue ChefLicensing::LicenseKeyFetcher::LicenseKeyNotFetchedError
        Chef::Log.error "Infra cannot execute without valid licenses." # TODO: Replace Infra with the product name dynamically
        Chef::Application.exit! "License not set", 1 # TODO: Replace 1 with a constant after deciding on the exit code
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # TODO: Replace 1 with a constant after deciding on the exit code
      end

      def check_software_entitlement!
        puts "Checking software entitlement..."
        ChefLicensing.check_software_entitlement!
      rescue ChefLicensing::SoftwareNotEntitled
        Chef::Log.error "License is not entitled to use Infra."
        Chef::Application.exit! "License not entitled", 1 # TODO: Replace 1 with a constant after deciding on the exit code
      rescue ChefLicensing::Error => e
        Chef::Log.error e.message
        Chef::Application.exit! "Usage error", 1 # TODO: Replace 1 with a constant after deciding on the exit code
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

            knife license add: This command helps users to generate or add an additional license (not applicable to local licensing service)

            For more information please visit:
            www.chef.io/licensing/faqs

        FOOTER
      end
    end
  end
end
