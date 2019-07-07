#
# Author:: Joshua Timberman <jtimberman@chef.io>
# Author:: Tim Smith <tsmith@chef.io>
# Copyright:: 2011-2019, Chef Software Inc.
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

require "chef/resource"
require "chef/resource/service"

class Chef
  class Resource
    # Missing top-level class documentation comment
    class RunitService < Chef::Resource::Service
      resource_name :runit_service

      description "The runit_service manages services running under the runit init system. Note: The runit init system must be installed to use this resource."

      introduced "15.2"

      # For legacy reasons we allow setting these via attribute
      property :sv_bin, String,
               default: lazy { (node["runit"] && node["runit"]["sv_bin"]) || (platform_family?("debian") ? "/usr/bin/sv" : "/sbin/sv") },
               description: "The path to the sv program binary. This will attempt to use the node['runit']['sv_bin'] attribute, and falls back to /usr/bin/sv."

      property :sv_dir, [String, FalseClass],
               default: lazy { (node["runit"] && node["runit"]["sv_dir"]) || "/etc/sv" },
               description: "The base 'service directory' for the services managed by the resource. By default, this will attempt to use the node['runit']['sv_dir'] attribute, and falls back to /etc/sv."

      property :service_dir, String,
               default: lazy { (node["runit"] && node["runit"]["service_dir"]) || "/etc/service" },
               description: "The directory where services are symlinked to be supervised by runsvdir. By default, this will attempt to use the node['runit']['service_dir'] attribute, and falls back to /etc/service."

      property :lsb_init_dir, String,
               default: lazy { (node["runit"] && node["runit"]["lsb_init_dir"]) || "/etc/init.d" },
               description: "The directory where an LSB-compliant init script interface will be created. By default, this will attempt to use the node['runit']['lsb_init_dir'] attribute, and falls back to /etc/init.d."

      property :control, Array, default: [],
               description: "An array of signals to customize control of the service, see runsv man page on how to use this. This requires that each template be created with the name sv-service_name-signal.erb."

      property :env, Hash, default: {},
               description: "A hash of environment variables with their values as content used in the service's env directory. Default is an empty hash. When this hash is non-empty, the contents of the runit service's env directory will be managed by Chef in order to conform to the declared state."

      property :options, Hash, # deprecated: true should be set in the future
               default: lazy { default_options }, coerce: proc { |r| default_options.merge(r) if r.respond_to?(:merge) },
               description: "Options passed as variables to templates, for compatibility with legacy runit service definition. Default is an empty hash."

      property :log, [TrueClass, FalseClass], default: true,
               description: "Whether to start the service's logger with svlogd, requires a template sv-service_name-log-run.erb to configure the log's run script."

      property :cookbook, String,
               description: "A cookbook where templates are located instead of where the resource is used. Applies for all the templates in the enable action."

      property :check, [TrueClass, FalseClass], default: false,
               description: "Whether the service has a check script, requires a template sv-service_name-check.erb."

      property :start_down, [TrueClass, FalseClass], default: false,
               description: "Set the default state of the runit service to 'down' by creating <sv_dir>/down file. Defaults to false. Services using start_down will not be notified to restart when their run script is updated."

      property :delete_downfile, [TrueClass, FalseClass], default: false,
               description: "Delete previously created <sv_dir>/down file."

      property :finish, [TrueClass, FalseClass], default: false,
               description: "Whether the service has a finish script, requires a template sv-service_name-finish.erb."

      property :supervisor_owner, String,
               description: "The user that should be allowed to control this service, see runsv faq.",
               regex: [Chef::Config[:user_valid_regex]]

      property :supervisor_group, String,
               description: "The group that should be allowed to control this service, see runsv faq.",
               regex: [Chef::Config[:group_valid_regex]]

      property :owner, String,
               description: "The user that should own the templates created to enable the service.",
               regex: [Chef::Config[:user_valid_regex]]

      property :group, String,
               description: "The group that should own the templates created to enable the service.",
               regex: [Chef::Config[:group_valid_regex]]

      property :enabled, [TrueClass, FalseClass], default: false,
               deprecated: true, skip_docs: true

      property :running, [TrueClass, FalseClass], default: false,
               deprecated: true, skip_docs: true

      property :default_logger, [TrueClass, FalseClass], default: false,
               description: "Whether a default log/run script should be set up. If true, the default content of the run script will use svlogd to write logs to /var/log/service_name."

      property :restart_on_update, [TrueClass, FalseClass], default: true,
               description: "Whether the service should be restarted when the run script is updated. Defaults to true. Set to false if the service shouldn't be restarted when the run script is updated."

      property :run_template_name, String, default: lazy { service_name },
               description: "An alternate filename of the run run script to use instead of the value provided in service_name."

      property :log_template_name, String, default: lazy { service_name },
               description: "An alternate filename of the log run script to use instead of the value provided in service_name."

      property :check_script_template_name, String, default: lazy { service_name },
               description: "An alternate filename for the check script to use instead of the value provided in service_name."

      property :finish_script_template_name, String, default: lazy { service_name },
               description: "An alternate filename for the finish script to use instead of the value provided in service_name."

      property :control_template_names, Hash, default: lazy { set_control_template_names },
               description: "A hash of control signals (see control above) and their alternate template name(s) replacing service_name."

      property :status_command, String, default: lazy { "#{sv_bin} status #{service_name}" },
               description: "The command used to check the status of the service to see if it is enabled/running (if it's running, it's enabled). This hardcodes the location of the sv program to /usr/bin/sv due to the aforementioned cookbook load order."

      property :sv_templates, [TrueClass, FalseClass], default: true, description: "If true, the :enable action will create the service directory with the appropriate templates. Default is true. Set this to false if the service has a package that provides its own service directory. See Usage examples."

      property :sv_timeout, Integer,
               description: "Override the default sv timeout of 7 seconds."

      property :sv_verbose, [TrueClass, FalseClass], default: false, description: "Whether to enable sv verbose mode. Default is false."

      property :log_dir, String,
               default: lazy { ::File.join("/var/log/", service_name) },
               description: "The directory where the svlogd log service will run. Used when default_logger is true."

      property :log_flags, String, default: "-tt",
               description: "The flags to pass to the svlogd command. Used when default_logger is true."

      property :log_size, Integer,
               description: "The maximum size a log file can grow to before it is automatically rotated. See svlogd(8) for the default value."

      property :log_num, Integer,
               description: "The maximum number of log files that will be retained after rotation. See svlogd(8) for the default value."

      property :log_min, Integer,
               description: "The minimum number of log files that will be retained after rotation (if svlogd cannot create a new file and the minimum has not been reached, it will block).",
               default_description: "No minimum"

      property :log_timeout, Integer,
               description: "The maximum age a log file can get to before it is automatically rotated, whether it has reached log_size or not.",
               default_description: "No timeout"

      property :log_processor, String,
               description: "A string containing a path to a program that rotated log files will be fed through. See the PROCESSOR section of svlogd(8) for details."

      property :log_socket, [String, Hash],
               description: "An string containing an IP:port pair identifying a UDP socket that log lines will be copied to."

      property :log_prefix, String,
               description: "A string that will be prepended to each line as it is logged."

      property :log_config_append, String,
               description: "A string containing optional additional lines to add to the log service configuration. See svlogd(8) for more details."

      # Use a link to sv instead of a full blown init script calling runit.
      # This was added for omnibus projects and probably shouldn't be used elsewhere
      property :use_init_script_sv_link, [TrueClass, FalseClass], default: false

      alias template_name run_template_name

      def set_control_template_names
        template_names = {}
        control.each do |signal|
          template_names[signal] ||= service_name
        end
        template_names
      end

      # the default legacy options kept for compatibility with the definition
      #
      # @return [Hash] if env is the default empty hash then return env_dir valuue. Otherwise return an empty hash
      def default_options
        env.empty? ? { env_dir: ::File.join(sv_dir, service_name, "env") } : {}
      end

      def after_created
        unless run_context.nil?
          new_resource = self
          service_dir_name = ::File.join(service_dir, service_name)
          find_resource(:service, new_resource.name) do # creates if it does not exist
            provider Chef::Provider::Service::Simple
            supports new_resource.supports
            start_command "#{new_resource.sv_bin} start #{service_dir_name}"
            stop_command "#{new_resource.sv_bin} stop #{service_dir_name}"
            restart_command "#{new_resource.sv_bin} restart #{service_dir_name}"
            status_command "#{new_resource.sv_bin} status #{service_dir_name}"
            action :nothing
          end
        end
      end

      # Mapping of valid signals with optional friendly name
      VALID_SIGNALS ||= Mash.new(
        :down => nil,
        :hup => nil,
        :int => nil,
        :term => nil,
        :kill => nil,
        :quit => nil,
        :up => nil,
        :once => nil,
        :cont => nil,
        1 => :usr1,
        2 => :usr2
      )

      # actions
      action :create do
        ruby_block "restart_service" do
          block do
            previously_enabled = enabled?
            action_enable

            # Only restart the service if it was previously enabled. If the service was disabled
            # or not running, then the enable action will start the service, and it's unnecessary
            # to restart the service again.
            restart_service if previously_enabled
          end
          action :nothing
          only_if { new_resource.restart_on_update && !new_resource.start_down }
        end

        ruby_block "restart_log_service" do
          block do
            action_enable
            restart_log_service
          end
          action :nothing
          only_if { new_resource.restart_on_update && !new_resource.start_down }
        end

        # sv_templates
        if new_resource.sv_templates
          directory sv_dir_name do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0755"
            recursive true
            action :create
          end

          template ::File.join(sv_dir_name, "run") do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            source "sv-#{new_resource.run_template_name}-run.erb"
            cookbook new_resource.cookbook
            mode "0755"
            variables(options: new_resource.options)
            action :create
            notifies :run, "ruby_block[restart_service]", :delayed
          end

          # log stuff
          if new_resource.log
            directory ::File.join(sv_dir_name, "log") do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              recursive true
              action :create
            end

            directory ::File.join(sv_dir_name, "log", "main") do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode "0755"
              recursive true
              action :create
            end

            directory new_resource.log_dir do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode "0755"
              recursive true
              action :create
            end

            template ::File.join(sv_dir_name, "log", "config") do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode "0644"
              cookbook "runit"
              source "log-config.erb"
              variables(config: new_resource)
              notifies :run, "ruby_block[restart_log_service]", :delayed
              action :create
            end

            link ::File.join(new_resource.log_dir, "config") do
              to ::File.join(sv_dir_name, "log", "config")
            end

            if new_resource.default_logger
              template ::File.join(sv_dir_name, "log", "run") do
                owner new_resource.owner unless new_resource.owner.nil?
                group new_resource.group unless new_resource.group.nil?
                mode "0755"
                cookbook "runit"
                source "log-run.erb"
                variables(config: new_resource)
                notifies :run, "ruby_block[restart_log_service]", :delayed
                action :create
              end
            else
              template ::File.join(sv_dir_name, "log", "run") do
                owner new_resource.owner unless new_resource.owner.nil?
                group new_resource.group unless new_resource.group.nil?
                mode "0755"
                source "sv-#{new_resource.log_template_name}-log-run.erb"
                cookbook new_resource.cookbook
                variables(options: new_resource.options)
                action :create
                notifies :run, "ruby_block[restart_log_service]", :delayed
              end
            end
          end

          # environment stuff
          directory ::File.join(sv_dir_name, "env") do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0755"
            action :create
          end

          new_resource.env.map do |var, value|
            file ::File.join(sv_dir_name, "env", var) do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              content value
              sensitive true
              mode "0640"
              action :create
              notifies :run, "ruby_block[restart_service]", :delayed
            end
          end

          ruby_block "Delete unmanaged env files for #{new_resource.name} service" do
            block { delete_extra_env_files }
            only_if { extra_env_files? }
            not_if { new_resource.env.empty? }
            action :run
            notifies :run, "ruby_block[restart_service]", :delayed
          end

          template ::File.join(sv_dir_name, "check") do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0755"
            cookbook new_resource.cookbook
            source "sv-#{new_resource.check_script_template_name}-check.erb"
            variables(options: new_resource.options)
            action :create
            only_if { new_resource.check }
          end

          template ::File.join(sv_dir_name, "finish") do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0755"
            source "sv-#{new_resource.finish_script_template_name}-finish.erb"
            cookbook new_resource.cookbook
            variables(options: new_resource.options) if new_resource.options.respond_to?(:has_key?)
            action :create
            only_if { new_resource.finish }
          end

          directory ::File.join(sv_dir_name, "control") do
            owner new_resource.owner unless new_resource.owner.nil?
            group new_resource.group unless new_resource.group.nil?
            mode "0755"
            action :create
          end

          new_resource.control.map do |signal|
            template ::File.join(sv_dir_name, "control", signal) do
              owner new_resource.owner unless new_resource.owner.nil?
              group new_resource.group unless new_resource.group.nil?
              mode "0755"
              source "sv-#{new_resource.control_template_names[signal]}-#{signal}.erb"
              cookbook new_resource.cookbook
              variables(options: new_resource.options)
              action :create
            end
          end

          # lsb_init
          if platform?("debian", "ubuntu") && !new_resource.use_init_script_sv_link
            ruby_block "unlink #{::File.join(new_resource.lsb_init_dir, new_resource.service_name)}" do
              block { ::File.unlink(::File.join(new_resource.lsb_init_dir, new_resource.service_name).to_s) }
              only_if { ::File.symlink?(::File.join(new_resource.lsb_init_dir, new_resource.service_name).to_s) }
            end

            template ::File.join(new_resource.lsb_init_dir, new_resource.service_name) do
              owner "root"
              group "root"
              mode "0755"
              cookbook "runit"
              source "init.d.erb"
              variables(
                name: new_resource.service_name,
                sv_bin: new_resource.sv_bin,
                sv_args: sv_args,
                init_dir: ::File.join(new_resource.lsb_init_dir, "")
              )
              action :create
            end
          else
            link ::File.join(new_resource.lsb_init_dir, new_resource.service_name) do
              to new_resource.sv_bin
              action :create
            end
          end

          # Create/Delete service down file
          # To prevent unexpected behavior, require users to explicitly set
          # delete_downfile to remove any down file that may already exist
          df_action = :nothing
          if new_resource.start_down
            df_action = :create
          elsif new_resource.delete_downfile
            df_action = :delete
          end

          file down_file do
            mode "0644"
            backup false
            content "# File created and managed by chef!"
            action df_action
          end
        end
      end

      action :disable do
        ruby_block "disable #{new_resource.service_name}" do
          block { disable_service }
          only_if { enabled? }
        end
      end

      action :enable do
        action_create

        directory new_resource.service_dir

        link service_dir_name.to_s do
          to sv_dir_name
          action :create
        end

        ruby_block "wait for #{new_resource.service_name} service socket" do
          block do
            wait_for_service
          end
          action :run
        end

        # Support supervisor owner and groups http://smarden.org/runit/faq.html#user
        if new_resource.supervisor_owner || new_resource.supervisor_group
          directory ::File.join(service_dir_name, "supervise") do
            mode "0755"
            action :create
          end
          %w{ok status control}.each do |target|
            file ::File.join(service_dir_name, "supervise", target) do
              owner new_resource.supervisor_owner || "root"
              group new_resource.supervisor_group || "root"
              action :touch
            end
          end
        end
      end

      # signals
      VALID_SIGNALS.each do |signal, signal_name|
        action(signal_name || signal) do
          if running?
            Chef::Log.info "#{new_resource} signalled (#{(signal_name || signal).to_s.upcase})"
            runit_send_signal(signal, signal_name)
          else
            Chef::Log.debug "#{new_resource} not running - nothing to do"
          end
        end
      end

      action :restart do
        restart_service
      end

      action :start do
        if running?
          Chef::Log.debug "#{new_resource} already running - nothing to do"
        else
          start_service
          Chef::Log.info "#{new_resource} started"
        end
      end

      action :stop do
        if running?
          stop_service
          Chef::Log.info "#{new_resource} stopped"
        else
          Chef::Log.debug "#{new_resource} already stopped - nothing to do"
        end
      end

      action :reload do
        if running?
          reload_service
          Chef::Log.info "#{new_resource} reloaded"
        else
          Chef::Log.debug "#{new_resource} not running - nothing to do"
        end
      end

      action :status do
        running?
      end

      action :reload_log do
        converge_by("reload log service") do
          reload_log_service
        end
      end

      action_class do
        def down_file
          ::File.join(sv_dir_name, "down")
        end

        def env_dir
          ::File.join(sv_dir_name, "env")
        end

        def extra_env_files?
          files = []
          Dir.glob(::File.join(sv_dir_name, "env", "*")).each do |f|
            files << File.basename(f)
          end
          return true if files.sort != new_resource.env.keys.sort
          false
        end

        def delete_extra_env_files
          Dir.glob(::File.join(sv_dir_name, "env", "*")).each do |f|
            unless new_resource.env.key?(File.basename(f))
              File.unlink(f)
              Chef::Log.info("removing file #{f}")
            end
          end
        end

        def wait_for_service
          raise "Runit does not appear to be installed. Include runit::default before using the resource!" unless binary_exists?

          sleep 1 until ::FileTest.pipe?(::File.join(service_dir_name, "supervise", "ok"))

          if new_resource.log
            sleep 1 until ::FileTest.pipe?(::File.join(service_dir_name, "log", "supervise", "ok"))
          end
        end

        def runit_send_signal(signal, friendly_name = nil)
          friendly_name ||= signal
          converge_by("send #{friendly_name} to #{new_resource}") do
            safe_sv_shellout!("#{sv_args}#{signal} #{service_dir_name}")
            Chef::Log.info("#{new_resource} sent #{friendly_name}")
          end
        end

        def running?
          cmd = safe_sv_shellout("#{sv_args}status #{service_dir_name}", returns: [0, 100])
          !cmd.error? && cmd.stdout =~ /^run:/
        end

        def log_running?
          cmd = safe_sv_shellout("#{sv_args}status #{::File.join(service_dir_name, 'log')}", returns: [0, 100])
          !cmd.error? && cmd.stdout =~ /^run:/
        end

        def enabled?
          ::File.exist?(::File.join(service_dir_name, "run"))
        end

        def log_service_name
          ::File.join(new_resource.service_name, "log")
        end

        def sv_dir_name
          ::File.join(new_resource.sv_dir, new_resource.service_name)
        end

        def sv_args
          sv_args = ""
          sv_args += "-w #{new_resource.sv_timeout} " unless new_resource.sv_timeout.nil?
          sv_args += "-v " if new_resource.sv_verbose
          sv_args
        end

        def service_dir_name
          ::File.join(new_resource.service_dir, new_resource.service_name)
        end

        def log_dir_name
          ::File.join(new_resource.service_dir, new_resource.service_name, log)
        end

        def binary_exists?
          begin
            Chef::Log.debug("Checking to see if the runit binary exists by running #{new_resource.sv_bin}")
            shell_out!(new_resource.sv_bin.to_s, returns: [0, 100])
          rescue Errno::ENOENT
            Chef::Log.debug("Failed to return 0 or 100 running #{new_resource.sv_bin}")
            return false
          end
          true
        end

        def safe_sv_shellout(command, options = {})
          begin
            Chef::Log.debug("Attempting to run runit command: #{new_resource.sv_bin} #{command}")
            cmd = shell_out("#{new_resource.sv_bin} #{command}", options)
          rescue Errno::ENOENT
            if binary_exists?
              raise # Some other cause
            else
              raise "Runit does not appear to be installed. You must install runit before using the runit_service resource!"
            end
          end
          cmd
        end

        def safe_sv_shellout!(command, options = {})
          safe_sv_shellout(command, options).tap(&:error!)
        end

        def disable_service
          Chef::Log.debug("Attempting to disable runit service with: #{new_resource.sv_bin} #{sv_args}down #{service_dir_name}")
          shell_out("#{new_resource.sv_bin} #{sv_args}down #{service_dir_name}")
          FileUtils.rm(service_dir_name)

          # per the documentation, a service should be removed from supervision
          # within 5 seconds of removing the service dir symlink, so we'll sleep for 6.
          # otherwise, runit recreates the 'ok' named pipe too quickly
          Chef::Log.debug("Sleeping 6 seconds to allow the disable to take effect")
          sleep(6)
          # runit will recreate the supervise directory and
          # pipes when the service is reenabled
          Chef::Log.debug("Removing #{::File.join(sv_dir_name, 'supervise', 'ok')}")
          FileUtils.rm(::File.join(sv_dir_name, "supervise", "ok"))
        end

        def start_service
          safe_sv_shellout!("#{sv_args}start #{service_dir_name}")
        end

        def stop_service
          safe_sv_shellout!("#{sv_args}stop #{service_dir_name}")
        end

        def restart_service
          safe_sv_shellout!("#{sv_args}restart #{service_dir_name}")
        end

        def restart_log_service
          safe_sv_shellout!("#{sv_args}restart #{::File.join(service_dir_name, 'log')}")
        end

        def reload_service
          safe_sv_shellout!("#{sv_args}force-reload #{service_dir_name}")
        end

        def reload_log_service
          if log_running?
            safe_sv_shellout!("#{sv_args}force-reload #{::File.join(service_dir_name, 'log')}")
          else
            Chef::Log.debug("Logging not running so doing nothing")
          end
        end
      end
    end
  end
end
