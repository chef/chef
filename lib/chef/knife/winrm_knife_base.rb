#
# Author:: Steven Murawski (<smurawski@chef.io)
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

require_relative "../knife"
require_relative "winrm_base"
require_relative "winrm_shared_options"
require_relative "winrm_session"

class Chef
  class Knife
    module WinrmCommandSharedFunctions

      FAILED_BASIC_HINT ||= "Hint: Please check winrm configuration 'winrm get winrm/config/service' AllowUnencrypted flag on remote server.".freeze
      FAILED_NOT_BASIC_HINT ||= <<~EOS.freeze
        Hint: Make sure to prefix domain usernames with the correct domain name.
        Hint: Local user names should be prefixed with computer name or IP address.
        EXAMPLE: my_domain\\user_name
      EOS

      def self.included(includer)
        includer.class_eval do

          @@ssl_warning_given = false

          include Chef::Knife::WinrmBase
          include Chef::Knife::WinrmSharedOptions

          def validate_winrm_options!
            winrm_auth_protocol = config[:winrm_authentication_protocol]

            unless Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.include?(winrm_auth_protocol)
              ui.error "Invalid value '#{winrm_auth_protocol}' for --winrm-authentication-protocol option."
              ui.info "Valid values are #{Chef::Knife::WinrmBase::WINRM_AUTH_PROTOCOL_LIST.join(",")}."
              exit 1
            end

            warn_no_ssl_peer_verification if no_ssl_peer_verification?
          end

          # Overrides Chef::Knife#configure_session, as that code is tied to the SSH implementation
          # Tracked by Issue # 3042 / https://github.com/chef/chef/issues/3042
          def configure_session
            validate_winrm_options!
            session_options
            target_nodes
            session_from_list
          end

          def target_nodes
            @list = if config[:manual]
                      @name_args[0].split(" ")
                    else
                      q = Chef::Search::Query.new
                      @action_nodes = q.search(:node, @name_args[0])[0]
                      @action_nodes.map do |item|
                        extract_nested_value(item, config[:attribute])
                      end.compact
                    end

            if @list.length == 0
              if @action_nodes.length == 0
                ui.fatal("No nodes returned from search!")
              else
                ui.fatal("#{@action_nodes.length} #{@action_nodes.length > 1 ? "nodes" : "node"} found, " +
                         "but does not have the required attribute (#{config[:attribute]}) to establish the connection. " +
                         "Try setting another attribute to open the connection using --attribute.")
              end
              exit 10
            end
          end

          # TODO: Copied from Knife::Core:GenericPresenter. Should be extracted
          def extract_nested_value(data, nested_value_spec)
            nested_value_spec.split(".").each do |attr|
              if data.nil?
                nil # don't get no method error on nil
              elsif data.respond_to?(attr.to_sym)
                data = data.send(attr.to_sym)
              elsif data.respond_to?(:[])
                data = data[attr]
              else
                data = begin
                         data.send(attr.to_sym)
                       rescue NoMethodError
                         nil
                       end
              end
            end
            ( !data.is_a?(Array) && data.respond_to?(:to_hash) ) ? data.to_hash : data
          end

          def run_command(command = "")
            relay_winrm_command(command)
            check_for_errors!
            @exit_code
          end

          def relay_winrm_command(command)
            Chef::Log.debug(command)
            @session_results = []
            queue = Queue.new
            @winrm_sessions.each { |s| queue << s }
            num_sessions = config[:concurrency]
            num_targets = @winrm_sessions.length
            num_sessions = (num_sessions.nil? || num_sessions == 0) ? num_targets : [num_sessions, num_targets].min

            # These nils will kill the Threads once no more sessions are left
            num_sessions.times { queue << nil }
            threads = []
            num_sessions.times do
              threads << Thread.new do
                while session = queue.pop
                  run_command_in_thread(session, command)
                end
              end
            end
            threads.map(&:join)
            @session_results
          end

          private

          def run_command_in_thread(s, command)
            @session_results << s.relay_command(command)
          rescue WinRM::WinRMHTTPTransportError, WinRM::WinRMAuthorizationError => e
            if authorization_error?(e)
              unless config[:suppress_auth_failure]
                # Display errors if the caller hasn't opted to retry
                ui.error "Failed to authenticate to #{s.host} as #{config[:winrm_user]}"
                ui.info "Response: #{e.message}"
                ui.info get_failed_authentication_hint
                raise e
              end
            else
              raise e
            end
          end

          def get_failed_authentication_hint
            if @session_opts[:basic_auth_only]
              FAILED_BASIC_HINT
            else
              FAILED_NOT_BASIC_HINT
            end
          end

          def authorization_error?(exception)
            exception.is_a?(WinRM::WinRMAuthorizationError) ||
              exception.message =~ /401/
          end

          def check_for_errors!
            @exit_code ||= 0
            @winrm_sessions.each do |session|
              session_exit_code = session.exit_code
              unless success_return_codes.include? session_exit_code.to_i
                @exit_code = [@exit_code, session_exit_code.to_i].max
                ui.error "Failed to execute command on #{session.host} return code #{session_exit_code}"
              end
            end
          end

          def success_return_codes
            # Redundant if the CLI options parsing occurs
            return [0] unless config[:returns]

            @success_return_codes ||= config[:returns].split(",").collect(&:to_i)
          end

          def session_from_list
            @list.each do |item|
              Chef::Log.debug("Adding #{item}")
              create_winrm_session(@session_opts.merge(host: item))
            end
          end

          def create_winrm_session(options = {})
            session = Chef::Knife::WinrmSession.new(options)
            @winrm_sessions ||= []
            @winrm_sessions.push(session)
          end

          def session_options
            config[:winrm_port] ||= ( config[:winrm_transport] == "ssl" ) ? "5986" : "5985"

            @session_opts = {
              user: winrm_user,
              password: config[:winrm_password],
              port: config[:winrm_port],
              operation_timeout: winrm_session_timeout_secs,
              basic_auth_only: winrm_basic_auth?,
              disable_sspi: winrm_disable_sspi,
              transport: winrm_transport,
              no_ssl_peer_verification: no_ssl_peer_verification?,
              ssl_peer_fingerprint: config[:ssl_peer_fingerprint],
              shell: config[:winrm_shell],
              codepage: config[:winrm_codepage],
            }

            # if a username was set and no password set we need to prompt
            if @session_opts[:user] && @session_opts[:password].nil?
              @session_opts[:password] = ui.ask("Enter your password: ", echo: false)
            end

            if @session_opts[:transport] == :kerberos
              @session_opts.merge!(winrm_kerberos_options)
            end

            @session_opts[:ca_trust_path] = config[:ca_trust_file] if config[:ca_trust_file]
          end

          def winrm_user
            # Prefixing with '.\' when using negotiate
            # to auth user against local machine domain
            if winrm_basic_auth? ||
                winrm_transport == :kerberos ||
                config[:winrm_user].include?("\\") ||
                config[:winrm_user].include?("@")
              config[:winrm_user]
            else
              ".\\#{config[:winrm_user]}"
            end
          end

          def winrm_session_timeout_secs
            # 30 min (Default) OperationTimeout for long bootstraps fix for KNIFE_WINDOWS-8
            config[:session_timeout].to_i * 60 if config[:session_timeout]
          end

          def winrm_basic_auth?
            config[:winrm_authentication_protocol] == "basic"
          end

          def winrm_kerberos_options
            kerberos_opts = {}
            kerberos_opts[:keytab] = config[:kerberos_keytab_file] if config[:kerberos_keytab_file]
            kerberos_opts[:realm] = config[:kerberos_realm] if config[:kerberos_realm]
            kerberos_opts[:service] = config[:kerberos_service] if config[:kerberos_service]
            kerberos_opts
          end

          def winrm_transport
            transport = config[:winrm_transport].to_sym
            if config.any? { |k, v| k.to_s =~ /kerberos/ && !v.nil? }
              transport = :kerberos
            elsif transport != :ssl && negotiate_auth?
              transport = :negotiate
            end

            transport
          end

          def no_ssl_peer_verification?
            config[:ca_trust_file].nil? && config[:winrm_ssl_verify_mode] == :verify_none && winrm_transport == :ssl
          end

          def winrm_disable_sspi
            winrm_transport != :negotiate
          end

          def negotiate_auth?
            config[:winrm_authentication_protocol] == "negotiate"
          end

          def warn_no_ssl_peer_verification
            unless @@ssl_warning_given
              @@ssl_warning_given = true
              ui.warn(<<~WARN)
                * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
                SSL validation of HTTPS requests for the WinRM transport is disabled. HTTPS WinRM
                connections are still encrypted, but knife is not able to detect forged replies
                or spoofing attacks.

                To fix this issue add an entry like this to your knife configuration file:

                ```
                  # Verify all WinRM HTTPS connections (default, recommended)
                  knife[:winrm_ssl_verify_mode] = :verify_peer
                ```
                * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
              WARN
            end
          end
        end
      end
    end
  end
end
