#
# Copyright:: 2011-2018, Joshua Timberman
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "corefoundation" if RUBY_PLATFORM.match?(/darwin/)
autoload :Plist, "plist"

class Chef
  class Resource
    class MacosUserDefaults < Chef::Resource

      # align with apple's marketing department
      provides(:macos_userdefaults) { true }
      provides(:mac_os_x_userdefaults) { true }

      description "Use the **macos_userdefaults** resource to manage the macOS user defaults system. The properties of this resource are passed to the defaults command, and the parameters follow the convention of that command. See the defaults(1) man page for details on how the tool works."
      introduced "14.0"
      examples <<~DOC
        **Specify a global domain value**

        ```ruby
        macos_userdefaults 'Full keyboard access to all controls' do
          key 'AppleKeyboardUIMode'
          value 2
        end
        ```

        **Setting a value on a specific domain**

        ```ruby
        macos_userdefaults 'Enable macOS firewall' do
          domain '/Library/Preferences/com.apple.alf'
          key 'globalstate'
          value 1
        end
        ```

        **Setting a value for specific user and hosts**

        ```ruby
        macos_userdefaults 'Enable macOS firewall' do
          key 'globalstate'
          value 1
          user 'jane'
          host :current
        end
        ```

      DOC

      property :domain, String,
        description: "The domain that the user defaults belong to.",
        default: "NSGlobalDomain",
        default_description: "NSGlobalDomain: the global domain.",
        desired_state: false

      property :global, [TrueClass, FalseClass],
        description: "Determines whether or not the domain is global.",
        deprecated: "As of Chef Infra Client 17.8 the `global` property is no longer necessary.",
        default: false,
        desired_state: false

      property :key, String,
        description: "The preference key.",
        required: true

      property :host, [String, Symbol],
        description: "Set either :current, :all or a hostname to set the user default at the host level.",
        default: :all,
        desired_state: false,
        introduced: "16.3"

      property :value, [Integer, Float, String, TrueClass, FalseClass, Hash, Array],
        description: "The value of the key. Note: With the `type` property set to `bool`, `String` forms of Boolean true/false values that Apple accepts in the defaults command will be coerced: 0/1, 'TRUE'/'FALSE,' 'true'/false', 'YES'/'NO', or 'yes'/'no'.",
        required: [:write]

      property :type, String,
        description: "The value type of the preference key.",
        equal_to: %w{bool string int float array dict},
        desired_state: false,
        deprecated: "As of Chef Infra Client 17.8 the `type` property is no longer necessary."

      property :user, [String, Symbol],
        description: "The system user that the default will be applied to. Set :current for current user, :all for all users or pass a valid username",
        default: :current,
        desired_state: false

      property :sudo, [TrueClass, FalseClass],
        description: "Set to true if the setting you wish to modify requires privileged access. This requires passwordless sudo for the `/usr/bin/defaults` command to be setup for the user running #{ChefUtils::Dist::Infra::PRODUCT}.",
        default: false,
        desired_state: false,
        deprecated: "As of Chef Infra Client 17.8 the `sudo` property is no longer necessary."

      load_current_value do |new_resource|
        Chef::Log.debug "#load_current_value: attempting to read \"#{new_resource.domain}\" value from preferences to determine state"

        pref = get_preference(new_resource)
        current_value_does_not_exist! if pref.nil?

        key new_resource.key
        value pref
      end

      action :write, description: "Write the value to the specified domain/key." do
        converge_if_changed do
          Chef::Log.debug("Updating defaults value for #{new_resource.key} in #{new_resource.domain}")
          CF::Preferences.set!(new_resource.key, new_resource.value, new_resource.domain, to_cf_user(new_resource.user), to_cf_host(new_resource.host))
        end
      end

      action :delete, description: "Delete a key from a domain." do
        # if it's not there there's nothing to remove
        return if current_resource.nil?

        converge_by("delete domain:#{new_resource.domain} key:#{new_resource.key}") do
          Chef::Log.debug("Removing defaults key: #{new_resource.key}")
          CF::Preferences.set!(new_resource.key, nil, new_resource.domain, to_cf_user(new_resource.user), to_cf_host(new_resource.host))
        end
      end

      def get_preference(new_resource)
        CF::Preferences.get(new_resource.key, new_resource.domain, to_cf_user(new_resource.user), to_cf_host(new_resource.host))
      end

      # Return valid hostname based on the input from host property
      def to_cf_host(value)
        case value
        when :all
          CF::Preferences::ALL_HOSTS
        when :current
          CF::Preferences::CURRENT_HOST
        else
          value
        end
      end

      # Return valid username based on the input from user property
      def to_cf_user(value)
        case value
        when :all
          CF::Preferences::ALL_USERS
        when :current
          CF::Preferences::CURRENT_USER
        else
          value
        end
      end
    end
  end
end
