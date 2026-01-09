#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "tmpdir" unless defined?(Dir.mktmpdir)
module Addressable
  autoload :URI, "addressable/uri"
end

class Chef
  class Resource
    class AptRepository < Chef::Resource

      provides(:apt_repository, target_mode: true) { true }
      target_mode support: :full

      description "Use the **apt_repository** resource to specify additional APT repositories. Adding a new repository will update the APT package cache immediately."
      introduced "12.9"

      examples <<~DOC
        **Add repository with basic settings**:

        ```ruby
        apt_repository 'nginx' do
          uri        'http://nginx.org/packages/ubuntu/'
          components ['nginx']
        end
        ```

        **Enable Ubuntu multiverse repositories**:

        ```ruby
        apt_repository 'security-ubuntu-multiverse' do
          uri          'http://security.ubuntu.com/ubuntu'
          distribution 'xenial-security'
          components   ['multiverse']
          deb_src      true
        end
        ```

        **Add the Nginx PPA, autodetect the key and repository url**:

        ```ruby
        apt_repository 'nginx-php' do
          uri          'ppa:nginx/stable'
        end
        ```

        **Add the JuJu PPA, grab the key from the Ubuntu keyserver, and add source repo**:

        ```ruby
        apt_repository 'juju' do
          uri 'ppa:juju/stable'
          components ['main']
          distribution 'xenial'
          key 'C8068B11'
          action :add
          deb_src true
        end
        ```

        **Add repository that requires multiple keys to authenticate packages**:

        ```ruby
        apt_repository 'rundeck' do
          uri 'https://dl.bintray.com/rundeck/rundeck-deb'
          distribution '/'
          key ['379CE192D401AB61', 'http://rundeck.org/keys/BUILD-GPG-KEY-Rundeck.org.key']
          keyserver 'keyserver.ubuntu.com'
          action :add
        end
        ```

        **Add the Cloudera Repo of CDH4 packages for Ubuntu 16.04 on AMD64**:

        ```ruby
        apt_repository 'cloudera' do
          uri          'http://archive.cloudera.com/cdh4/ubuntu/xenial/amd64/cdh'
          arch         'amd64'
          distribution 'xenial-cdh4'
          components   ['contrib']
          key          'http://archive.cloudera.com/debian/archive.key'
        end
        ```

        **Add repository that needs custom options**:
        ```ruby
        apt_repository 'corretto' do
          uri          'https://apt.corretto.aws'
          arch         'amd64'
          distribution 'stable'
          components   ['main']
          options      ['target-=Contents-deb']
          key          'https://apt.corretto.aws/corretto.key'
        end
        ```

        **Remove a repository from the list**:

        ```ruby
        apt_repository 'zenoss' do
          action :remove
        end
        ```
      DOC

      # There's a pile of [ String, nil, FalseClass ] types in these properties.
      # This goes back to Chef 12 where String didn't default to nil and we had to do
      # it ourself, which required allowing that type as well. We've cleaned up the
      # defaults, but since we allowed users to pass nil here we need to continue
      # to allow that so don't refactor this however tempting it is
      property :repo_name, String,
        regex: [%r{^[^/]+$}],
        coerce: proc { |x| x.gsub(" ", "-") },
        description: "An optional property to set the repository name if it differs from the resource block's name. The value of this setting must not contain spaces.",
        validation_message: "repo_name property cannot contain a forward slash '/'",
        introduced: "14.1", name_property: true

      property :uri, String,
        description: "The base of the Debian distribution."

      property :distribution, [ String, nil, FalseClass ],
        description: "Usually a distribution's codename, such as `xenial`, `bionic`, or `focal`.",
        default: lazy { node["lsb"]["codename"] }, default_description: "The LSB codename of the node such as 'focal'."

      property :components, Array,
        description: "Package groupings, such as 'main' and 'stable'.",
        default: [], default_description: "`main` if using a PPA repository."

      property :arch, [String, nil, FalseClass],
        description: "Constrain packages to a particular CPU architecture such as `i386` or `amd64`."

      property :trusted, [TrueClass, FalseClass],
        description: "Determines whether you should treat all packages from this repository as authenticated regardless of signature.",
        default: false

      property :deb_src, [TrueClass, FalseClass],
        description: "Determines whether or not to add the repository as a source repo as well.",
        default: false

      property :keyserver, [String, nil, FalseClass],
        description: "The GPG keyserver where the key for the repo should be retrieved.",
        default: "keyserver.ubuntu.com"

      property :key, [String, Array, nil, FalseClass],
        description: "If a keyserver is provided, this is assumed to be the fingerprint; otherwise it can be either the URI of GPG key for the repo, or a cookbook_file.",
        default: [], coerce: proc { |x| x ? Array(x) : x }

      property :key_proxy, [String, nil, FalseClass],
        description: "If set, a specified proxy is passed to GPG via `http-proxy=`."

      property :signed_by, [String, true, false, nil],
        description: "If a string, specify the file and/or fingerprint the repo is signed with. If true, set Signed-With to use the specified key",
        default: true

      property :cookbook, [String, nil, FalseClass],
        description: "If key should be a cookbook_file, specify a cookbook where the key is located for files/default. Default value is nil, so it will use the cookbook where the resource is used.",
        desired_state: false

      property :cache_rebuild, [TrueClass, FalseClass],
        description: "Determines whether to rebuild the APT package cache.",
        default: true, desired_state: false

      property :options, [String, Array],
        description: "Additional options to set for the repository",
        default: [], coerce: proc { |x| Array(x) }

      default_action :add
      allowed_actions :add, :remove

      action_class do
        LIST_APT_KEY_FINGERPRINTS = %w{apt-key adv --list-public-keys --with-fingerprint --with-colons}.freeze

        # is the provided ID a key ID from a keyserver. Looks at length and HEX only values
        # @param [String] id the key value passed by the user that *may* be an ID
        def is_key_id?(id)
          id = id[2..] if id.start_with?("0x")
          id =~ /^\h+$/ && [8, 16, 40].include?(id.length)
        end

        # run the specified command and extract the fingerprints from the output
        # accepts a command so it can be used to extract both the current key's fingerprints
        # and the fingerprint of the new key
        # @param [Array<String>] cmd the command to run
        #
        # @return [Array] an array of fingerprints
        def extract_fingerprints_from_cmd(*cmd)
          so = shell_out(*cmd)
          so.stdout.split("\n").map do |t|
            if z = t.match(/^fpr:+([0-9A-F]+):/)
              z[1].split.join
            end
          end.compact
        end

        # run the specified command and extract the public key ids
        # accepts the command so it can be used to extract both the current keys
        # and the new keys
        # @param [Array<String>] cmd the command to run
        #
        # @return [Array] an array of key ids
        def extract_public_keys_from_cmd(*cmd)
          so = shell_out(*cmd)
          # Sample output
          # pub:-:4096:1:D94AA3F0EFE21092:1336774248:::-:::scSC::::::23::0:
          so.stdout.split("\n").map do |t|
            if t.match(/^pub:/)
              f = t.split(":")
              f.slice(0, 6).join(":")
            end
          end.compact
        end

        # validate the key against the apt keystore to see if that version is expired
        # @param [String] key
        #
        # @return [Boolean] is the key valid or not
        def key_is_valid?(key)
          valid = shell_out("apt-key", "list").stdout.each_line.none?(%r{^\/#{key}.*\[expired: .*\]$})

          logger.debug "key #{key} #{valid ? "is valid" : "is not valid"}"
          valid
        end

        # validate the key against the gpg keyring to see if that version is expired or revoked
        # @param [String] key
        # @param [String] keyring
        #
        # @return [Boolean] if the key valid or not
        def keyring_key_is_valid?(keyring, key)
          out = shell_out("gpg", "--no-default-keyring", "--keyring", keyring, "--list-public-keys", key)
          valid = out.exitstatus == 0 && out.stdout.each_line.none?(/\[(expired|revoked):/)

          logger.debug "key #{key} #{valid ? "is valid" : "is not valid"}"
          valid
        end

        # validate the key against the gpg keyring to see if the key is present
        # @param [String] key
        # @param [String] keyring
        #
        # @return [Boolean] if the key present
        def keyring_key_is_present?(keyring, key)
          shell_out(*%W{gpg --no-default-keyring --keyring #{keyring} --list-public-keys --with-fingerprint --with-colons #{key}}).exitstatus == 0
        end

        # return the specified cookbook name or the cookbook containing the
        # resource.
        #
        # @return [String] name of the cookbook
        def cookbook_name
          new_resource.cookbook || new_resource.cookbook_name
        end

        # determine if a cookbook file is available in the run
        # @param [String] fn the path to the cookbook file
        #
        # @return [Boolean] cookbook file exists or doesn't
        def has_cookbook_file?(fn)
          run_context.has_cookbook_file_in_cookbook?(cookbook_name, fn)
        end

        # determine if there are any new keys by comparing the fingerprints of installed
        # keys to those of the passed file
        # @param [String] file the keyfile of the new repository
        #
        # @return [Boolean] true: no new keys in the file. false: there are new keys
        def no_new_keys?(file)
          # Now we are using the option --with-colons that works across old os versions
          # as well as the latest (16.10). This for both `apt-key` and `gpg` commands
          installed_keys = extract_public_keys_from_cmd(*LIST_APT_KEY_FINGERPRINTS)
          proposed_keys = extract_public_keys_from_cmd("gpg", "--with-fingerprint", "--with-colons", file)
          (installed_keys & proposed_keys).sort == proposed_keys.sort
        end

        # Given the provided key URI determine what kind of chef resource we need
        # to fetch the key
        # @param [String] uri the uri of the gpg key (local path or http URL)
        #
        # @raise [Chef::Exceptions::FileNotFound] Key isn't remote or found in the current run
        #
        # @return [Symbol] :remote_file or :cookbook_file
        def key_resource_type(uri)
          if uri.start_with?("http")
            :remote_file
          elsif has_cookbook_file?(uri)
            :cookbook_file
          else
            raise Chef::Exceptions::FileNotFound, "Cannot locate key file: #{uri}"
          end
        end

        def keyring_path
          "/etc/apt/keyrings/#{new_resource.repo_name}.gpg"
        end

        # Get the current APT version, this is important for creating keyring files,
        # on newer APT versions these need to be an _older_ GnuPG format due to "sqv"
        # being used to verify
        #
        # @return [Integer]
        def apt_version
          @apt_version ||= shell_out("apt -v").stdout.strip[/([0-9]\.?){3}/, 0].to_i
        end

        # Fetch the key using either cookbook_file or remote_file, validate it,
        # and install it with apt-key add
        # @param [String] key the key to install
        #
        # @raise [RuntimeError] Invalid key which can't verify the apt repository
        #
        # @return [void]
        def install_key_from_uri(key)
          key_name = key.gsub(/[^0-9A-Za-z\-]/, "_")
          keyfile_tmp_path = ::File.join(Chef::Config[:file_cache_path], key_name)
          keyfile_path = keyring_path
          gpg_keyring_prefix = apt_version > 2 ? "gnupg-ring:" : ""
          tmp_dir = TargetIO::Dir.mktmpdir(".gpg")
          at_exit { TargetIO::FileUtils.remove_entry(tmp_dir) }

          if new_resource.signed_by
            directory "/etc/apt/keyrings" do
              mode "0755"
            end

            declare_resource(key_resource_type(key), keyfile_tmp_path) do
              source key
              mode "0644"
              sensitive new_resource.sensitive
              action :create
              verify "gpg --homedir #{tmp_dir} %{path}"
              notifies :run, "execute[import #{keyfile_path}]", :immediately
            end

            execute "import #{keyfile_path}" do
              command [ "gpg", "--import", "--batch", "--yes", "--no-default-keyring", "--keyring", "#{gpg_keyring_prefix}#{keyfile_path}", keyfile_tmp_path ]
              default_env true
              sensitive new_resource.sensitive
              action :nothing
            end

            file keyfile_path do
              mode "0644"
              notifies :run, "execute[import #{keyfile_path}]", :before unless ::File.exist?(keyfile_path)
            end
          else
            declare_resource(key_resource_type(key), keyfile_path) do
              source key
              mode "0644"
              sensitive new_resource.sensitive
              action :create
              verify "gpg --homedir #{tmp_dir} %{path}"
            end

            execute "apt-key add #{keyfile_path}" do
              command [ "apt-key", "add", keyfile_path ]
              default_env true
              sensitive new_resource.sensitive
              action :run
              not_if { no_new_keys?(keyfile_path) }
              notifies :run, "execute[apt-cache gencaches]", :immediately
            end
          end
        end

        # build the apt-key command to install the keyserver
        # @param [String] key the key to install
        # @param [String] keyserver the key server to use
        #
        # @return [String] the full apt-key command to run
        def keyserver_install_cmd(key, keyserver)
          cmd = "apt-key adv --no-tty --recv"
          cmd << " --keyserver-options http-proxy=#{new_resource.key_proxy}" if new_resource.key_proxy
          cmd << " --keyserver "
          cmd << if keyserver.start_with?("hkp://")
                   keyserver
                 else
                   "hkp://#{keyserver}:80"
                 end

          cmd << " #{key}"
          cmd
        end

        # @param [String] key
        # @param [String] keyserver
        #
        # @raise [RuntimeError] Invalid key which can't verify the apt repository
        #
        # @return [void]
        def install_key_from_keyserver(key, keyserver = new_resource.keyserver)
          if new_resource.signed_by
            install_key_from_keyserver_to_keyring(key, keyserver, keyring_path)
            return
          end
          execute "install-key #{key}" do
            command keyserver_install_cmd(key, keyserver)
            default_env true
            sensitive new_resource.sensitive
            not_if do
              present = extract_fingerprints_from_cmd(*LIST_APT_KEY_FINGERPRINTS).any? do |fp|
                fp.end_with? key.upcase
              end
              present && key_is_valid?(key.upcase)
            end
            notifies :run, "execute[apt-cache gencaches]", :immediately
          end

          raise "The key #{key} is invalid and cannot be used to verify an apt repository." unless key_is_valid?(key.upcase)
        end

        # @param [String] key
        # @param [String] keyserver
        # @param [String] keyring
        def install_key_from_keyserver_to_keyring(key, keyserver, keyring)
          keyserver = "hkp://#{keyserver}:80" unless keyserver.start_with?("hkp://")

          cmd = "gpg --no-default-keyring --keyring #{keyring}"
          cmd << " --keyserver-options http-proxy=#{new_resource.key_proxy}" if new_resource.key_proxy
          cmd << " --keyserver #{keyserver}"
          cmd << " --recv #{key}"

          execute "install-key #{key}" do
            command cmd
            default_env true
            sensitive new_resource.sensitive
            not_if do
              keyring_key_is_present?(keyring, key.upcase) && keyring_key_is_valid?(keyring, key.upcase)
            end
            notifies :run, "execute[apt-cache gencaches]", :immediately
          end

          raise "The key #{key} is invalid and cannot be used to verify an apt repository." unless keyring_key_is_valid?(keyring, key.upcase)
        end

        # @param [String] owner
        # @param [String] repo
        #
        # @raise [RuntimeError] Could not access the Launchpad PPA API
        #
        # @return [void]
        def install_ppa_key(owner, repo)
          url = "https://launchpad.net/api/1.0/~#{owner}/+archive/#{repo}"
          key_id = TargetIO::HTTP.new(url).get("signing_key_fingerprint").delete('"')
          install_key_from_keyserver(key_id, "keyserver.ubuntu.com")
        rescue Net::HTTPClientException => e
          raise "Could not access Launchpad ppa API: #{e.message}"
        end

        # determine if the repository URL is a PPA
        # @param [String] url the url of the repository
        #
        # @return [Boolean] is the repo URL a PPA
        def is_ppa_url?(url)
          url.start_with?("ppa:")
        end

        # determine the repository's components:
        #  - "components" property if defined
        #  - "main" if "components" not defined and the repo is a PPA URL
        #  - otherwise nothing
        #
        # @return [String] the repository component
        def repo_components
          if is_ppa_url?(new_resource.uri) && new_resource.components.empty?
            "main"
          else
            new_resource.components
          end
        end

        # given a PPA return a PPA URL in http://ppa.launchpad.net format
        # @param [String] ppa the ppa URL
        #
        # @return [String] full PPA URL
        def make_ppa_url(ppa)
          owner, repo = ppa[4..-1].split("/")
          repo ||= "ppa"

          install_ppa_key(owner, repo)
          "http://ppa.launchpad.net/#{owner}/#{repo}/ubuntu"
        end

        # build complete repo text that will be written to the config
        # @param [String] uri
        # @param [Array] components
        # @param [Boolean] trusted
        # @param [String] arch
        # @param [String] signed_by
        # @param [Array] options
        # @param [Boolean] add_src
        #
        # @return [String] complete repo config text
        def build_repo(uri, distribution, components, trusted, arch, signed_by, options, add_src = false)
          uri = make_ppa_url(uri) if is_ppa_url?(uri)

          uri = Addressable::URI.parse(uri)
          components = Array(components).join(" ")
          options_list = []
          options_list << "arch=#{arch}" if arch
          options_list << "trusted=yes" if trusted
          options_list << "signed-by=#{signed_by}" if signed_by
          options_list += options
          optstr = unless options_list.empty?
                     "[" + options_list.join(" ") + "]"
                   end
          info = [ optstr, uri.normalize.to_s, distribution, components ].compact.join(" ")
          repo =  "deb      #{info}\n"
          repo << "deb-src  #{info}\n" if add_src
          repo
        end

        # clean up a potentially legacy file from before we fixed the usage of
        # new_resource.name vs. new_resource.repo_name. We might have the
        # name.list file hanging around and need to clean it up.
        #
        # @return [void]
        def cleanup_legacy_file!
          legacy_path = "/etc/apt/sources.list.d/#{new_resource.name}.list"
          if new_resource.name != new_resource.repo_name && ::TargetIO::File.exist?(legacy_path)
            converge_by "Cleaning up legacy #{legacy_path} repo file" do
              file legacy_path do
                action :delete
                # Not triggering an update since it isn't super likely to be needed.
              end
            end
          end
        end
      end

      action :add, description: "Creates a repository file at `/etc/apt/sources.list.d/` and builds the repository listing." do
        return unless debian?

        execute "apt-cache gencaches" do
          command %w{apt-cache gencaches}
          default_env true
          ignore_failure true
          action :nothing
        end

        apt_update new_resource.name do
          ignore_failure true
          action :nothing
        end

        if new_resource.key.nil?
          logger.debug "No 'key' property specified skipping key import"
        else
          new_resource.key.each do |k|
            if is_key_id?(k) && !has_cookbook_file?(k)
              install_key_from_keyserver(k)
            else
              install_key_from_uri(k)
            end
          end
        end

        cleanup_legacy_file!

        signed_by = new_resource.signed_by
        if signed_by == true
          if new_resource.key || ::File.exist?(keyring_path)
            signed_by = keyring_path
          else
            # There isn't a key to use, so don't set the signed-by attribute
            signed_by = false
          end
        end

        repo = build_repo(
          new_resource.uri,
          new_resource.distribution,
          repo_components,
          new_resource.trusted,
          new_resource.arch,
          signed_by,
          new_resource.options,
          new_resource.deb_src
        )

        file "/etc/apt/sources.list.d/#{new_resource.repo_name}.list" do
          owner "root"
          group "root"
          mode "0644"
          content repo
          sensitive new_resource.sensitive
          action :create
          notifies :run, "execute[apt-cache gencaches]", :immediately
          notifies :update, "apt_update[#{new_resource.name}]", :immediately if new_resource.cache_rebuild
        end
      end

      action :remove, description: "Removes the repository listing." do
        return unless debian?

        cleanup_legacy_file!
        if ::TargetIO::File.exist?("/etc/apt/sources.list.d/#{new_resource.repo_name}.list")
          converge_by "Removing #{new_resource.repo_name} repository from /etc/apt/sources.list.d/" do
            apt_update new_resource.name do
              ignore_failure true
              action :nothing
            end

            file keyring_path do
              sensitive new_resource.sensitive
              action :delete
            end

            file "/etc/apt/sources.list.d/#{new_resource.repo_name}.list" do
              sensitive new_resource.sensitive
              action :delete
              notifies :update, "apt_update[#{new_resource.name}]", :immediately if new_resource.cache_rebuild
            end
          end
        else
          logger.debug("/etc/apt/sources.list.d/#{new_resource.repo_name}.list does not exist. Nothing to do")
        end
      end

    end
  end
end
