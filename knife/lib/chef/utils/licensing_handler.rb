#
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "licensing_config"

class Chef
  class Utils
    class LicensingHandler
      LEGACY_OMNITRUCK_URL = "https://omnitruck.chef.io".freeze

      OMNITRUCK_URLS = {
        "free" => "https://chefdownload-trial.chef.io",
        "trial" => "https://chefdownload-trial.chef.io",
        "commercial" => "https://chefdownload-commerical.chef.io",
      }.freeze

      attr_reader :license_key, :license_type

      def initialize(key, type)
        @license_key = key
        @license_type = type
      end

      def omnitruck_url
        url = OMNITRUCK_URLS[license_type]
        is_legacy = url.nil?
        url ||= LEGACY_OMNITRUCK_URL

        "#{url}/%s#{is_legacy ? "" : "?license_id=#{license_key}"}"
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
