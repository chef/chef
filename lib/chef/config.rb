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

class Chef
  class Config

    extend Mixlib::Config

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

    def self.platform_path_separator
      if RUBY_PLATFORM =~ /mswin|mingw|windows/
        File::ALT_SEPARATOR || '\\'
      else
        File::SEPARATOR
      end
    end

    def self.platform_specific_path(path)
      if RUBY_PLATFORM =~ /mswin|mingw|windows/
        # turns /etc/chef/client.rb into C:/chef/client.rb
        system_drive = ENV['SYSTEMDRIVE'] ? ENV['SYSTEMDRIVE'] : ""
        path = File.join(system_drive, path.split('/')[2..-1])
        # ensure all forward slashes are backslashes
        path.gsub!(File::SEPARATOR, (File::ALT_SEPARATOR || '\\'))
      end
      path
    end

    def self.add_formatter(name, file_path=nil)
      formatters << [name, file_path]
    end

    default :formatters, []

    # Override the config dispatch to set the value of multiple server options simultaneously
    #
    # === Parameters
    # url<String>:: String to be set for all of the chef-server-api URL's
    #
    configurable(:chef_server_url).writes_value { |url| url.strip }

    # When you are using ActiveSupport, they monkey-patch 'daemonize' into Kernel.
    # So while this is basically identical to what method_missing would do, we pull
    # it up here and get a real method written so that things get dispatched
    # properly.
    configurable(:daemonize).writes_value { |v| v }

    # Override the config dispatch to set the value of log_location configuration option
    #
    # === Parameters
    # location<IO||String>:: Logging location as either an IO stream or string representing log file path
    #
    config_attr_writer :log_location do |location|
      if location.respond_to? :sync=
        location.sync = true
        location
      elsif location.respond_to? :to_str
        begin
          f = File.new(location.to_str, "a")
          f.sync = true
        rescue Errno::ENOENT
          raise Chef::Exceptions::ConfigurationError, "Failed to open or create log file at #{location.to_str}"
        end
        f
      end
    end

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
        platform_specific_path("/var/chef")
      end
    end

    def self.derive_path_from_chef_repo_path(child_path)
      if chef_repo_path.kind_of?(String)
        "#{chef_repo_path}#{platform_path_separator}#{child_path}"
      else
        chef_repo_path.map { |path| "#{path}#{platform_path_separator}#{child_path}"}
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

    # Turn on "path sanity" by default. See also: http://wiki.opscode.com/display/chef/User+Environment+PATH+Sanity
    default :enforce_path_sanity, true

    # Formatted Chef Client output is a beta feature, disabled by default:
    default :formatter, "null"

    # The number of times the client should retry when registering with the server
    default :client_registration_retries, 5

    # An array of paths to search for knife exec scripts if they aren't in the current directory
    default :script_path, []

    # Where cookbook files are stored on the server (by content checksum)
    default :checksum_path, '/var/chef/checksums'

    # Where chef's cache files should be stored
    default(:file_cache_path) { platform_specific_path('/var/chef/cache') }

    # Where backups of chef-managed files should go
    default(:file_backup_path) { platform_specific_path('/var/chef/backup') }

    # The chef-client (or solo) lockfile.
    #
    # If your `file_cache_path` resides on a NFS (or non-flock()-supporting
    # fs), it's recommended to set this to something like
    # '/tmp/chef-client-running.pid'
    default(:lockfile) { "#{file_cache_path}#{platform_path_separator}chef-client-running.pid" }

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
    # context. When a tty is available (usually becase the user is running chef
    # in a console), the log level is set to :warn, and output formatters are
    # used as the primary mode of output. When a tty is not available, the
    # logger is the primary mode of output, and the log level is set to :info
    default :log_level, :auto

    # Using `force_formatter` causes chef to default to formatter output when STDOUT is not a tty
    default :force_formatter, false

    # Using `force_logger` causes chef to default to logger output when STDOUT is a tty
    default :force_logger, false

    default :http_retry_count, 5
    default :http_retry_delay, 5
    default :interval, nil
    default :once, nil
    default :json_attribs, nil
    default :log_location, STDOUT
    # toggle info level log items that can create a lot of output
    default :verbose_logging, true
    default :node_name, nil
    default :diff_disabled,           false
    default :diff_filesize_threshold, 10000000
    default :diff_output_threshold,   1000000

    default :pid_file, nil

    default :start_chef_zero, false
    default :chef_zero_port,  8889
    default :chef_server_url,   "https://localhost:443"

    default :rest_timeout, 300
    default :yum_timeout, 900
    default :solo,  false
    default :splay, nil
    default :why_run, false
    default :color, false
    default :client_fork, true
    default :enable_reporting, true
    default :enable_reporting_url_fatals, false

    # Set these to enable SSL authentication / mutual-authentication
    # with the server
    default :ssl_client_cert, nil
    default :ssl_client_key, nil
    default :ssl_verify_mode, :verify_none
    default :ssl_ca_path, nil
    default :ssl_ca_file, nil

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
    default(:client_key) { platform_specific_path("/etc/chef/client.pem") }

    # This secret is used to decrypt encrypted data bag items.
    default(:encrypted_data_bag_secret) do
      # We have to check for the existence of the default file before setting it
      # since +Chef::Config[:encrypted_data_bag_secret]+ is read by older
      # bootstrap templates to determine if the local secret should be uploaded to
      # node being bootstrapped. This should be removed in Chef 12.
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
    # Set this to `2` if you have chef-client 11.6.0+ in your infrastructure:
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
    default(:validation_key) { platform_specific_path("/etc/chef/validation.pem") }
    default :validation_client_name, "chef-validator"

    # Zypper package provider gpg checks. Set to true to enable package
    # gpg signature checking. This will be default in the
    # future. Setting to false disables the warnings.
    # Leaving this set to nil or false is a security hazard!
    default :zypper_check_gpg, nil

    # Report Handlers
    default :report_handlers, []

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
    default(:cache_options) { { :path => platform_specific_path("/var/chef/cache/checksums") } }

    # Set to false to silence Chef 11 deprecation warnings:
    default :chef11_deprecation_warnings, true

    # knife configuration data
    config_context :knife do
      default :ssh_port, nil
      default :ssh_user, nil
      default :ssh_attribute, nil
      default :ssh_gateway, nil
      default :bootstrap_version, nil
      default :bootstrap_proxy, nil
      default :identity_file, nil
      default :host_key_verify, nil
      default :forward_agent, nil
      default :sort_status_reverse, nil
      default :hints, {}
    end

    # Those lists of regular expressions define what chef considers a
    # valid user and group name
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      # From http://technet.microsoft.com/en-us/library/cc776019(WS.10).aspx

      principal_valid_regex_part = '[^"\/\\\\\[\]\:;|=,+*?<>]+'
      default :user_valid_regex, [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]
      default :group_valid_regex, [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]

      default :fatal_windows_admin_check, false
    else
      default :user_valid_regex, [ /^([-a-zA-Z0-9_.]+[\\@]?[-a-zA-Z0-9_.]+)$/, /^\d+$/ ]
      default :group_valid_regex, [ /^([-a-zA-Z0-9_.\\@^ ]+)$/, /^\d+$/ ]
    end

    # returns a platform specific path to the user home dir
    windows_home_path = ENV['SYSTEMDRIVE'] + ENV['HOMEPATH'] if ENV['SYSTEMDRIVE'] && ENV['HOMEPATH']
    default :user_home, (ENV['HOME'] || windows_home_path || ENV['USERPROFILE'])

    # Enable file permission fixup for selinux. Fixup will be done
    # only if selinux is enabled in the system.
    default :enable_selinux_file_permission_fixup, true

    # Use atomic updates (i.e. move operation) while updating contents
    # of the files resources. When set to false copy operation is
    # used to update files.
    default :file_atomic_update, true

    # If false file staging is will be done via tempfiles that are
    # created under ENV['TMP'] otherwise tempfiles will be created in
    # the directory that files are going to reside.
    default :file_staging_uses_destdir, false
  end
end
