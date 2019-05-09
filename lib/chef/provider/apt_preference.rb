#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2016-2017, Chef Software, Inc.
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

require_relative "../provider"
require_relative "../dsl/declare_resource"
require_relative "noop"
require_relative "../log"

class Chef
  class Provider
    class AptPreference < Chef::Provider
      provides :apt_preference, platform_family: "debian"

      APT_PREFERENCE_DIR = "/etc/apt/preferences.d".freeze

      def load_current_resource
      end

      action :add do
        preference = build_pref(
          new_resource.glob || new_resource.package_name,
          new_resource.pin,
          new_resource.pin_priority
        )

        declare_resource(:directory, APT_PREFERENCE_DIR) do
          mode "0755"
          action :create
        end

        sanitized_prefname = safe_name(new_resource.package_name)

        # cleanup any existing pref files w/o the sanitized name (created by old apt cookbook)
        if (sanitized_prefname != new_resource.package_name) && ::File.exist?("#{APT_PREFERENCE_DIR}/#{new_resource.package_name}.pref")
          logger.warn "Replacing legacy #{new_resource.package_name}.pref with #{sanitized_prefname}.pref in #{APT_PREFERENCE_DIR}"
          declare_resource(:file, "#{APT_PREFERENCE_DIR}/#{new_resource.package_name}.pref") do
            action :delete
          end
        end

        # cleanup any existing pref files without the .pref extension (created by old apt cookbook)
        if ::File.exist?("#{APT_PREFERENCE_DIR}/#{new_resource.package_name}")
          logger.warn "Replacing legacy #{new_resource.package_name} with #{sanitized_prefname}.pref in #{APT_PREFERENCE_DIR}"
          declare_resource(:file, "#{APT_PREFERENCE_DIR}/#{new_resource.package_name}") do
            action :delete
          end
        end

        declare_resource(:file, "#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref") do
          mode "0644"
          content preference
          action :create
        end
      end

      action :remove do
        sanitized_prefname = safe_name(new_resource.package_name)

        if ::File.exist?("#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref")
          logger.info "Un-pinning #{sanitized_prefname} from #{APT_PREFERENCE_DIR}"
          declare_resource(:file, "#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref") do
            action :delete
          end
        end
      end

      # Build preferences.d file contents
      def build_pref(package_name, pin, pin_priority)
        "Package: #{package_name}\nPin: #{pin}\nPin-Priority: #{pin_priority}\n"
      end

      def safe_name(name)
        name.tr(".", "_").gsub("*", "wildcard")
      end
    end
  end
end

Chef::Provider::Noop.provides :apt_preference
