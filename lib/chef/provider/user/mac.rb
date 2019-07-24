#
# Author:: Ryan Cragun (<ryan@chef.io>)
# Copyright:: Copyright (c) 2019, Chef Software Inc.
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

require_relative "../../resource"
require_relative "../../dsl/declare_resource"
require_relative "../../mixin/shell_out"
require_relative "../../mixin/which"
require_relative "../user"
require_relative "../../resource/user/mac_user"

class Chef
  class Provider
    class User
      # A macOS user provider that is compatible with default TCC restrictions
      # in macOS >= 10.14. See resource/user/mac_user.rb for complete description
      # of the mac_user resource and how it differs from the dscl resource used
      # on previous platforms.
      class MacUser < Chef::Provider::User
        include Chef::Mixin::Which

        provides :mac_user
        provides :user, os: "darwin", platform_version: ">= 10.14"

        attr_accessor :auth_authority, :guid, :user_plist

        DSCL_PROPERTY_MAP = {
            uid: "dsAttrTypeStandard:UniqueID",
            guid: "dsAttrTypeStandard:GeneratedUID",
            gid: "dsAttrTypeStandard:PrimaryGroupID",
            home: "dsAttrTypeStandard:NFSHomeDirectory",
            shell: "dsAttrTypeStandard:UserShell",
            comment: "dsAttrTypeStandard:RealName",
            password: "dsAttrTypeStandard:Password",
            auth_authority: "dsAttrTypeStandard:AuthenticationAuthority",
            shadow_hash: "dsAttrTypeNative:ShadowHashData",
            group_members: "dsAttrTypeStandard:GroupMembers",
        }.freeze

        def define_resource_requirements
          super

          %w{dscl sysadminctl plutil dsimport}.each do |bin|
            requirements.assert(:all_actions) do |a|
              a.assertion { which(bin) }
              a.failure_message(Chef::Exceptions::User, "Cannot find binary '#{bin}' on the system for #{new_resource}!")
            end
          end

          requirements.assert(:all_actions) do |a|
            a.assertion do
              if new_resource.property_is_set?(:salt)
                new_resource.property_is_set?(:iterations) && new_resource.password =~ /^[[:xdigit:]]{256}$/
              else
                true
              end
            end
            a.failure_message(Chef::Exceptions::User, "Password must be a SALTED-SHA512-PBKDF2 shadow hash entropy when a shadow hash salt is given")
          end
        end

        def load_current_resource
          convert_group_name if new_resource.property_is_set?(:gid)

          @current_resource = Chef::Resource::User::MacUser.new(new_resource.username)
          current_resource.username(new_resource.username)

          @user_plist = load_user
          if user_plist
            reload_with_user_plist
          else
            @user_exists = false
            logger.trace("#{new_resource} user does not exist")
          end

          current_resource
        end

        def load_user
          # Load the user information.
          user_xml = run_dscl("read", "/Users/#{new_resource.username}")

          # User doesn't exist yet so there's not info
          return nil if user_xml.nil? || user_xml == ""

          user_plist = Plist.parse_xml(user_xml)

          # The password infomation is stored in the ShadowHashData key in the
          # plist. However, parsing it is a bit tricky as the value is itself
          # another encoded binary plist. We have to extract the encoded plist,
          # decode it from hex to a binary plist and then convert the binary
          # into XML plist. From there we can extract the hash data.
          #
          # NOTE: `dscl -read` and `plutil -convert` return different values for ShadowHashData.
          #
          # `dscl` returns the value encoded as an octal hex string and stored as a <string>
          # `plutil` returns the value encoded as a base64 string stored as <data>
          #
          #  eg:
          #
          # <array>
          #   <string>77687920 63616e27 74206170 706c6520 6275696c 6420636f 6e736973 74656e74 20746f6f 6c696e67</string>
          # </array>
          #
          # vs
          #
          # <array>
          #   <data>AADKAAAKAA4LAA0MAAAAAAAAAAA=</data>
          # </array>
          #
          shadow_hash_hex = dscl_get(user_plist, :shadow_hash)[0]

          return user_plist unless shadow_hash_hex && shadow_hash_hex != ""

          shadow_binary_plist = [shadow_hash_hex.delete(" ")].pack("H*")
          shadow_xml_plist = shell_out("plutil", "-convert", "xml1", "-o", "-", "-", input: shadow_binary_plist).stdout
          dscl_set(user_plist, :shadow_hash, Plist.parse_xml(shadow_xml_plist))

          user_plist
        rescue Chef::Exceptions::PlistUtilCommandFailed, Chef::Exceptions::DsclCommandFailed
          nil
        end

        # Map updated user information from the user_plist onto the current resource
        # and instance variables.
        def reload_with_user_plist
          current_resource.uid(dscl_get(user_plist, :uid)[0])
          current_resource.gid(dscl_get(user_plist, :gid)[0])
          current_resource.home(dscl_get(user_plist, :home)[0])
          current_resource.shell(dscl_get(user_plist, :shell)[0])
          current_resource.comment(dscl_get(user_plist, :comment)[0])

          shadow_hash = dscl_get(user_plist, :shadow_hash)
          if shadow_hash
            current_resource.password(shadow_hash[0]["SALTED-SHA512-PBKDF2"]["entropy"].string.unpack("H*")[0])
            current_resource.salt(shadow_hash[0]["SALTED-SHA512-PBKDF2"]["salt"].string.unpack("H*")[0])
            current_resource.iterations(shadow_hash[0]["SALTED-SHA512-PBKDF2"]["iterations"].to_i)
          end

          @auth_authority = dscl_get(user_plist, :auth_authority)
          @guid = dscl_get(user_plist, :guid)
          @admin_group_info = nil

          current_resource.secure_token(secure_token_enabled?)
          current_resource.admin(admin_user?)
        end

        #
        # User Provider Callbacks
        #

        def create_user
          cmd = [-"-addUser", new_resource.username]
          cmd += ["-fullName", new_resource.comment]  if new_resource.property_is_set?(:comment)
          cmd += ["-UID", new_resource.uid]           if new_resource.property_is_set?(:uid)
          cmd += ["-shell", new_resource.shell]       if new_resource.property_is_set?(:shell)
          cmd += ["-home", new_resource.home]         if new_resource.property_is_set?(:home)
          cmd += ["-admin"]                           if new_resource.admin

          # We can technically create a new user without the admin credentials
          # but without them the user cannot enable SecureToken, thus they cannot
          # create other secure users or enable FileVault full disk encryption.
          if new_resource.property_is_set?(:admin_username) && new_resource.property_is_set?(:admin_password)
            cmd += ["-adminUser", new_resource.admin_username]
            cmd += ["-adminPassword", new_resource.admin_password]
          end

          # sysadminctl doesn't exit with a non-zero exit code if it encounters
          # a problem. We'll check stderr and make sure we see that it finished
          # correctly.
          res = run_sysadminctl(cmd)
          unless res.downcase =~ /creating user/
            raise Chef::Exceptions::User, "error when creating user: #{res}"
          end

          # Wait for the user to be created and for dscl to flush everything
          sleep 3

          # Reload with up-to-date user information
          @user_plist = load_user
          reload_with_user_plist

          converge_by("set password") { set_password } if new_resource.property_is_set?(:password)

          if new_resource.manage_home
            # "sydadminctl -addUser" will create the home directory if it's
            # the default /Users/<username>, otherwise it sets it in plist
            # but does not create it. Here we'll ensure that it gets created
            # if we've been given a directory that is not the default.
            unless ::File.directory?(new_resource.home) && ::File.exist?(new_resource.home)
              converge_by("create home directory") do
                shell_out!("createhomedir -c -u #{new_resource.username}")
              end
            end
          end

          if new_resource.property_is_set?(:gid)
            # NOTE: Here we're managing the primary group of the user which is
            # a departure from previous behavior. We could just set the
            # PrimaryGroupID for the user and move on if we decide that actual
            # group magement should be done outside of the core resource.
            group_name, group_id, group_action = user_group_info

            declare_resource(:group, group_name) do
              members new_resource.username
              gid group_id if group_id
              action group_action
              append true
            end

            converge_by("create primary group ID") do
              run_dscl("create", "/Users/#{new_resource.username}", "PrimaryGroupID", new_resource.gid)
            end
          end

          converge_by("alter SecureToken") { toggle_secure_token } if diverged?(:secure_token)

          @user_exists = true
        end

        def compare_user
          %i{comment shell uid gid salt password admin secure_token}.each do |m|
            return true if diverged?(m)
          end

          false
        end

        def manage_user
          %i{uid home}.each do |prop|
            raise Chef::Exceptions::User, "cannot modify #{prop} on macOS >= 10.14" if diverged?(prop)
          end

          converge_by("alter password") { set_password } if diverged?(:password)

          if diverged?(:comment)
            converge_by("alter comment") do
              run_dscl("create", "/Users/#{new_resource.username}", "RealName", new_resource.comment)
            end
          end

          if diverged?(:shell)
            converge_by("alter shell") do
              run_dscl("create", "/Users/#{new_resource.username}", "UserShell", new_resource.shell)
            end
          end

          converge_by("alter SecureToken") { toggle_secure_token } if diverged?(:secure_token)

          if diverged?(:admin)
            converge_by("alter admin group membership") do
              declare_resource(:group, "admin") do
                if new_resource.admin
                  members new_resource.username
                else
                  excluded_members new_resource.username
                end

                action :create
                append true
              end

              admins = dscl_get(admin_group_info, :group_members)
              if new_resource.admin
                admins << guid[0]
              else
                admins.reject! { |m| m == guid[0] }
              end

              run_dscl("create", "/Groups/admin", "GroupMembers", admins)

              @admin_group_info = nil
            end
          end

          group_name, group_id, group_action = user_group_info
          declare_resource(:group, group_name) do
            gid group_id if group_id
            members new_resource.username
            action group_action
            append true
          end

          if diverged?(:gid)
            converge_by("alter group membership") do
              run_dscl("create", "/Users/#{new_resource.username}", "PrimaryGroupID", new_resource.gid)
            end
          end
        end

        def remove_user
          cmd = ["-deleteUser", new_resource.username]
          cmd << new_resource.manage_home ? "-secure" : "-keepHome"
          if new_resource.property_is_set?(:admin_username) && new_resource.property_is_set?(:admin_password)
            cmd += ["-adminUser", new_resource.admin_username]
            cmd += ["-adminPassword", new_resource.admin_password]
          end

          # sysadminctl doesn't exit with a non-zero exit code if it encounters
          # a problem. We'll check stdout and make sure we see that it finished
          res = run_sysadminctl(cmd)
          unless res.downcase =~ /deleting record|not found/
            raise Chef::Exceptions::User, "error deleting user: #{res}"
          end

          @user_exists = false
        end

        def lock_user
          run_dscl("append", "/Users/#{new_resource.username}", "AuthenticationAuthority", ";DisabledUser;")
        end

        def unlock_user
          auth_string = auth_authority.reject! { |tag| tag == ";DisabledUser;" }.join.strip
          run_dscl("create", "/Users/#{new_resource.username}", "AuthenticationAuthority", auth_string)
        end

        def locked?
          if auth_authority
            auth_authority.any? { |tag| tag == ";DisabledUser;" }
          else
            false
          end
        end

        def check_lock
          @locked = locked?
        end

        #
        # Methods
        #

        def diverged?(prop)
          prop = prop.to_sym

          if prop == :password
            return password_diverged?
          elsif prop == :gid
            return user_group_diverged?
          end

          # Other fields are have been set on current resource so just compare
          # them.
          new_resource.property_is_set?(prop) && (new_resource.send(prop) != current_resource.send(prop))
        end

        def user_group_info
          @user_group_info ||= begin
            if new_resource.gid.is_a?(String)
              begin
                g = Etc.getgrnam(new_resource.gid)
                [g.name, g.gid.to_s, :modify]
              rescue
                [new_resource.gid, nil, :create]
              end
            else
              begin
                g = Etc.getgrgid(new_resource.gid)
                [g.name, g.gid.to_s, :modify]
              rescue
                [g.username, nil, :create]
              end
            end
          end
        end

        def secure_token_enabled?
          if auth_authority
            auth_authority.any? { |tag| tag == ";SecureToken;" }
          else
            false
          end
        end

        def toggle_secure_token
          # Check for this lazily as we only need to validate for these credentials
          # if we're toggling secure token.
          unless new_resource.property_is_set?(:admin_username) &&
              new_resource.property_is_set?(:admin_password) &&
              # property_is_set? can't handle a default inherited from password
              # when not using shadow hash data. Hence, we'll just have to
              # make sure some valid string is there.
              new_resource.secure_token_password &&
              new_resource.secure_token_password != ""
            raise Chef::Exceptions::User, "secure_token_password, admin_user and admin_password properties are required to modify SecureToken"
          end

          cmd = (new_resource.secure_token ? %w{-secureTokenOn} : %w{-secureTokenOff})
          cmd += [new_resource.username, "-password", new_resource.secure_token_password]
          cmd += ["-adminUser", new_resource.admin_username]
          cmd += ["-adminPassword", new_resource.admin_password]

          # sysadminctl doesn't exit with a non-zero exit code if it encounters
          # a problem. We'll check stdout and make sure we see that it finished
          res = run_sysadminctl(cmd)
          unless res.downcase =~ /done/
            raise Chef::Exceptions::User, "error when modifying SecureToken: #{res}"
          end

          # HACK: When SecureToken is enabled or disabled it requires the user
          # password in plaintext, which it verifies and uses as a key. It also
          # takes the liberty of _rehashing_ the password with a random salt and
          # iterations count and saves it back into the user ShadowHashData.
          #
          # Therefore, if we're configuring a user based upon an existing shadow
          # hash data we'll have to set the password again so that future runs
          # of the client don't show password drift.
          set_password if new_resource.property_is_set?(:salt)
        end

        def user_group_diverged?
          return false unless new_resource.property_is_set?(:gid)

          _, group_id = user_group_info

          current_resource.gid != group_id
        end

        def password_diverged?
          # There are three options for configuring the password:
          #   * ShadowHashData which includes the hash data as:
          #     * hashed entropy as the "password"
          #     * salt
          #     * iterations
          #   * Plaintext password
          #   * Not configuring it

          # Check for no desired password configuration
          return false unless new_resource.property_is_set?(:password)

          # Check for ShadowHashData divergence by comparing the entropy,
          # salt, and iterations.
          if new_resource.property_is_set?(:salt)
            return true if %i{salt iterations}.any? { |prop| diverged?(prop) }

            return new_resource.password != current_resource.password
          end

          # Check for plaintext password divergence. We don't actually know
          # what the stored password is but we can hash the given password with
          # stored salt and iterations, and compare the resulting entropy with
          # the saved entropy.
          OpenSSL::PKCS5.pbkdf2_hmac(
            new_resource.password,
            convert_to_binary(current_resource.salt),
            current_resource.iterations.to_i,
            128,
            OpenSSL::Digest::SHA512.new
          ).unpack("H*")[0] != current_resource.password
        end

        def admin_user?
          return false unless admin_group_info

          dscl_get(admin_group_info, :group_members).any? { |mem| mem == guid[0] }
        end

        def admin_group_info
          @admin_group_info ||= begin
            admin_group_xml = run_dscl("read", "/Groups/admin")
            return nil unless admin_group_xml && admin_group_xml != ""

            Plist.parse_xml(admin_group_xml)
          end
        end

        def convert_to_binary(string)
          string.unpack("a2" * (string.size / 2)).collect { |i| i.hex.chr }.join
        end

        def set_password
          if new_resource.property_is_set?(:salt)
            entropy = StringIO.new(convert_to_binary(new_resource.password))
            salt = StringIO.new(convert_to_binary(new_resource.salt))
          else
            salt = StringIO.new(OpenSSL::Random.random_bytes(32))
            entropy = StringIO.new(
              OpenSSL::PKCS5.pbkdf2_hmac(
                new_resource.password,
                salt.string,
                new_resource.iterations,
                128,
                OpenSSL::Digest::SHA512.new
              )
            )
          end

          shadow_hash = dscl_get(user_plist, :shadow_hash)[0]
          shadow_hash["SALTED-SHA512-PBKDF2"] = {
            "entropy" => entropy,
            "salt" => salt,
            "iterations" => new_resource.iterations,
          }

          shadow_hash_binary = StringIO.new
          shell_out("plutil", "-convert", "binary1", "-o", "-", "-",
            input: shadow_hash.to_plist,
            live_stream: shadow_hash_binary)

          # Apple seem to have killed their dsimport documentation about the
          # dsimport record format. Perhaps that means our days of being able to
          # use dsimport without an admin password or perhaps at all could be
          # numbered. Here is the record format for posterity:
          #
          # End of record character
          # Escape character
          # Field separator
          # Value separator
          # Record type (Users, Groups, Computers, ComputerGroups, ComputerLists)
          # Number of properties
          # Property 1
          # ...
          # Property N
          #
          # The user password shadow data format breaks down as:
          #
          # 0x0A                                    End of record denoted by \n
          # 0x5C                                    Escaping is denoted by \
          # 0x3A                                    Fields are separated by :
          # 0x2C                                    Values are seperated by ,
          # dsRecTypeStandard:Users                 The record type we're configuring
          # 2                                       How many properties we're going to set
          # dsAttrTypeStandard:RecordName           Property 1: our users record name
          # base64:dsAttrTypeNative:ShadowHashData  Property 2: our shadow hash data

          import_file = ::File.join(Chef::Config["file_cache_path"], "#{new_resource.username}_password_dsimport")
          ::File.open(import_file, "w+", 0600) do |f|
            f.write <<~DSIMPORT
              0x0A 0x5C 0x3A 0x2C dsRecTypeStandard:Users 2 dsAttrTypeStandard:RecordName base64:dsAttrTypeNative:ShadowHashData
              #{new_resource.username}:#{::Base64.strict_encode64(shadow_hash_binary.string)}
            DSIMPORT
          end

          run_dscl("delete", "/Users/#{new_resource.username}", "ShadowHashData")
          run_dsimport(import_file, "/Local/Default", "M")
          run_dscl("create", "/Users/#{new_resource.username}", "Password", "********")
        ensure
          ::File.delete(import_file) if defined?(import_file) && ::File.exist?(import_file)
        end

        def run_dsimport(*args)
          shell_out!("dsimport", *(args.compact))
        end

        # Gets a value from user information hash using Chef attributes as keys.
        #
        def dscl_get(user_hash, key)
          raise "Unknown dscl key #{key}" unless DSCL_PROPERTY_MAP.keys.include?(key)

          user_hash[DSCL_PROPERTY_MAP[key]]
        end

        #
        # Sets a value in user information hash using Chef attributes as keys.
        #
        def dscl_set(user_hash, key, value)
          raise "Unknown dscl key #{key}" unless DSCL_PROPERTY_MAP.keys.include?(key)

          user_hash[DSCL_PROPERTY_MAP[key]] = [ value ]
          user_hash
        end

        def run_sysadminctl(args)
          # sysadminctl doesn't exit with a non-zero code when errors are encountered
          # and ouputs everything to STDERR instead of STDOUT and STDERR. Therefore we'll
          # return the STDERR and let the caller handle it.
          shell_out("sysadminctl", args).stderr
        end

        def run_dscl(*args)
          result = shell_out("dscl", "-plist", ".", "-#{args[0]}", args[1..-1])
          return "" if ( args.first =~ /^delete/ ) && ( result.exitstatus != 0 )
          raise(Chef::Exceptions::DsclCommandFailed, "dscl error: #{result.inspect}") unless result.exitstatus == 0
          raise(Chef::Exceptions::DsclCommandFailed, "dscl error: #{result.inspect}") if result.stdout =~ /No such key: /

          result.stdout
        end

        def run_plutil(*args)
          result = shell_out("plutil", "-#{args[0]}", args[1..-1])
          raise(Chef::Exceptions::PlistUtilCommandFailed, "plutil error: #{result.inspect}") unless result.exitstatus == 0

          if result.stdout.encoding == Encoding::ASCII_8BIT
            result.stdout.encode("utf-8", "binary", undef: :replace, invalid: :replace, replace: "?")
          else
            result.stdout
          end
        end
      end
    end
  end
end
