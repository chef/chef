require_relative "licensing_config"

class Chef
  class Utils
    class LicensingHandler

      OMNITRUCK_URLS = {
        "free"       => "https://trial-acceptance.downloads.chef.co",
        "trial"      => "https://trial-acceptance.downloads.chef.co",
        "commercial" => "https://commercial-acceptance.downloads.chef.co",
      }.freeze

      attr_reader :license_key, :license_type

      def initialize(key, type)
        @license_key = key
        @license_type = type
      end

      def omnitruck_url
        return if license_type.nil?

        OMNITRUCK_URLS[license_type] + "/%s"
      end

      class << self
        def validate!
          license_keys = ChefLicensing::LicenseKeyFetcher.fetch

          return new(nil, nil) if license_keys.blank?

          licenses_metadata = ChefLicensing::Api::Describe.list({
            license_keys: license_keys,
          })

          new(licenses_metadata.last.id, licenses_metadata.last.license_type)
        end
      end
    end
  end
end
