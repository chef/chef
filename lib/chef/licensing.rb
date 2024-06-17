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
    end
  end
end
