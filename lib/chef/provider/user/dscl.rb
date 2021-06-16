#
# Author:: Dreamcat4 (<dreamcat4@gmail.com>)
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

require_relative "../../mixin/shell_out"
require_relative "../user"
require_relative "../../resource/user/dscl_user"
autoload :OpenSSL, "openssl"
autoload :Plist, "plist"
require_relative "../../util/path_helper"

class Chef
  class Provider
    class User
      #
      # The most tricky bit of this provider is the way it deals with user passwords.
      # macOS has different password shadow calculations based on the version.
      # < 10.7  => password shadow calculation format SALTED-SHA1
      #         => stored in: /var/db/shadow/hash/#{guid}
      #         => shadow binary length 68 bytes
      #         => First 4 bytes salt / Next 64 bytes shadow value
      # = 10.7  => password shadow calculation format SALTED-SHA512
      #         => stored in: /var/db/dslocal/nodes/Default/users/#{name}.plist
      #         => shadow binary length 68 bytes
      #         => First 4 bytes salt / Next 64 bytes shadow value
      # > 10.7  => password shadow calculation format SALTED-SHA512-PBKDF2
      #         => stored in: /var/db/dslocal/nodes/Default/users/#{name}.plist
      #         => shadow binary length 128 bytes
      #         => Salt / Iterations are stored separately in the same file
      #
      # This provider only supports macOS versions 10.7 to 10.13
      class Dscl < Chef::Provider::User

        attr_accessor :user_info
        attr_accessor :authentication_authority
        attr_accessor :password_shadow_conversion_algorithm

        provides :dscl_user
        provides :user, os: "darwin", platform_version: "<= 10.13"

        # Just-in-case a recipe calls the user dscl provider without specifying
        # a gid property. Avoids chown issues in move_home when the manage_home
        # property is in use. #5393
        STAFF_GROUP_ID = 20

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exist?("/usr/bin/dscl") }
            a.failure_message(Chef::Exceptions::User, "Cannot find binary '/usr/bin/dscl' on the system for #{new_resource}!")
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exist?("/usr/bin/plutil") }
            a.failure_message(Chef::Exceptions::User, "Cannot find binary '/usr/bin/plutil' on the system for #{new_resource}!")
          end

          requirements.assert(:create, :modify, :manage) do |a|
            a.assertion do
              if new_resource.password
                # SALTED-SHA512 password shadow hashes are not supported on 10.8 and above.
                !salted_sha512?(new_resource.password)
              else
                true
              end
            end
            a.failure_message(Chef::Exceptions::User, "SALTED-SHA512 passwords are not supported on Mac 10.8 and above. \
If you want to set the user password using shadow info make sure you specify a SALTED-SHA512-PBKDF2 shadow hash \
in 'password', with the associated 'salt' and 'iterations'.")
          end

          requirements.assert(:create, :modify, :manage) do |a|
            a.assertion do
              if new_resource.password && salted_sha512_pbkdf2?(new_resource.password)
                # salt and iterations should be specified when
                # SALTED-SHA512-PBKDF2 password shadow hash is given
                !new_resource.salt.nil? && !new_resource.iterations.nil?
              else
                true
              end
            end
            a.failure_message(Chef::Exceptions::User, "SALTED-SHA512-PBKDF2 shadow hash is given without associated \
'salt' and 'iterations'. Please specify 'salt' and 'iterations' in order to set the user password using shadow hash.")
          end
        end

        def load_current_resource
          @current_resource = Chef::Resource::User::DsclUser.new(new_resource.username)
          current_resource.username(new_resource.username)

          @user_info = read_user_info
          if user_info
            current_resource.uid(dscl_get(user_info, :uid))
            current_resource.gid(dscl_get(user_info, :gid))
            current_resource.home(dscl_get(user_info, :home))
            current_resource.shell(dscl_get(user_info, :shell))
            current_resource.comment(dscl_get(user_info, :comment))
            @authentication_authority = dscl_get(user_info, :auth_authority)

            if new_resource.password && dscl_get(user_info, :password) == "********"
              # A password is set. Let's get the password information from shadow file
              shadow_hash_binary = dscl_get(user_info, :shadow_hash)

              # Calling shell_out directly since we want to give an input stream
              shadow_hash_xml = convert_binary_plist_to_xml(shadow_hash_binary.string)
              shadow_hash = ::Plist.parse_xml(shadow_hash_xml)

              if shadow_hash["SALTED-SHA512-PBKDF2"] # 10.7+ contains this, but we retain the check in case it goes away in the future
                @password_shadow_conversion_algorithm = "SALTED-SHA512-PBKDF2"
                # Convert the entropy from Base64 encoding to hex before consuming them
                current_resource.password(shadow_hash["SALTED-SHA512-PBKDF2"]["entropy"].string.unpack("H*").first)
                current_resource.iterations(shadow_hash["SALTED-SHA512-PBKDF2"]["iterations"])
                # Convert the salt from Base64 encoding to hex before consuming them
                current_resource.salt(shadow_hash["SALTED-SHA512-PBKDF2"]["salt"].string.unpack("H*").first)
              else
                raise(Chef::Exceptions::User, "Unknown shadow_hash format: #{shadow_hash.keys.join(" ")}")
              end
            end

            convert_group_name if new_resource.gid
          else
            @user_exists = false
            logger.trace("#{new_resource} user does not exist")
          end

          current_resource
        end

        #
        # Provider Actions
        #

        def create_user
          dscl_create_user
          # set_password modifies the plist file of the user directly. So update
          # the password first before making any modifications to the user.
          set_password
          dscl_create_comment
          dscl_set_uid
          dscl_set_gid
          dscl_set_home
          dscl_set_shell
        end

        def manage_user
          # set_password modifies the plist file of the user directly. So update
          # the password first before making any modifications to the user.
          set_password        if diverged_password?
          dscl_create_user    if diverged?(:username)
          dscl_create_comment if diverged?(:comment)
          dscl_set_uid        if diverged?(:uid)
          dscl_set_gid        if diverged?(:gid)
          dscl_set_home       if diverged?(:home)
          dscl_set_shell      if diverged?(:shell)
        end

        #
        # Action Helpers
        #

        #
        # Create a user using dscl
        #
        def dscl_create_user
          run_dscl("create", "/Users/#{new_resource.username}")
        end

        #
        # Saves the specified Chef user `comment` into RealName attribute
        # of Mac user. If `comment` is not specified, it takes `username` value.
        #
        def dscl_create_comment
          comment = new_resource.comment || new_resource.username
          run_dscl("create", "/Users/#{new_resource.username}", "RealName", comment)
        end

        #
        # Sets the user id for the user using dscl.
        # If a `uid` is not specified, it finds the next available one starting
        # from 200 if `system` is set, 501 otherwise.
        #
        def dscl_set_uid
          # XXX: mutates the new resource
          new_resource.uid(get_free_uid) if new_resource.uid.nil? || new_resource.uid == ""

          if uid_used?(new_resource.uid)
            raise(Chef::Exceptions::RequestedUIDUnavailable, "uid #{new_resource.uid} is already in use")
          end

          run_dscl("create", "/Users/#{new_resource.username}", "UniqueID", new_resource.uid)
        end

        #
        # Find the next available uid on the system. starting with 200 if `system` is set,
        # 501 otherwise.
        #
        def get_free_uid(search_limit = 1000)
          uid = nil
          base_uid = new_resource.system ? 200 : 501
          next_uid_guess = base_uid
          users_uids = run_dscl("list", "/Users", "uid")
          while next_uid_guess < search_limit + base_uid
            if users_uids&.match?(Regexp.new("#{Regexp.escape(next_uid_guess.to_s)}\n"))
              next_uid_guess += 1
            else
              uid = next_uid_guess
              break
            end
          end
          uid || raise("uid not found. Exhausted. Searched #{search_limit} times")
        end

        #
        # Returns true if uid is in use by a different account, false otherwise.
        #
        def uid_used?(uid)
          return false unless uid

          users_uids = run_dscl("list", "/Users", "uid").split("\n")
          uid_map = users_uids.each_with_object({}) do |tuid, tmap|
            x = tuid.split
            tmap[x[1]] = x[0]
            tmap
          end
          if uid_map[uid.to_s]
            unless uid_map[uid.to_s] == new_resource.username
              return true
            end
          end
          false
        end

        #
        # Sets the group id for the user using dscl. Fails if a group doesn't
        # exist on the system with given group id. If `gid` is not specified, it
        # sets a default Mac user group "staff", with id 20 using the CONSTANT
        #
        def dscl_set_gid
          if new_resource.gid.nil?
            # XXX: mutates the new resource
            new_resource.gid(STAFF_GROUP_ID)
          elsif !new_resource.gid.to_s.match(/^\d+$/)
            begin
              possible_gid = run_dscl("read", "/Groups/#{new_resource.gid}", "PrimaryGroupID").split(" ").last
            rescue Chef::Exceptions::DsclCommandFailed
              raise Chef::Exceptions::GroupIDNotFound, "Group not found for #{new_resource.gid} when creating user #{new_resource.username}"
            end
            # XXX: mutates the new resource
            new_resource.gid(possible_gid) if possible_gid && possible_gid.match(/^\d+$/)
          end
          run_dscl("create", "/Users/#{new_resource.username}", "PrimaryGroupID", new_resource.gid)
        end

        #
        # Sets the home directory for the user. If `:manage_home` is set home
        # directory is managed (moved / created) for the user.
        #
        def dscl_set_home
          if new_resource.home.nil? || new_resource.home.empty?
            run_dscl("delete", "/Users/#{new_resource.username}", "NFSHomeDirectory")
            return
          end

          if new_resource.manage_home
            validate_home_dir_specification!

            if (current_resource.home == new_resource.home) && !new_home_exists?
              ditto_home
            elsif !current_home_exists? && !new_home_exists?
              ditto_home
            elsif current_home_exists?
              move_home
            end
          end
          run_dscl("create", "/Users/#{new_resource.username}", "NFSHomeDirectory", new_resource.home)
        end

        def validate_home_dir_specification!
          unless %r{^/}.match?(new_resource.home)
            raise(Chef::Exceptions::InvalidHomeDirectory, "invalid path spec for User: '#{new_resource.username}', home directory: '#{new_resource.home}'")
          end
        end

        def current_home_exists?
          !!current_resource.home && ::File.exist?(current_resource.home)
        end

        def new_home_exists?
          ::File.exist?(new_resource.home)
        end

        def ditto_home
          shell_out!("/usr/sbin/createhomedir", "-c", "-u", (new_resource.username).to_s)
        end

        def move_home
          logger.trace("#{new_resource} moving #{self} home from #{current_resource.home} to #{new_resource.home}")
          new_resource.gid(STAFF_GROUP_ID) if new_resource.gid.nil?
          src = current_resource.home
          FileUtils.mkdir_p(new_resource.home)
          files = ::Dir.glob("#{Chef::Util::PathHelper.escape_glob_dir(src)}/*", ::File::FNM_DOTMATCH) - ["#{src}/.", "#{src}/.."]
          ::FileUtils.mv(files, new_resource.home, force: true)
          ::FileUtils.rmdir(src)
          ::FileUtils.chown_R(new_resource.username, new_resource.gid.to_s, new_resource.home)
        end

        #
        # Sets the shell for the user using dscl.
        #
        def dscl_set_shell
          if new_resource.shell
            run_dscl("create", "/Users/#{new_resource.username}", "UserShell", new_resource.shell)
          else
            run_dscl("create", "/Users/#{new_resource.username}", "UserShell", "/usr/bin/false")
          end
        end

        #
        # Sets the password for the user based on given password parameters.
        # Chef supports specifying plain-text passwords and password shadow
        # hash data.
        #
        def set_password
          # Return if there is no password to set
          return if new_resource.password.nil?

          shadow_info = prepare_password_shadow_info

          # Shadow info is saved as binary plist. Convert the info to binary plist.
          shadow_info_binary = StringIO.new
          shell_out("plutil", "-convert", "binary1", "-o", "-", "-",
            input: shadow_info.to_plist, live_stream: shadow_info_binary)

          if user_info.nil?
            # User is  just created. read_user_info() will read the fresh information
            # for the user with a cache flush. However with experimentation we've seen
            # that dscl cache is not immediately updated after the creation of the user
            # This is odd and needs to be investigated further.
            sleep 3
            @user_info = read_user_info
          end

          # Replace the shadow info in user's plist
          dscl_set(user_info, :shadow_hash, shadow_info_binary)
          save_user_info(user_info)
        end

        #
        # Prepares the password shadow info based on the platform version.
        #
        def prepare_password_shadow_info
          shadow_info = {}
          entropy = nil
          salt = nil
          iterations = nil

          if salted_sha512_pbkdf2?(new_resource.password)
            entropy = convert_to_binary(new_resource.password)
            salt = convert_to_binary(new_resource.salt)
            iterations = new_resource.iterations
          else
            salt = OpenSSL::Random.random_bytes(32)
            iterations = new_resource.iterations # Use the default if not specified by the user

            entropy = OpenSSL::PKCS5.pbkdf2_hmac(
              new_resource.password,
              salt,
              iterations,
              128,
              OpenSSL::Digest.new("SHA512")
            )
          end

          pbkdf_info = {}
          pbkdf_info["entropy"] = StringIO.new
          pbkdf_info["entropy"].string = entropy
          pbkdf_info["salt"] = StringIO.new
          pbkdf_info["salt"].string = salt
          pbkdf_info["iterations"] = iterations

          shadow_info["SALTED-SHA512-PBKDF2"] = pbkdf_info
          shadow_info
        end

        #
        # Removes the user from the system after removing user from his groups
        # and deleting home directory if needed.
        #
        def remove_user
          if new_resource.manage_home
            # Remove home directory
            FileUtils.rm_rf(current_resource.home)
          end

          # Remove the user from its groups
          run_dscl("list", "/Groups").each_line do |group|
            if member_of_group?(group.chomp)
              run_dscl("delete", "/Groups/#{group.chomp}", "GroupMembership", new_resource.username)
            end
          end

          # Remove user account
          run_dscl("delete", "/Users/#{new_resource.username}")
        end

        #
        # Locks the user.
        #
        def lock_user
          run_dscl("append", "/Users/#{new_resource.username}", "AuthenticationAuthority", ";DisabledUser;")
        end

        #
        # Unlocks the user
        #
        def unlock_user
          auth_string = authentication_authority.gsub(/AuthenticationAuthority: /, "").gsub(/;DisabledUser;/, "").strip
          run_dscl("create", "/Users/#{new_resource.username}", "AuthenticationAuthority", auth_string)
        end

        #
        # Returns true if the user is locked, false otherwise.
        #
        def locked?
          if authentication_authority
            !!(authentication_authority.include?("DisabledUser"))
          else
            false
          end
        end

        #
        # This is the interface base User provider requires to provide idempotency.
        #
        def check_lock
          @locked = locked?
        end

        #
        # Helper functions
        #

        #
        # Returns true if the system state and desired state is different for
        # given attribute.
        #
        def diverged?(parameter)
          parameter_updated?(parameter) && !new_resource.send(parameter).nil?
        end

        def parameter_updated?(parameter)
          !(new_resource.send(parameter) == current_resource.send(parameter))
        end

        #
        # We need a special check function for password since we support both
        # plain text and shadow hash data.
        #
        # Checks if password needs update based on platform version and the
        # type of the password specified.
        #
        def diverged_password?
          return false if new_resource.password.nil?

          # Dscl provider supports both plain text passwords and shadow hashes.
          #
          # Some system users don't have salts; this can happen if the system is
          # upgraded and the user hasn't logged in yet. In this case, we will force
          # the password to be updated.
          return true if current_resource.salt.nil?

          if salted_sha512_pbkdf2?(new_resource.password)
            diverged?(:password) || diverged?(:salt) || diverged?(:iterations)
          else
            !salted_sha512_pbkdf2_password_match?
          end
        end

        #
        # Returns true if user is member of the specified group, false otherwise.
        #
        def member_of_group?(group_name)
          membership_info = ""
          begin
            membership_info = run_dscl("read", "/Groups/#{group_name}")
          rescue Chef::Exceptions::DsclCommandFailed
            # Raised if the group doesn't contain any members
          end
          # Output is something like:
          # GroupMembership: root admin etc
          members = membership_info.split(" ")
          members.shift # Get rid of GroupMembership: string
          members.include?(new_resource.username)
        end

        #
        # DSCL Helper functions
        #

        # A simple map of Chef's terms to DSCL's terms.
        DSCL_PROPERTY_MAP = {
          uid: "uid",
          gid: "gid",
          home: "home",
          shell: "shell",
          comment: "realname",
          password: "passwd",
          auth_authority: "authentication_authority",
          shadow_hash: "ShadowHashData",
        }.freeze

        # Directory where the user plist files are stored for versions 10.7 and above
        USER_PLIST_DIRECTORY = "/var/db/dslocal/nodes/Default/users".freeze

        #
        # Reads the user plist and returns a hash keyed with DSCL properties specified
        # in DSCL_PROPERTY_MAP. Return nil if the user is not found.
        #
        def read_user_info
          user_info = nil

          # We flush the cache here in order to make sure that we read fresh information
          # for the user.
          shell_out("dscacheutil", "-flushcache") # FIXME: this is macOS version dependent

          begin
            user_plist_file = "#{USER_PLIST_DIRECTORY}/#{new_resource.username}.plist"
            user_plist_info = run_plutil("convert", "xml1", "-o", "-", user_plist_file)
            user_info = ::Plist.parse_xml(user_plist_info)
          rescue Chef::Exceptions::PlistUtilCommandFailed
          end

          user_info
        end

        #
        # Saves the given hash keyed with DSCL properties specified
        # in DSCL_PROPERTY_MAP to the disk.
        #
        def save_user_info(user_info)
          user_plist_file = "#{USER_PLIST_DIRECTORY}/#{new_resource.username}.plist"
          ::Plist::Emit.save_plist(user_info, user_plist_file)
          run_plutil("convert", "binary1", user_plist_file)
        end

        #
        # Sets a value in user information hash using Chef attributes as keys.
        #
        def dscl_set(user_hash, key, value)
          raise "Unknown dscl key #{key}" unless DSCL_PROPERTY_MAP.key?(key)

          user_hash[DSCL_PROPERTY_MAP[key]] = [ value ]
          user_hash
        end

        #
        # Gets a value from user information hash using Chef attributes as keys.
        #
        def dscl_get(user_hash, key)
          raise "Unknown dscl key #{key}" unless DSCL_PROPERTY_MAP.key?(key)

          # DSCL values are set as arrays
          value = user_hash[DSCL_PROPERTY_MAP[key]]
          value.nil? ? value : value.first
        end

        #
        # System Helpers
        #

        def run_dscl(*args)
          result = shell_out("dscl", ".", "-#{args[0]}", args[1..])
          return "" if ( args.first =~ /^delete/ ) && ( result.exitstatus != 0 )
          raise(Chef::Exceptions::DsclCommandFailed, "dscl error: #{result.inspect}") unless result.exitstatus == 0
          raise(Chef::Exceptions::DsclCommandFailed, "dscl error: #{result.inspect}") if result.stdout.include?("No such key: ")

          result.stdout
        end

        def run_plutil(*args)
          result = shell_out("plutil", "-#{args[0]}", args[1..])
          raise(Chef::Exceptions::PlistUtilCommandFailed, "plutil error: #{result.inspect}") unless result.exitstatus == 0

          if result.stdout.encoding == Encoding::ASCII_8BIT
            result.stdout.encode("utf-8", "binary", undef: :replace, invalid: :replace, replace: "?")
          else
            result.stdout
          end
        end

        def convert_binary_plist_to_xml(binary_plist_string)
          shell_out("plutil", "-convert", "xml1", "-o", "-", "-", input: binary_plist_string).stdout
        end

        def convert_to_binary(string)
          string.unpack("a2" * (string.size / 2)).collect { |i| i.hex.chr }.join
        end

        def salted_sha512?(string)
          !!(string =~ /^[[:xdigit:]]{136}$/)
        end

        def salted_sha512_pbkdf2?(string)
          !!(string =~ /^[[:xdigit:]]{256}$/)
        end

        def salted_sha512_pbkdf2_password_match?
          salt = convert_to_binary(current_resource.salt)

          OpenSSL::PKCS5.pbkdf2_hmac(
            new_resource.password,
            salt,
            current_resource.iterations,
            128,
            OpenSSL::Digest.new("SHA512")
          ).unpack("H*").first == current_resource.password
        end

      end
    end
  end
end
