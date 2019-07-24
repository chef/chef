#
# Author:: Ryan Cragun (<ryan@chef.io>)
# Copyright:: Copyright 2019, Chef Software Inc.
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
      #   use newer methods of creating, modifying and removing users.
      #
      # * Due to the tooling required by the provider this provider is only
      #   suitable for use on macOS >= 10.14. Support for older platforms has
      #   been removed.
      #
      # New Features:
      #
      # * Primary group management is now included.
      #
      # * 'admin' is now a boolean property that configures a user to an admin.
      #
      # * 'admin_username' and 'admin_password' are new properties that define the
      #   admin user credentials required for toggling SecureToken for an
      #   exiting user.
      #
      #   The 'admin_username' must correspond to a system admin with SecureToken
      #   enabled in order to toggle SecureToken.
      #
      # * 'secure_token' is a boolean property that sets the desired state
      #   for SecureToken. SecureToken token is required for FileVault full
      #   disk encryption.
      class MacUser < Chef::Resource::User
        resource_name :mac_user

        provides :mac_user
        provides :user, os: "darwin", platform_version: ">= 10.14"

        property :iterations, Integer,
          description: "macOS platform only. The number of iterations for a password with a SALTED-SHA512-PBKDF2 shadow hash.",
          default: 57803, desired_state: false

        # Overload gid so we can set our default. NilClass is for backwards compat
        # and 20 is the macOS "staff" group.
        property :gid, [String, Integer, NilClass], description: "The numeric group identifier.", default: 20, coerce: ->(gid) do
          begin
            return 20 if gid.nil?

            return Etc.getgrnam(gid).gid if gid.is_a?(String)

            Integer(gid)
          rescue
            gid
          end
        end

        # Overload the password so we can set a length requirements and update the
        # description.
        property :password, String, description: "The plain text user password", sensitive: true, callbacks: {
          "Password length must be >= 4" => ->(password) { password.size >= 4 },
        }

        # Overload home so we set our default.
        property :home, String, description: "The user home directory", default: lazy { "/Users/#{name}" }

        property :admin, [TrueClass, FalseClass], description: "Create the user as an admin", default: false

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
