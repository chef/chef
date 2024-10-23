require_relative "licensing_config"

class Chef
  class Utils
    class LicensingHandler
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
        url = OMNITRUCK_URLS[license_type]

        "#{url}/%s#{license_key ? "?license_id=#{license_key}" : ""}"
      end

      def install_sh_url
        format(omnitruck_url, "install.sh")
      end

      class << self
        def validate!
          license_keys = ChefLicensing.license_keys

          return new(nil, nil) if license_keys.blank?

          licenses_metadata = ChefLicensing::Api::Describe.list({
            license_keys: license_keys,
          })

          new(licenses_metadata.last.id, licenses_metadata.last.license_type)
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
