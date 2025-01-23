require_relative "licensing_config"

class Chef
  class Utils
    class LicensingHandler
      LEGACY_OMNITRUCK_URL = "https://omnitruck.chef.io".freeze

      OMNITRUCK_URLS = {
        "free"       => "https://chefdownload-trial.chef.io",
        "trial"      => "https://chefdownload-trial.chef.io",
        "commercial" => "https://chefdownload-commerical.chef.io",
      }.freeze

      attr_reader :license_key, :license_type

      def initialize(key, type)
        @license_key = key
        @license_type = type
      end

      def omnitruck_url
        url = OMNITRUCK_URLS[license_type] || LEGACY_OMNITRUCK_URL

        "#{url}/%s#{license_key ? "?license_id=#{license_key}" : ""}"
      end

      def install_sh_url
        format(omnitruck_url, "install.sh")
      end

      class << self
        def validate!
          license_keys = begin
                           ChefLicensing::LicenseKeyFetcher.fetch
                         # If the env is airgapped or the local licensing service is unreachable,
                         # the licensing gem will raise ChefLicensing::RestfulClientConnectionError.
                         # In such cases, we are assuming the license is not available.
                         rescue ChefLicensing::RestfulClientConnectionError
                           []
                         end

          return new(nil, nil) if license_keys&.empty?

          licenses_metadata = ChefLicensing::Api::Describe.list({
            license_keys: license_keys,
          })

          new(licenses_metadata.last.id, licenses_metadata.last.license_type)
        end
      end
    end
  end
end
