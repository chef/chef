class Chef
  class Utils
    class LicensingHandler

      OMNITRUCK_URLS = {
        "free"       => "https://opensource-acceptance.downloads.chef.co",
        "trial"      => "https://trial-acceptance.downloads.chef.co",
        "commercial" => "https://commercial-acceptance.downloads.chef.co"
      }.freeze

      attr_reader :license_key, :license_type

      def initialize(key, type)
        @license_key = key
        @license_type = type
      end

      def omnitruck_url
        OMNITRUCK_URLS[license_type] + "/%s"
      end

      class << self
        def validate!
          license_keys = ChefLicensing::LicenseKeyFetcher.fetch

          licenses_metadata = ChefLicensing::Api::Describe.list({
            license_keys: license_keys,
          })

          new(licenses_metadata.first.id, licenses_metadata.first.license_type)
        end

        def check_software_entitlement!(ui)
          ChefLicensing.check_software_entitlement!
        rescue ChefLicensing::SoftwareNotEntitled
          ui.error "License is not entitled to use Workstation."
          exit 1
        rescue ChefLicensing::Error => e
          ui.error e.message
          exit 1
        end
      end
    end
  end
end
