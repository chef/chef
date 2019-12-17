#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2016-2019, Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    # @since 13.3
    class AptPreference < Chef::Resource
      unified_mode true

      resource_name :apt_preference
      provides(:apt_preference) { true }

      description "The apt_preference resource allows for the creation of APT preference files. Preference files are used to control which package versions and sources are prioritized during installation."
      introduced "13.3"

      property :package_name, String,
        name_property: true,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        regex: [/^([a-z]|[A-Z]|[0-9]|_|-|\.|\*|\+)+$/],
        validation_message: "The provided package name is not valid. Package names can only contain alphanumeric characters as well as _, -, +, or *!"

      property :glob, String,
        description: "Pin by glob() expression or with regular expressions surrounded by /."

      property :pin, String,
        description: "The package version or repository to pin.",
        required: true

      property :pin_priority, [String, Integer],
        description: "Sets the Pin-Priority for a package.",
        required: true

      default_action :add
      allowed_actions :add, :remove

      APT_PREFERENCE_DIR = "/etc/apt/preferences.d".freeze

      action_class do
        # Build preferences.d file contents
        def build_pref(package_name, pin, pin_priority)
          "Package: #{package_name}\nPin: #{pin}\nPin-Priority: #{pin_priority}\n"
        end

        def safe_name(name)
          name.tr(".", "_").gsub("*", "wildcard")
        end
      end

      action :add do
        return unless debian?

        preference = build_pref(
          new_resource.glob || new_resource.package_name,
          new_resource.pin,
          new_resource.pin_priority
        )

        directory APT_PREFERENCE_DIR do
          mode "0755"
          action :create
        end

        sanitized_prefname = safe_name(new_resource.package_name)

        # cleanup any existing pref files w/o the sanitized name (created by old apt cookbook)
        if (sanitized_prefname != new_resource.package_name) && ::File.exist?("#{APT_PREFERENCE_DIR}/#{new_resource.package_name}.pref")
          logger.warn "Replacing legacy #{new_resource.package_name}.pref with #{sanitized_prefname}.pref in #{APT_PREFERENCE_DIR}"
          file "#{APT_PREFERENCE_DIR}/#{new_resource.package_name}.pref" do
            action :delete
          end
        end

        # cleanup any existing pref files without the .pref extension (created by old apt cookbook)
        if ::File.exist?("#{APT_PREFERENCE_DIR}/#{new_resource.package_name}")
          logger.warn "Replacing legacy #{new_resource.package_name} with #{sanitized_prefname}.pref in #{APT_PREFERENCE_DIR}"
          file "#{APT_PREFERENCE_DIR}/#{new_resource.package_name}" do
            action :delete
          end
        end

        file "#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref" do
          mode "0644"
          content preference
          action :create
        end
      end

      action :remove do
        return unless debian?

        sanitized_prefname = safe_name(new_resource.package_name)

        if ::File.exist?("#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref")
          logger.info "Un-pinning #{sanitized_prefname} from #{APT_PREFERENCE_DIR}"
          file "#{APT_PREFERENCE_DIR}/#{sanitized_prefname}.pref" do
            action :delete
          end
        end
      end

    end
  end
end
