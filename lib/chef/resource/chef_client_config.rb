#
# Copyright:: Copyright (c) Chef Software Inc.
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

class Chef
  class Resource
    class ChefClientConfig < Chef::Resource
      unified_mode true

      provides :chef_client_config

      description "Use the **chef_client_config** resource to create a client.rb file in the #{ChefUtils::Dist::Infra::PRODUCT} configuration directory. See the [client.rb docs](https://docs.chef.io/config_rb_client/) for more details on options available in the client.rb configuration file."
      introduced "16.6"
      examples <<~DOC
      **Bare minimum #{ChefUtils::Dist::Infra::PRODUCT} client.rb**:

      The absolute minimum configuration necessary for a node to communicate with the Infra Server is the URL of the Infra Server. All other configuration options either have values at the server side (Policyfiles, Roles, Environments, etc) or have default values determined at client startup.

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
      end
      ```

      **More complex #{ChefUtils::Dist::Infra::PRODUCT} client.rb**:

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        log_level :info
        log_location :syslog
        http_proxy 'proxy.example.dmz'
        https_proxy 'proxy.example.dmz'
        no_proxy %w(internal.example.dmz)
      end
      ```

      **Adding additional config content to the client.rb**:

      This resource aims to provide common configuration options. Some configuration options are missing and some users may want to use arbitrary Ruby code within their configuration. For this we offer an `additional_config` property that can be used to add any configuration or code to the bottom of the `client.rb` file. Also keep in mind that within the configuration directory is a `client.d` directory where you can put additional `.rb` files containing configuration options. These can be created using `file` or `template` resources within your cookbooks as necessary.

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        additional_config <<~CONFIG
          # Extra config code to safely load a gem into the client run.
          # Since the config is Ruby you can run any Ruby code you want via the client.rb.
          # It's a great way to break things, so be careful
          begin
            require 'aws-sdk'
          rescue LoadError
            Chef::Log.warn "Failed to load aws-sdk."
          end
        CONFIG
      end
      ```

      **Setup two report handlers in the client.rb**:

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        report_handlers [
          {
           'class' => 'ReportHandler1Class',
           'arguments' => ["'FirstArgument'", "'SecondArgument'"],
          },
          {
           'class' => 'ReportHandler2Class',
           'arguments' => ["'FirstArgument'", "'SecondArgument'"],
          },
        ]
      end
      ```
      DOC

      # @todo policy_file or policy_group being set requires the other to be set so enforce that.
      # @todo all properties for automate report
      # @todo add all descriptions
      # @todo validate handler hash structure

      #
      # @param [String, Symbol] prop_val the value from the property
      #
      # @return [Symbol] The symbol form of the symbol-like string, string, or symbol value
      #
      def string_to_symbol(prop_val)
        if prop_val.is_a?(String) && prop_val.start_with?(":")
          prop_val[1..-1].to_sym
        else
          prop_val.to_sym
        end
      end

      property :config_directory, String,
        description: "The directory to store the client.rb in.",
        default: ChefConfig::Config.etc_chef_dir,
        default_description: "`/etc/chef/` on *nix-like systems and `C:\\chef\\` on Windows"

      property :user, String,
        description: "The user that should own the client.rb file and the configuration directory if it needs to be created. Note: The configuration directory will not be created if it already exists, which allows you to further control the setup of that directory outside of this resource."

      property :group, String,
        description: "The group that should own the client.rb file and the configuration directory if it needs to be created. Note: The configuration directory will not be created if it already exists, which allows you to further control the setup of that directory outside of this resource."

      property :node_name, [String, NilClass], # this accepts nil so people can disable the default
        description: "The name of the node. This configuration sets the `node.name` value used in cookbooks and the `client_name` value used when authenticating to a #{ChefUtils::Dist::Server::PRODUCT} to determine what configuration to apply. Note: By default this configuration uses the `node.name` value which would be set during bootstrap. Hard coding this value in the `client.rb` config avoids logic within #{ChefUtils::Dist::Server::PRODUCT} that performs DNS lookups and may fail in the event of a DNS outage. To skip this default value and instead use the built-in #{ChefUtils::Dist::Server::PRODUCT} logic, set this property to `nil`",
        default: lazy { node.name },
        default_description: "The `node.name` value reported by #{ChefUtils::Dist::Infra::PRODUCT}."

      property :chef_server_url, String,
        description: "The URL for the #{ChefUtils::Dist::Server::PRODUCT}.",
        required: true

      # @todo Allow passing this as a string and convert it to the symbol
      property :ssl_verify_mode, [Symbol, String],
        equal_to: %i{verify_none verify_peer},
        coerce: proc { |x| string_to_symbol(x) },
        description: <<~DESC
        Set the verify mode for HTTPS requests.

        * Use :verify_none for no validation of SSL certificates.
        * Use :verify_peer for validation of all SSL certificates, including the #{ChefUtils::Dist::Server::PRODUCT} connections, S3 connections, and any HTTPS remote_file resource URLs used in #{ChefUtils::Dist::Infra::PRODUCT} runs. This is the recommended setting.
        DESC

      property :formatters, Array,
        description: "Client logging formatters to load.",
        default: []

      property :event_loggers, Array,
        description: "",
        default: []

      property :log_level, Symbol,
        description: "The level of logging performed by the #{ChefUtils::Dist::Infra::PRODUCT}.",
        equal_to: %i{auto trace debug info warn fatal}

      property :log_location, [String, Symbol],
        description: "The location to save logs to. This can either by a path to a log file on disk `:syslog` to log to Syslog, `:win_evt` to log to the Windows Event Log, or `'STDERR'`/`'STDOUT'` to log to the *nix text streams.",
        callbacks: {
          "accepts Symbol values of ':win_evt' for Windows Event Log or ':syslog' for Syslog" => lambda { |p|
            p.is_a?(Symbol) ? %i{win_evt syslog}.include?(p) : true
          },
        }

      property :http_proxy, String,
        description: "The proxy server to use for HTTP connections."

      property :https_proxy, String,
        description: "The proxy server to use for HTTPS connections."

      property :ftp_proxy, String,
      description: "The proxy server to use for FTP connections."

      property :no_proxy, [String, Array],
        description: "A comma-separated list or an array of URLs that do not need a proxy.",
        coerce: proc { |x| x.is_a?(Array) ? x.join(",") : x },
        default: []

      # @todo we need to fixup bad plugin naming inputs here
      property :ohai_disabled_plugins, Array,
        description: "Ohai plugins that should be disabled in order to speed up the #{ChefUtils::Dist::Infra::PRODUCT} run and reduce the size of node data sent to #{ChefUtils::Dist::Infra::PRODUCT}",
        coerce: proc { |x| x.map { |v| string_to_symbol(v).capitalize } },
        default: []

      # @todo we need to fixup bad plugin naming inputs here
      property :ohai_optional_plugins, Array,
        description: "Optional Ohai plugins that should be enabled to provide additional Ohai data for use in cookbooks.",
        coerce: proc { |x| x.map { |v| string_to_symbol(v).capitalize } },
        default: []

      property :minimal_ohai, [true, false],
        description: "Run a minimal set of Ohai plugins providing data necessary for the execution of #{ChefUtils::Dist::Infra::PRODUCT}'s built-in resources. Setting this to true will skip many large and time consuming data sets such as `cloud` or `packages`. Setting this this to true may break cookbooks that assume all Ohai data will be present."

      property :start_handlers, Array,
        description: %q(An array of hashes that contain a report handler class and the arguments to pass to that class on initialization. The hash should include `class` and `argument` keys where `class` is a String and `argument` is an array of quoted String values. For example: `[{'class' => 'MyHandler', %w('"argument1"', '"argument2"')}]`),
        default: []

      property :report_handlers, Array,
        description: %q(An array of hashes that contain a report handler class and the arguments to pass to that class on initialization. The hash should include `class` and `argument` keys where `class` is a String and `argument` is an array of quoted String values. For example: `[{'class' => 'MyHandler', %w('"argument1"', '"argument2"')}]`),
        default: []

      property :exception_handlers, Array,
        description: %q(An array of hashes that contain a exception handler class and the arguments to pass to that class on initialization. The hash should include `class` and `argument` keys where `class` is a String and `argument` is an array of quoted String values. For example: `[{'class' => 'MyHandler', %w('"argument1"', '"argument2"')}]`),
        default: []

      property :chef_license, String,
        description: "Accept the [Chef EULA](https://www.chef.io/end-user-license-agreement/)",
        equal_to: %w{accept accept-no-persist accept-silent}

      property :policy_name, String,
        description: "The name of a policy, as identified by the `name` setting in a Policyfile.rb file. `policy_group`  when setting this property."

      property :policy_group, String,
        description: "The name of a `policy group` that exists on the #{ChefUtils::Dist::Server::PRODUCT}. `policy_name` must also be specified when setting this property."

      property :named_run_list, String,
        description: "A specific named runlist defined in the node's applied Policyfile, which the should be used when running #{ChefUtils::Dist::Infra::PRODUCT}."

      property :pid_file, String,
        description: "The location in which a process identification number (pid) is saved. An executable, when started as a daemon, writes the pid to the specified file. "

      property :file_cache_path, String,
        description: "The location in which cookbooks (and other transient data) files are stored when they are synchronized. This value can also be used in recipes to download files with the `remote_file` resource."

      property :file_backup_path, String,
        description: "The location in which backup files are stored. If this value is empty, backup files are stored in the directory of the target file"

      property :file_staging_uses_destdir, String,
        description: "How file staging (via temporary files) is done. When `true`, temporary files are created in the directory in which files will reside. When `false`, temporary files are created under `ENV['TMP']`"

      property :additional_config, String,
        description: "Additional text to add at the bottom of the client.rb config. This can be used to run custom Ruby or to add less common config options"

      action :create, description: "Create a client.rb config file for configuring #{ChefUtils::Dist::Infra::PRODUCT}." do
        unless ::Dir.exist?(new_resource.config_directory)
          directory new_resource.config_directory do
            user new_resource.user unless new_resource.user.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0750"
            recursive true
          end
        end

        unless ::Dir.exist?(::File.join(new_resource.config_directory, "client.d"))
          directory ::File.join(new_resource.config_directory, "client.d") do
            user new_resource.user unless new_resource.user.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0750"
            recursive true
          end
        end

        template ::File.join(new_resource.config_directory, "client.rb") do
          source ::File.expand_path("support/client.erb", __dir__)
          user new_resource.user unless new_resource.user.nil?
          group new_resource.group unless new_resource.group.nil?
          local true
          variables(
            chef_license: new_resource.chef_license,
            chef_server_url: new_resource.chef_server_url,
            event_loggers: new_resource.event_loggers,
            exception_handlers: format_handler(new_resource.exception_handlers),
            file_backup_path: new_resource.file_backup_path,
            file_cache_path: new_resource.file_cache_path,
            file_staging_uses_destdir: new_resource.file_staging_uses_destdir,
            formatters: new_resource.formatters,
            http_proxy: new_resource.http_proxy,
            https_proxy: new_resource.https_proxy,
            ftp_proxy: new_resource.ftp_proxy,
            log_level: new_resource.log_level,
            log_location: new_resource.log_location,
            minimal_ohai: new_resource.minimal_ohai,
            named_run_list: new_resource.named_run_list,
            no_proxy: new_resource.no_proxy,
            node_name: new_resource.node_name,
            ohai_disabled_plugins: new_resource.ohai_disabled_plugins,
            ohai_optional_plugins: new_resource.ohai_optional_plugins,
            pid_file: new_resource.pid_file,
            policy_group: new_resource.policy_group,
            policy_name: new_resource.policy_name,
            report_handlers: format_handler(new_resource.report_handlers),
            ssl_verify_mode: new_resource.ssl_verify_mode,
            start_handlers: format_handler(new_resource.start_handlers),
            additional_config: new_resource.additional_config
          )
          mode "0640"
          action :create
        end
      end

      action :remove, description: "Remove a client.rb config file for configuring #{ChefUtils::Dist::Infra::PRODUCT}." do
        file ::File.join(new_resource.config_directory, "client.rb") do
          action :delete
        end
      end

      action_class do
        #
        # Format the handler document in the way we want it presented in the client.rb file
        #
        # @param [Hash] a handler property
        #
        # @return [Array] Array of handler data
        #
        def format_handler(handler_property)
          handler_data = []

          handler_property.each do |handler|
            handler_data << "#{handler["class"]}.new(#{handler["arguments"].join(",")})"
          end

          handler_data
        end
      end
    end
  end
end
