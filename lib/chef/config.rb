#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Mark Mzyk (<mmzyk@opscode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/log'
require 'chef/exceptions'
require 'mixlib/config'
require 'chef/util/selinux'
require 'chef/util/path_helper'
require 'pathname'
require 'chef/mixin/shell_out'

class Chef
  class Config

    extend Mixlib::Config
    extend Chef::Mixin::ShellOut

    PathHelper = Chef::Util::PathHelper

    # Evaluates the given string as config.
    #
    # +filename+ is used for context in stacktraces, but doesn't need to be the name of an actual file.
    def self.from_string(string, filename)
      self.instance_eval(string, filename, 1)
    end

    # Manages the chef secret session key
    # === Returns
    # <newkey>:: A new or retrieved session key
    #
    def self.manage_secret_key
      newkey = nil
      if Chef::FileCache.has_key?("chef_server_cookie_id")
        newkey = Chef::FileCache.load("chef_server_cookie_id")
      else
        chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newkey = ""
        40.times { |i| newkey << chars[rand(chars.size-1)] }
        Chef::FileCache.store("chef_server_cookie_id", newkey)
      end
      newkey
    end

    def self.inspect
      configuration.inspect
    end

    def self.platform_specific_path(path)
      path = PathHelper.cleanpath(path)
      if Chef::Platform.windows?
        # turns \etc\chef\client.rb and \var\chef\client.rb into C:/chef/client.rb
        if env['SYSTEMDRIVE'] && path[0] == '\\' && path.split('\\')[2] == 'chef'
          path = PathHelper.join(env['SYSTEMDRIVE'], path.split('\\', 3)[2])
        end
      end
      path
    end

    def self.add_formatter(name, file_path=nil)
      formatters << [name, file_path]
    end

    def self.add_event_logger(logger)
      event_handlers << logger
    end

    # Config file to load (client.rb, knife.rb, etc. defaults set differently in knife, chef-client, etc.)
    configurable(:config_file)

    default(:config_dir) do
      if config_file
        PathHelper.dirname(config_file)
      else
        PathHelper.join(user_home, ".chef", "")
      end
    end

    default :formatters, []

    # Override the config dispatch to set the value of multiple server options simultaneously
    #
    # === Parameters
    # url<String>:: String to be set for all of the chef-server-api URL's
    #
    configurable(:chef_server_url).writes_value { |url| url.to_s.strip }

    # When you are using ActiveSupport, they monkey-patch 'daemonize' into Kernel.
    # So while this is basically identical to what method_missing would do, we pull
    # it up here and get a real method written so that things get dispatched
    # properly.
    configurable(:daemonize).writes_value { |v| v }

    # The root where all local chef object data is stored.  cookbooks, data bags,
    # environments are all assumed to be in separate directories under this.
    # chef-solo uses these directories for input data.  knife commands
    # that upload or download files (such as knife upload, knife role from file,
    # etc.) work.
    default :chef_repo_path do
      if self.configuration[:cookbook_path]
        if self.configuration[:cookbook_path].kind_of?(String)
          File.expand_path('..', self.configuration[:cookbook_path])
        else
          self.configuration[:cookbook_path].map do |path|
            File.expand_path('..', path)
          end
        end
      else
        cache_path
      end
    end

    def self.find_chef_repo_path(cwd)
      # In local mode, we auto-discover the repo root by looking for a path with "cookbooks" under it.
      # This allows us to run config-free.
      path = cwd
      until File.directory?(PathHelper.join(path, "cookbooks"))
        new_path = File.expand_path('..', path)
        if new_path == path
          Chef::Log.warn("No cookbooks directory found at or above current directory.  Assuming #{Dir.pwd}.")
          return Dir.pwd
        end
        path = new_path
      end
      Chef::Log.info("Auto-discovered chef repository at #{path}")
      path
    end

    def self.derive_path_from_chef_repo_path(child_path)
      if chef_repo_path.kind_of?(String)
        PathHelper.join(chef_repo_path, child_path)
      else
        chef_repo_path.map { |path| PathHelper.join(path, child_path)}
      end
    end

    # Location of acls on disk. String or array of strings.
    # Defaults to <chef_repo_path>/acls.
    # Only applies to Enterprise Chef commands.
    default(:acl_path) { derive_path_from_chef_repo_path('acls') }

    # Location of clients on disk. String or array of strings.
    # Defaults to <chef_repo_path>/acls.
    default(:client_path) { derive_path_from_chef_repo_path('clients') }

    # Location of cookbooks on disk. String or array of strings.
    # Defaults to <chef_repo_path>/cookbooks.  If chef_repo_path
    # is not specified, this is set to [/var/chef/cookbooks, /var/chef/site-cookbooks]).
    default(:cookbook_path) do
      if self.configuration[:chef_repo_path]
        derive_path_from_chef_repo_path('cookbooks')
      else
        Array(derive_path_from_chef_repo_path('cookbooks')).flatten +
          Array(derive_path_from_chef_repo_path('site-cookbooks')).flatten
      end
    end

    # Location of containers on disk. String or array of strings.
    # Defaults to <chef_repo_path>/containers.
    # Only applies to Enterprise Chef commands.
    default(:container_path) { derive_path_from_chef_repo_path('containers') }

    # Location of data bags on disk. String or array of strings.
    # Defaults to <chef_repo_path>/data_bags.
    default(:data_bag_path) { derive_path_from_chef_repo_path('data_bags') }

    # Location of environments on disk. String or array of strings.
    # Defaults to <chef_repo_path>/environments.
    default(:environment_path) { derive_path_from_chef_repo_path('environments') }

    # Location of groups on disk. String or array of strings.
    # Defaults to <chef_repo_path>/groups.
    # Only applies to Enterprise Chef commands.
    default(:group_path) { derive_path_from_chef_repo_path('groups') }

    # Location of nodes on disk. String or array of strings.
    # Defaults to <chef_repo_path>/nodes.
    default(:node_path) { derive_path_from_chef_repo_path('nodes') }

    # Location of roles on disk. String or array of strings.
    # Defaults to <chef_repo_path>/roles.
    default(:role_path) { derive_path_from_chef_repo_path('roles') }

    # Location of users on disk. String or array of strings.
    # Defaults to <chef_repo_path>/users.
    # Does not apply to Enterprise Chef commands.
    default(:user_path) { derive_path_from_chef_repo_path('users') }

    # Location of policies on disk. String or array of strings.
    # Defaults to <chef_repo_path>/policies.
    default(:policy_path) { derive_path_from_chef_repo_path('policies') }

    # Turn on "path sanity" by default. See also: http://wiki.opscode.com/display/chef/User+Environment+PATH+Sanity
    default :enforce_path_sanity, true

    # Formatted Chef Client output is a beta feature, disabled by default:
    default :formatter, "null"

    # The number of times the client should retry when registering with the server
    default :client_registration_retries, 5

    # An array of paths to search for knife exec scripts if they aren't in the current directory
    default :script_path, []

    # The root of all caches (checksums, cache and backup).  If local mode is on,
    # this is under the user's home directory.
    default(:cache_path) do
      if local_mode
        PathHelper.join(config_dir, 'local-mode-cache')
      else
        primary_cache_root = platform_specific_path("/var")
        primary_cache_path = platform_specific_path("/var/chef")
        # Use /var/chef as the cache path only if that folder exists and we can read and write
        # into it, or /var exists and we can read and write into it (we'll create /var/chef later).
        # Otherwise, we'll create .chef under the user's home directory and use that as
        # the cache path.
        unless path_accessible?(primary_cache_path) || path_accessible?(primary_cache_root)
          secondary_cache_path = PathHelper.join(user_home, '.chef')
          Chef::Log.info("Unable to access cache at #{primary_cache_path}. Switching cache to #{secondary_cache_path}")
          secondary_cache_path
        else
          primary_cache_path
        end
      end
    end

    # Returns true only if the path exists and is readable and writeable for the user.
    def self.path_accessible?(path)
      File.exists?(path) && File.readable?(path) && File.writable?(path)
    end

    # Where cookbook files are stored on the server (by content checksum)
    default(:checksum_path) { PathHelper.join(cache_path, "checksums") }

    # Where chef's cache files should be stored
    default(:file_cache_path) { PathHelper.join(cache_path, "cache") }

    # Where backups of chef-managed files should go
    default(:file_backup_path) { PathHelper.join(cache_path, "backup") }

    # The chef-client (or solo) lockfile.
    #
    # If your `file_cache_path` resides on a NFS (or non-flock()-supporting
    # fs), it's recommended to set this to something like
    # '/tmp/chef-client-running.pid'
    default(:lockfile) { PathHelper.join(file_cache_path, "chef-client-running.pid") }

    ## Daemonization Settings ##
    # What user should Chef run as?
    default :user, nil
    default :group, nil
    default :umask, 0022

    # Valid log_levels are:
    # * :debug
    # * :info
    # * :warn
    # * :fatal
    # These work as you'd expect. There is also a special `:auto` setting.
    # When set to :auto, Chef will auto adjust the log verbosity based on
    # context. When a tty is available (usually because the user is running chef
    # in a console), the log level is set to :warn, and output formatters are
    # used as the primary mode of output. When a tty is not available, the
    # logger is the primary mode of output, and the log level is set to :info
    default :log_level, :auto

    # Logging location as either an IO stream or string representing log file path
    default :log_location, STDOUT

    # Using `force_formatter` causes chef to default to formatter output when STDOUT is not a tty
    default :force_formatter, false

    # Using `force_logger` causes chef to default to logger output when STDOUT is a tty
    default :force_logger, false

    default :http_retry_count, 5
    default :http_retry_delay, 5
    default :interval, nil
    default :once, nil
    default :json_attribs, nil
    # toggle info level log items that can create a lot of output
    default :verbose_logging, true
    default :node_name, nil
    default :diff_disabled,           false
    default :diff_filesize_threshold, 10000000
    default :diff_output_threshold,   1000000
    default :local_mode, false

    default :pid_file, nil

    config_context :chef_zero do
      config_strict_mode true
      default(:enabled) { Chef::Config.local_mode }
      default :host, 'localhost'
      default :port, 8889.upto(9999) # Will try ports from 8889-9999 until one works
    end
    default :chef_server_url,   "https://localhost:443"

    default :rest_timeout, 300
    default :yum_timeout, 900
    default :yum_lock_timeout, 30
    default :solo,  false
    default :splay, nil
    default :why_run, false
    default :color, false
    default :client_fork, true
    default :ez, false
    default :enable_reporting, true
    default :enable_reporting_url_fatals, false
    # Possible values for :audit_mode
    # :enabled, :disabled, :audit_only,
    #
    # TODO: 11 Dec 2014: Currently audit-mode is an experimental feature
    # and is disabled by default. When users choose to enable audit-mode,
    # a warning is issued in application/client#reconfigure.
    # This can be removed when audit-mode is enabled by default.
    default :audit_mode, :disabled

    # Policyfile is an experimental feature where a node gets its run list and
    # cookbook version set from a single document on the server instead of
    # expanding the run list and having the server compute the cookbook version
    # set based on environment constraints.
    #
    # Because this feature is experimental, it is not recommended for
    # production use. Developent/release of this feature may not adhere to
    # semver guidelines.
    default :use_policyfile, false

    # Set these to enable SSL authentication / mutual-authentication
    # with the server

    # Client side SSL cert/key for mutual auth
    default :ssl_client_cert, nil
    default :ssl_client_key, nil

    # Whether or not to verify the SSL cert for all HTTPS requests. When set to
    # :verify_peer (default), all HTTPS requests will be validated regardless of other
    # SSL verification settings. When set to :verify_none no HTTPS requests will
    # be validated.
    default :ssl_verify_mode, :verify_peer

    # Whether or not to verify the SSL cert for HTTPS requests to the Chef
    # server API. If set to `true`, the server's cert will be validated
    # regardless of the :ssl_verify_mode setting. This is set to `true` when
    # running in local-mode.
    # NOTE: This is a workaround until verify_peer is enabled by default.
    default(:verify_api_cert) { Chef::Config.local_mode }

    # Path to the default CA bundle files.
    default :ssl_ca_path, nil
    default(:ssl_ca_file) do
      if Chef::Platform.windows? and embedded_path = embedded_dir
        cacert_path = File.join(embedded_path, "ssl/certs/cacert.pem")
        cacert_path if File.exist?(cacert_path)
      else
        nil
      end
    end

    # A directory that contains additional SSL certificates to trust. Any
    # certificates in this directory will be added to whatever CA bundle ruby
    # is using. Use this to add self-signed certs for your Chef Server or local
    # HTTP file servers.
    default(:trusted_certs_dir) { PathHelper.join(config_dir, "trusted_certs") }

    # Where should chef-solo download recipes from?
    default :recipe_url, nil

    # Sets the version of the signed header authentication protocol to use (see
    # the 'mixlib-authorization' project for more detail). Currently, versions
    # 1.0 and 1.1 are available; however, the chef-server must first be
    # upgraded to support version 1.1 before clients can begin using it.
    #
    # Version 1.1 of the protocol is required when using a `node_name` greater
    # than ~90 bytes (~90 ascii characters), so chef-client will automatically
    # switch to using version 1.1 when `node_name` is too large for the 1.0
    # protocol. If you intend to use large node names, ensure that your server
    # supports version 1.1. Automatic detection of large node names means that
    # users will generally not need to manually configure this.
    #
    # In the future, this configuration option may be replaced with an
    # automatic negotiation scheme.
    default :authentication_protocol_version, "1.0"

    # This key will be used to sign requests to the Chef server. This location
    # must be writable by Chef during initial setup when generating a client
    # identity on the server.
    #
    # The chef-server will look up the public key for the client using the
    # `node_name` of the client.
    #
    # If chef-zero is enabled, this defaults to nil (no authentication).
    default(:client_key) { chef_zero.enabled ? nil : platform_specific_path("/etc/chef/client.pem") }

    # When registering the client, should we allow the client key location to
    # be a symlink?  eg: /etc/chef/client.pem -> /etc/chef/prod-client.pem
    # If the path of the key goes through a directory like /tmp this should
    # never be set to true or its possibly an easily exploitable security hole.
    default :follow_client_key_symlink, false

    # This secret is used to decrypt encrypted data bag items.
    default(:encrypted_data_bag_secret) do
      if File.exist?(platform_specific_path("/etc/chef/encrypted_data_bag_secret"))
        platform_specific_path("/etc/chef/encrypted_data_bag_secret")
      else
        nil
      end
    end

    # As of Chef 11.0, version "1" is the default encrypted data bag item
    # format. Version "2" is available which adds encrypt-then-mac protection.
    # To maintain compatibility, versions other than 1 must be opt-in.
    #
    # Set this to `2` if you have chef-client 11.6.0+ in your infrastructure.
    # Set this to `3` if you have chef-client 11.?.0+, ruby 2 and OpenSSL >= 1.0.1 in your infrastructure. (TODO)
    default :data_bag_encrypt_version, 1

    # When reading data bag items, any supported version is accepted. However,
    # if all encrypted data bags have been generated with the version 2 format,
    # it is recommended to disable support for earlier formats to improve
    # security. For example, the version 2 format is identical to version 1
    # except for the addition of an HMAC, so an attacker with MITM capability
    # could downgrade an encrypted data bag to version 1 as part of an attack.
    default :data_bag_decrypt_minimum_version, 0

    # If there is no file in the location given by `client_key`, chef-client
    # will temporarily use the "validator" identity to generate one. If the
    # `client_key` is not present and the `validation_key` is also not present,
    # chef-client will not be able to authenticate to the server.
    #
    # The `validation_key` is never used if the `client_key` exists.
    #
    # If chef-zero is enabled, this defaults to nil (no authentication).
    default(:validation_key) { chef_zero.enabled ? nil : platform_specific_path("/etc/chef/validation.pem") }
    default :validation_client_name, "chef-validator"

    # When creating a new client via the validation_client account, Chef 11
    # servers allow the client to generate a key pair locally and send the
    # public key to the server. This is more secure and helps offload work from
    # the server, enhancing scalability. If enabled and the remote server
    # implements only the Chef 10 API, client registration will not work
    # properly.
    #
    # The default value is `true`. Set to `false` to disable client-side key
    # generation (server generates client keys).
    default(:local_key_generation) { true }

    # Zypper package provider gpg checks. Set to true to enable package
    # gpg signature checking. This will be default in the
    # future. Setting to false disables the warnings.
    # Leaving this set to nil or false is a security hazard!
    default :zypper_check_gpg, nil

    # Report Handlers
    default :report_handlers, []

    # Event Handlers
    default :event_handlers, []

    default :disable_event_loggers, false
    default :event_loggers do
      evt_loggers = []
      if Chef::Platform::windows? and not Chef::Platform::windows_server_2003?
        evt_loggers << :win_evt
      end
      evt_loggers
    end

    # Exception Handlers
    default :exception_handlers, []

    # Start handlers
    default :start_handlers, []

    # Syntax Check Cache. Knife keeps track of files that is has already syntax
    # checked by storing files in this directory. `syntax_check_cache_path` is
    # the new (and preferred) configuration setting. If not set, knife will
    # fall back to using cache_options[:path], which is deprecated but exists in
    # many client configs generated by pre-Chef-11 bootstrappers.
    default(:syntax_check_cache_path) { cache_options[:path] }

    # Deprecated:
    # Move this to the default value of syntax_cache_path when this is removed.
    default(:cache_options) { { :path => PathHelper.join(config_dir, "syntaxcache") } }

    # Whether errors should be raised for deprecation warnings. When set to
    # `false` (the default setting), a warning is emitted but code using
    # deprecated methods/features/etc. should work normally otherwise. When set
    # to `true`, usage of deprecated methods/features will raise a
    # `DeprecatedFeatureError`. This is used by Chef's tests to ensure that
    # deprecated functionality is not used internally by Chef.  End users
    # should generally leave this at the default setting (especially in
    # production), but it may be useful when testing cookbooks or other code if
    # the user wishes to aggressively address deprecations.
    default(:treat_deprecation_warnings_as_errors) do
      # Using an environment variable allows this setting to be inherited in
      # tests that spawn new processes.
      ENV.key?("CHEF_TREAT_DEPRECATION_WARNINGS_AS_ERRORS")
    end

    # knife configuration data
    config_context :knife do
      default :ssh_port, nil
      default :ssh_user, nil
      default :ssh_attribute, nil
      default :ssh_gateway, nil
      default :bootstrap_version, nil
      default :bootstrap_proxy, nil
      default :bootstrap_template, nil
      default :secret, nil
      default :secret_file, nil
      default :identity_file, nil
      default :host_key_verify, nil
      default :forward_agent, nil
      default :sort_status_reverse, nil
      default :hints, {}
    end

    def self.set_defaults_for_windows
      # Those lists of regular expressions define what chef considers a
      # valid user and group name
      # From http://technet.microsoft.com/en-us/library/cc776019(WS.10).aspx
      principal_valid_regex_part = '[^"\/\\\\\[\]\:;|=,+*?<>]+'
      default :user_valid_regex, [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]
      default :group_valid_regex, [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]

      default :fatal_windows_admin_check, false
    end

    def self.set_defaults_for_nix
      # Those lists of regular expressions define what chef considers a
      # valid user and group name
      #
      # user/group cannot start with '-', '+' or '~'
      # user/group cannot contain ':', ',' or non-space-whitespace or null byte
      # everything else is allowed (UTF-8, spaces, etc) and we delegate to your O/S useradd program to barf or not
      # copies: http://anonscm.debian.org/viewvc/pkg-shadow/debian/trunk/debian/patches/506_relaxed_usernames?view=markup
      default :user_valid_regex, [ /^[^-+~:,\t\r\n\f\0]+[^:,\t\r\n\f\0]*$/ ]
      default :group_valid_regex, [ /^[^-+~:,\t\r\n\f\0]+[^:,\t\r\n\f\0]*$/ ]
    end

    # Those lists of regular expressions define what chef considers a
    # valid user and group name
    if Chef::Platform.windows?
      set_defaults_for_windows
    else
      set_defaults_for_nix
    end

    # This provides a hook which rspec can stub so that we can avoid twiddling
    # global state in tests.
    def self.env
      ENV
    end

    def self.windows_home_path
      env['SYSTEMDRIVE'] + env['HOMEPATH'] if env['SYSTEMDRIVE'] && env['HOMEPATH']
    end

    # returns a platform specific path to the user home dir if set, otherwise default to current directory.
    default( :user_home ) { env['HOME'] || windows_home_path || env['USERPROFILE'] || Dir.pwd }

    # Enable file permission fixup for selinux. Fixup will be done
    # only if selinux is enabled in the system.
    default :enable_selinux_file_permission_fixup, true

    # Use atomic updates (i.e. move operation) while updating contents
    # of the files resources. When set to false copy operation is
    # used to update files.
    default :file_atomic_update, true

    # There are 3 possible values for this configuration setting.
    # true => file staging is done in the destination directory
    # false => file staging is done via tempfiles under ENV['TMP']
    # :auto => file staging will try using destination directory if possible and
    #   will fall back to ENV['TMP'] if destination directory is not usable.
    default :file_staging_uses_destdir, :auto

    # Exit if another run is in progress and the chef-client is unable to
    # get the lock before time expires. If nil, no timeout is enforced. (Exits
    # immediately if 0.)
    default :run_lock_timeout, nil

    # Number of worker threads for syncing cookbooks in parallel. Increasing
    # this number can result in gateway errors from the server (namely 503 and 504).
    # If you are seeing this behavior while using the default setting, reducing
    # the number of threads will help.
    default :cookbook_sync_threads, 10

    # At the beginning of the Chef Client run, the cookbook manifests are downloaded which
    # contain URLs for every file in every relevant cookbook.  Most of the files
    # (recipes, resources, providers, libraries, etc) are immediately synchronized
    # at the start of the run.  The handling of "files" and "templates" directories,
    # however, have two modes of operation.  They can either all be downloaded immediately
    # at the start of the run (no_lazy_load==true) or else they can be lazily loaded as
    # cookbook_file or template resources are converged which require them (no_lazy_load==false).
    #
    # The advantage of lazily loading these files is that unnecessary files are not
    # synchronized.  This may be useful to users with large files checked into cookbooks which
    # are only selectively downloaded to a subset of clients which use the cookbook.  However,
    # better solutions are to either isolate large files into individual cookbooks and only
    # include those cookbooks in the run lists of the servers that need them -- or move to
    # using remote_file and a more appropriate backing store like S3 for large file
    # distribution.
    #
    # The disadvantages of lazily loading files are that users some time find it
    # confusing that their cookbooks are not fully synchronzied to the cache initially,
    # and more importantly the time-sensitive URLs which are in the manifest may time
    # out on long Chef runs before the resource that uses the file is converged
    # (leading to many confusing 403 errors on template/cookbook_file resources).
    #
    default :no_lazy_load, true

    # Default for the chef_gem compile_time attribute.  Nil is the same as true but will emit
    # warnings on every use of chef_gem prompting the user to be explicit.  If the user sets this to
    # true then the user will get backcompat behavior but with a single nag warning that cookbooks
    # may break with this setting in the future.  The false setting is the recommended setting and
    # will become the default.
    default :chef_gem_compile_time, nil

    # A whitelisted array of attributes you want sent over the wire when node
    # data is saved.
    # The default setting is nil, which collects all data. Setting to [] will not
    # collect any data for save.
    default :automatic_attribute_whitelist, nil
    default :default_attribute_whitelist, nil
    default :normal_attribute_whitelist, nil
    default :override_attribute_whitelist, nil

    config_context :windows_service do
      # Set `watchdog_timeout` to the number of seconds to wait for a chef-client run
      # to finish
      default :watchdog_timeout, 2 * (60 * 60) # 2 hours
    end

    # Chef requires an English-language UTF-8 locale to function properly.  We attempt
    # to use the 'locale -a' command and search through a list of preferences until we
    # find one that we can use.  On Ubuntu systems we should find 'C.UTF-8' and be
    # able to use that even if there is no English locale on the server, but Mac, Solaris,
    # AIX, etc do not have that locale.  We then try to find an English locale and fall
    # back to 'C' if we do not.  The choice of fallback is pick-your-poison.  If we try
    # to do the work to return a non-US UTF-8 locale then we fail inside of providers when
    # things like 'svn info' return Japanese and we can't parse them.  OTOH, if we pick 'C' then
    # we will blow up on UTF-8 characters.  Between the warn we throw and the Encoding
    # exception that ruby will throw it is more obvious what is broken if we drop UTF-8 by
    # default rather than drop English.
    #
    # If there is no 'locale -a' then we return 'en_US.UTF-8' since that is the most commonly
    # available English UTF-8 locale.  However, all modern POSIXen should support 'locale -a'.
    def self.guess_internal_locale
      # https://github.com/opscode/chef/issues/2181
      # Some systems have the `locale -a` command, but the result has
      # invalid characters for the default encoding.
      #
      # For example, on CentOS 6 with ENV['LANG'] = "en_US.UTF-8",
      # `locale -a`.split fails with ArgumentError invalid UTF-8 encoding.
      locales = shell_out_with_systems_locale!("locale -a").stdout.split
      case
      when locales.include?('C.UTF-8')
        'C.UTF-8'
      when locales.include?('en_US.UTF-8'), locales.include?('en_US.utf8')
        'en_US.UTF-8'
      when locales.include?('en.UTF-8')
        'en.UTF-8'
      else
        # Will match en_ZZ.UTF-8, en_ZZ.utf-8, en_ZZ.UTF8, en_ZZ.utf8
        guesses = locales.select { |l| l =~ /^en_.*UTF-?8$/i }
        unless guesses.empty?
          guessed_locale = guesses.first
          # Transform into the form en_ZZ.UTF-8
          guessed_locale.gsub(/UTF-?8$/i, "UTF-8")
        else
          Chef::Log.warn "Please install an English UTF-8 locale for Chef to use, falling back to C locale and disabling UTF-8 support."
          'C'
        end
      end
    rescue
      if Chef::Platform.windows?
        Chef::Log.debug "Defaulting to locale en_US.UTF-8 on Windows, until it matters that we do something else."
      else
        Chef::Log.debug "No usable locale -a command found, assuming you have en_US.UTF-8 installed."
      end
      'en_US.UTF-8'
    end

    default :internal_locale, guess_internal_locale

    # Force UTF-8 Encoding, for when we fire up in the 'C' locale or other strange locales (e.g.
    # japanese windows encodings).  If we do not do this, then knife upload will fail when a cookbook's
    # README.md has UTF-8 characters that do not encode in whatever surrounding encoding we have been
    # passed.  Effectively, the Chef Ecosystem is globally UTF-8 by default.  Anyone who wants to be
    # able to upload Shift_JIS or ISO-8859-1 files needs to mark *those* files explicitly with
    # magic tags to make ruby correctly identify the encoding being used.  Changing this default will
    # break Chef community cookbooks and is very highly discouraged.
    default :ruby_encoding, Encoding::UTF_8

    # If installed via an omnibus installer, this gives the path to the
    # "embedded" directory which contains all of the software packaged with
    # omnibus. This is used to locate the cacert.pem file on windows.
    def self.embedded_dir
      Pathname.new(_this_file).ascend do |path|
        if path.basename.to_s == "embedded"
          return path.to_s
        end
      end

      nil
    end

    # Path to this file in the current install.
    def self._this_file
      File.expand_path(__FILE__)
    end
  end
end
