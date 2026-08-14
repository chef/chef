#
# Copyright:: 2026, Tim Smith
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

class Chef
  class Resource
    class LogrotateConfig < Chef::Resource

      provides :logrotate_config, target_mode: true
      target_mode support: :full

      description "Use the **logrotate_config** resource to manage log rotation policies for a set of log files" \
                  " using individual configuration files installed into the `/etc/logrotate.d/` directory." \
                  " logrotate is not a daemon: it re-reads `/etc/logrotate.d/` on every run, so no service" \
                  " reload is required for a new or changed policy to take effect. This resource does not" \
                  " install logrotate and does not manage `/etc/logrotate.conf`."
      introduced "19.5"
      examples <<~DOC
      **Rotate a service's logs daily, keeping two weeks**

      ```ruby
      logrotate_config '/var/log/nginx/*.log' do
        frequency 'daily'
        rotate 14
        compress true
        missingok true
        notifempty true
      end
      ```

      **Name the block after the application to control the filename**

      ```ruby
      logrotate_config 'nginx' do
        path ['/var/log/nginx/*.log', '/var/log/nginx/*/*.log']
        frequency 'daily'
        rotate 14
        sharedscripts true
        postrotate '/usr/bin/systemctl reload nginx'
      end
      ```

      **Rotate by size, truncating in place for a process that holds the file open**

      ```ruby
      logrotate_config 'myapp' do
        path '/var/log/myapp/app.log'
        size '100M'
        rotate 5
        copytruncate true
        compress true
      end
      ```

      **Use the directives escape hatch for options this resource does not model**

      ```ruby
      logrotate_config 'myapp' do
        path '/var/log/myapp/*.log'
        frequency 'weekly'
        directives ['su root adm', 'dateext', 'dateformat -%Y%m%d']
      end
      ```
      DOC

      property :path, [String, Array],
        name_property: true,
        coerce: proc { |v| Array(v) },
        description: "A log file path, or an Array of paths, that this rotation policy applies to. Globs are supported."

      property :filename, String,
        default: lazy { |r| r.name.sub(%r{^/}, "").gsub("/", "-").delete("*") },
        default_description: "The resource name, with leading slashes stripped, remaining slashes replaced by dashes, and globs removed.",
        description: "The name of the configuration file created in `/etc/logrotate.d/`."

      property :mode, [String, Integer],
        default: "0644",
        description: "The permission mode of the configuration file."

      property :frequency, String,
        equal_to: %w{hourly daily weekly monthly yearly},
        description: "How often to rotate the logs."

      property :rotate, Integer,
        description: "The number of rotated log files to keep before deleting the oldest."

      property :size, [String, Integer],
        description: "Rotate when the log grows larger than this size, e.g. `'100M'`. Takes precedence over `frequency`."

      property :minsize, [String, Integer],
        description: "Rotate on the configured frequency, but only once the log exceeds this size."

      property :maxsize, [String, Integer],
        description: "Rotate when the log exceeds this size, even if the configured frequency has not elapsed."

      property :maxage, Integer,
        description: "Remove rotated logs older than this many days."

      property :create, String,
        description: "Recreate the log file immediately after rotation, with the given mode, owner and group, e.g. `'0640 nginx adm'`."

      property :su, String,
        description: "Rotate the logs as the given user and group, e.g. `'root adm'`. Required when the log directory is not owned by root."

      property :olddir, String,
        description: "Move rotated logs into this directory."

      property :compress, [TrueClass, FalseClass],
        description: "Compress rotated logs with gzip."

      property :delaycompress, [TrueClass, FalseClass],
        description: "Postpone compression of the most recently rotated log until the next rotation. Use with processes that keep writing to the old file briefly after rotation."

      property :copytruncate, [TrueClass, FalseClass],
        description: "Copy the log and truncate it in place rather than moving it, for processes that cannot be told to reopen their log file."

      property :missingok, [TrueClass, FalseClass],
        description: "Do not error if the log file is missing. Recommended when the policy is configured before the application has written its first log."

      property :notifempty, [TrueClass, FalseClass],
        description: "Do not rotate the log when it is empty."

      property :sharedscripts, [TrueClass, FalseClass],
        description: "Run the prerotate and postrotate scripts once for the whole pattern rather than once per matched log file."

      property :dateext, [TrueClass, FalseClass],
        description: "Append a date to rotated log filenames instead of a sequence number."

      property :prerotate, [String, Array],
        description: "Command(s) to run before rotation."

      property :postrotate, [String, Array],
        description: "Command(s) to run after rotation, typically signalling the service to reopen its log file."

      property :firstaction, [String, Array],
        description: "Command(s) to run once before prerotate, before any log file is rotated."

      property :lastaction, [String, Array],
        description: "Command(s) to run once after postrotate, after all log files have been rotated."

      property :directives, Array,
        default: [],
        description: "Additional raw logrotate directives, emitted verbatim after the properties above. Use for options this resource does not model."

      # Directives rendered as a bare keyword when the property is true.
      BOOLEAN_DIRECTIVES = %i{compress delaycompress copytruncate missingok notifempty sharedscripts dateext}.freeze

      # Directives rendered as "keyword value".
      VALUED_DIRECTIVES = %i{rotate size minsize maxsize maxage create su olddir}.freeze

      # Directives rendered as a script block terminated by "endscript".
      SCRIPT_DIRECTIVES = %i{firstaction prerotate postrotate lastaction}.freeze

      LOGROTATE_CONF = "/etc/logrotate.conf".freeze
      LOGROTATE_DIR = "/etc/logrotate.d".freeze

      #
      # Build the contents of the logrotate configuration file.
      #
      # @return [String]
      #
      def config_content
        lines = ["# Generated by #{ChefUtils::Dist::Infra::PRODUCT}. Changes will be overwritten.", ""]
        lines << "#{path.join(" ")} {"

        # frequency is a bare keyword rather than a key/value pair
        lines << "  #{frequency}" if frequency

        VALUED_DIRECTIVES.each do |directive|
          value = send(directive)
          lines << "  #{directive} #{value}" unless value.nil?
        end

        BOOLEAN_DIRECTIVES.each do |directive|
          lines << "  #{directive}" if send(directive)
        end

        directives.each { |directive| lines << "  #{directive}" }

        SCRIPT_DIRECTIVES.each do |directive|
          commands = send(directive)
          next if commands.nil?

          lines << "  #{directive}"
          Array(commands).each { |command| lines << "    #{command}" }
          lines << "  endscript"
        end

        lines << "}"
        lines.join("\n") + "\n"
      end

      action :create, description: "Create a logrotate configuration file in the `/etc/logrotate.d/` directory." do
        warn_unless_included

        directory LOGROTATE_DIR

        file "#{LOGROTATE_DIR}/#{new_resource.filename}" do
          content new_resource.config_content
          mode new_resource.mode
          sensitive new_resource.sensitive
          action :create
        end
      end

      action :delete, description: "Delete an existing logrotate configuration file." do
        file "#{LOGROTATE_DIR}/#{new_resource.filename}" do
          action :delete
        end
      end

      action_class do
        # logrotate only reads /etc/logrotate.d because /etc/logrotate.conf includes it. Without that
        # directive the rendered file is inert, and nothing else would tell the user why. Warn rather
        # than fail, since the directory may legitimately be included from somewhere else.
        def warn_unless_included
          return unless ::TargetIO::File.exist?(LOGROTATE_CONF)
          return if ::TargetIO::File.readlines(LOGROTATE_CONF).grep(%r{^\s*include\s+#{Regexp.escape(LOGROTATE_DIR)}/?\s*$}).any?

          Chef::Log.warn("#{new_resource.filename} will be rendered, but #{LOGROTATE_CONF} lacks an 'include #{LOGROTATE_DIR}' directive, so it will not take effect!")
        end
      end
    end
  end
end
