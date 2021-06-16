#
# Author:: Tim Smith (<tsmith@chef.io>)
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

require_relative "../resource"

class Chef
  class Resource
    class AptPreference < Chef::Resource
      unified_mode true

      provides(:apt_preference) { true }

      description "Use the **apt_preference** resource to create APT [preference files](https://wiki.debian.org/AptPreferences). Preference files are used to control which package versions and sources are prioritized during installation."
      introduced "13.3"
      examples <<~DOC
      **Pin libmysqlclient16 to a version 5.1.49-3**:

      ```ruby
      apt_preference 'libmysqlclient16' do
        pin          'version 5.1.49-3'
        pin_priority '700'
      end
      ```

      Note: The `pin_priority` of `700` ensures that this version will be preferred over any other available versions.

      **Unpin a libmysqlclient16**:

      ```ruby
      apt_preference 'libmysqlclient16' do
        action :remove
      end
      ```

      **Pin all packages to prefer the packages.dotdeb.org repository**:

      ```ruby
      apt_preference 'dotdeb' do
        glob         '*'
        pin          'origin packages.dotdeb.org'
        pin_priority '700'
      end
      ```
      DOC

      property :package_name, String,
        name_property: true,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        regex: [/^([a-z]|[A-Z]|[0-9]|_|-|\.|\*|\+)+$/],
        validation_message: "The provided package name is not valid. Package names can only contain alphanumeric characters as well as _, -, +, or *!"

      property :glob, String,
        description: "Pin by a `glob()` expression or with a regular expression surrounded by `/`."

      property :pin, String,
        description: "The package version or repository to pin.",
        required: [:add]

      property :pin_priority, [String, Integer],
        description: "Sets the Pin-Priority for a package. See <https://wiki.debian.org/AptPreferences> for more details.",
        required: [:add]

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

      action :add, description: "Creates a preferences file under `/etc/apt/preferences.d`." do
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

      action :remove, description: "Removes the preferences file, thus unpinning the package." do
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
