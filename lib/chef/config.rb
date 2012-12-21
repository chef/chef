#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Mark Mzyk (mmzyk@opscode.com)
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
require 'mixlib/config'

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

    def self.formatters
      @formatters ||= []
    end

    # Override the config dispatch to set the value of multiple server options simultaneously
    #
    # === Parameters
    # url<String>:: String to be set for all of the chef-server-api URL's
    #
    config_attr_writer :chef_server_url do |url|
      url.strip!
      configure do |c|
        [ :registration_url,
          :template_url,
          :remotefile_url,
          :search_url,
          :chef_server_url,
          :role_url ].each do |u|
            c[u] = url
        end
      end
      url
    end

    # When you are using ActiveSupport, they monkey-patch 'daemonize' into Kernel.
    # So while this is basically identical to what method_missing would do, we pull
    # it up here and get a real method written so that things get dispatched
    # properly.
    config_attr_writer :daemonize do |v|
      configure do |c|
        c[:daemonize] = v
      end
    end

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
          raise Chef::Exceptions::ConfigurationError("Failed to open or create log file at #{location.to_str}")
        end
          f
      end
    end

    # Override the config dispatch to set the value of authorized_openid_providers when openid_providers (deprecated) is used
    #
    # === Parameters
    # providers<Array>:: An array of openid providers that are authorized to login to the chef server
    #
    config_attr_writer :openid_providers do |providers|
      configure { |c| c[:authorized_openid_providers] = providers }
      providers
    end

    # Turn on "path sanity" by default. See also: http://wiki.opscode.com/display/chef/User+Environment+PATH+Sanity
    enforce_path_sanity(true)

    # Formatted Chef Client output is a beta feature, disabled by default:
    formatter "null"

    # Used when OpenID authentication is enabled in the Web UI
    authorized_openid_identifiers nil
    authorized_openid_providers nil

    # The number of times the client should retry when registering with the server
    client_registration_retries 5

    # Where the cookbooks are located. Meaning is somewhat context dependent between
    # knife, chef-client, and chef-solo.
    cookbook_path [ platform_specific_path("/var/chef/cookbooks"),
                    platform_specific_path("/var/chef/site-cookbooks") ]

    # An array of paths to search for knife exec scripts if they aren't in the current directory
    script_path []

    # Where files are stored temporarily during uploads
    sandbox_path "/var/chef/sandboxes"

    # Where cookbook files are stored on the server (by content checksum)
    checksum_path "/var/chef/checksums"

    # Where chef's cache files should be stored
    file_cache_path platform_specific_path("/var/chef/cache")

    # By default, chef-client (or solo) creates a lockfile in
    # `file_cache_path`/chef-client-running.pid
    # If `lockfile` is explicitly set, this path will be used instead.
    #
    # If your `file_cache_path` resides on a NFS (or non-flock()-supporting
    # fs), it's recommended to set this to something like
    # '/tmp/chef-client-running.pid'
    lockfile nil

    # Where backups of chef-managed files should go
    file_backup_path platform_specific_path("/var/chef/backup")

    ## Daemonization Settings ##
    # What user should Chef run as?
    user nil
    group nil
    umask 0022


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
    log_level :auto

    # Using `force_formatter` causes chef to default to formatter output when STDOUT is not a tty
    force_formatter false

    # Using `force_logger` causes chef to default to logger output when STDOUT is a tty
    force_logger false

    http_retry_count 5
    http_retry_delay 5
    interval nil
    json_attribs nil
    log_location STDOUT
    # toggle info level log items that can create a lot of output
    verbose_logging true
    node_name nil
    node_path "/var/chef/node"
    diff_disable            false
    diff_filesize_threshold 10000000
    diff_output_threshold   1000000

    pid_file nil

    chef_server_url   "http://localhost:4000"
    registration_url  "http://localhost:4000"
    template_url      "http://localhost:4000"
    role_url          "http://localhost:4000"
    remotefile_url    "http://localhost:4000"
    search_url        "http://localhost:4000"

    client_url "http://localhost:4042"

    rest_timeout 300
    run_command_stderr_timeout 120
    run_command_stdout_timeout 120
    solo  false
    splay nil
    why_run false
    color false
    client_fork false
    enable_reporting true
    enable_reporting_url_fatals false

    # Set these to enable SSL authentication / mutual-authentication
    # with the server
    ssl_client_cert nil
    ssl_client_key nil
    ssl_verify_mode :verify_none
    ssl_ca_path nil
    ssl_ca_file nil


    # Where should chef-solo look for role files?
    role_path platform_specific_path("/var/chef/roles")

    data_bag_path platform_specific_path("/var/chef/data_bags")

    # Where should chef-solo download recipes from?
    recipe_url nil

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
    authentication_protocol_version "1.0"

    # This key will be used to sign requests to the Chef server. This location
    # must be writable by Chef during initial setup when generating a client
    # identity on the server.
    #
    # The chef-server will look up the public key for the client using the
    # `node_name` of the client.
    client_key platform_specific_path("/etc/chef/client.pem")

    # If there is no file in the location given by `client_key`, chef-client
    # will temporarily use the "validator" identity to generate one. If the
    # `client_key` is not present and the `validation_key` is also not present,
    # chef-client will not be able to authenticate to the server.
    #
    # The `validation_key` is never used if the `client_key` exists.
    validation_key platform_specific_path("/etc/chef/validation.pem")
    validation_client_name "chef-validator"
    web_ui_client_name "chef-webui"
    web_ui_key "/etc/chef/webui.pem"
    web_ui_admin_user_name  "admin"
    web_ui_admin_default_password "p@ssw0rd1"

    # Server Signing CA
    #
    # In truth, these don't even have to change
    signing_ca_cert "/var/chef/ca/cert.pem"
    signing_ca_key "/var/chef/ca/key.pem"
    signing_ca_user nil
    signing_ca_group nil
    signing_ca_country "US"
    signing_ca_state "Washington"
    signing_ca_location "Seattle"
    signing_ca_org "Chef User"
    signing_ca_domain "opensource.opscode.com"
    signing_ca_email "opensource-cert@opscode.com"

    # Report Handlers
    report_handlers []

    # Exception Handlers
    exception_handlers []

    # Start handlers
    start_handlers []

    # Syntax Check Cache. Knife keeps track of files that is has already syntax
    # checked by storing files in this directory. `syntax_check_cache_path` is
    # the new (and preferred) configuration setting. If not set, knife will
    # fall back to using cache_options[:path].
    #
    # Because many users will have knife configs with cache_options (generated
    # by `knife configure`), the default for now is to *not* set
    # syntax_check_cache_path, and thus fallback to cache_options[:path]. We
    # leave that value to the same default as was previously set.
    syntax_check_cache_path nil

    # Deprecated:
    cache_options({ :path => platform_specific_path("/var/chef/cache/checksums") })

    # Set to false to silence Chef 11 deprecation warnings:
    chef11_deprecation_warnings true

    # Arbitrary knife configuration data
    knife Hash.new

    # Those lists of regular expressions define what chef considers a
    # valid user and group name
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      # From http://technet.microsoft.com/en-us/library/cc776019(WS.10).aspx

      principal_valid_regex_part = '[^"\/\\\\\[\]\:;|=,+*?<>]+'
      user_valid_regex [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]
      group_valid_regex [ /^(#{principal_valid_regex_part}\\)?#{principal_valid_regex_part}$/ ]
    else
      user_valid_regex [ /^([-a-zA-Z0-9_.]+)$/, /^\d+$/ ]
      group_valid_regex [ /^([-a-zA-Z0-9_.\\ ]+)$/, /^\d+$/ ]
    end

    # returns a platform specific path to the user home dir
    windows_home_path = ENV['SYSTEMDRIVE'] + ENV['HOMEPATH'] if ENV['SYSTEMDRIVE'] && ENV['HOMEPATH']
    user_home(ENV['HOME'] || windows_home_path || ENV['USERPROFILE'])
  end
end
