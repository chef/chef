#
# Author:: Ryan Cragun (<ryan@chef.io>)
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

require_relative "../user"

class Chef
  class Resource
    class User
      # Provide a user resource that is compatible with default TCC restrictions
      # that were introduced in macOS 10.14.
      #
      # Changes:
      #
      # * This resource and the corresponding provider have been modified to
      #   work with default macOS TCC policies. Direct access to user binary
      #   plists are no longer permitted by default, thus we've chosen to use
      #   a combination of newer utilities for managing user lifecycles and older
      #   utilities for managing passwords.
      #
      # * Due to tooling changes that were necessitated by the new policy
      #   restrictions the mac_user resource is only suitable for use on macOS
      #   >= 10.14. Support for older platforms has been removed.
      #
      # New Features:
      #
      # * Primary group management is now included.
      #
      # * 'admin' is now a boolean property that configures a user to an admin.
      #
      # * 'admin_username' and 'admin_password' are new properties that define the
      #   admin user credentials required for toggling SecureToken for a user.
      #
      #   The value of 'admin_username' must correspond to a system user that
      #   is part of the 'admin' with SecureToken enabled in order to toggle
      #   SecureToken.
      #
      # * 'secure_token' is a boolean property that sets the desired state
      #   for SecureToken. SecureToken token is required for FileVault full
      #   disk encryption.
      #
      # * 'secure_token_password' is the plaintext password required to enable
      #   or disable secure_token for a user. If no salt is specified we assume
      #   the 'password' property corresponds to a plaintext password and will
      #   attempt to use it in place of secure_token_password if it not set.
      class MacUser < Chef::Resource::User
        unified_mode true

        provides :mac_user
        provides :user, platform: "mac_os_x"

        introduced "15.3"

        property :iterations, Integer,
          description: "The number of iterations for a password with a SALTED-SHA512-PBKDF2 shadow hash.",
          default: 57803, desired_state: false

        # Overload gid to set our default gid to 20, the macOS "staff" group.
        # We also allow a string group name here which we'll attempt to resolve
        # or create in the provider.
        property :gid, [Integer, String], description: "The numeric group identifier.", default: 20, coerce: ->(gid) do
          begin
            Integer(gid) # Try and coerce a group id string into an integer
          rescue
            gid # assume we have a group name
          end
        end

        # Overload the password so we can set a length requirements and update the
        # description.
        property :password, String, description: "The plain text user password", sensitive: true, coerce: ->(password) {
          # It would be nice if this could be in callbacks but we need the context
          # of the resource to get the salt property so we have to do it in coerce.
          if salt && password !~ /^[[:xdigit:]]{256}$/
            raise Chef::Exceptions::User, "Password must be a SALTED-SHA512-PBKDF2 shadow hash entropy when a shadow hash salt is given"
          end

          password
        },
        callbacks: {
          "Password length must be >= 4" => ->(password) { password.size >= 4 },
        }

        # Overload home so we set our default.
        property :home, String, description: "The user home directory", default: lazy { "/Users/#{name}" }

        property :admin, [TrueClass, FalseClass], description: "Create the user as an admin", default: false

        # Hide a user account in the macOS login window
        property :hidden, [TrueClass, FalseClass, nil], description: "Hide account from loginwindow and system preferences", default: nil, introduced: "15.8"

        # TCC on macOS >= 10.14 requires admin credentials of an Admin user that
        # has SecureToken enabled in order to toggle SecureToken.
        property :admin_username, String, description: "Admin username for superuser actions"
        property :admin_password, String, description: "Admin password for superuser actions", sensitive: true

        property :secure_token, [TrueClass, FalseClass], description: "Enable SecureToken for the user", default: false
        # In order to enable SecureToken for a user we require the plaintext password.
        property :secure_token_password, String, description: "The plaintext password for enabling SecureToken", sensitive: true, default: lazy {
          # In some cases the user can pass the plaintext value to "password" instead of
          # SALTED-SHA512-PBKDF2 entropy. In those cases we'll default to the
          # same value.
          (salt.nil? && password) ? password : nil
        }
      end
    end
  end
end
