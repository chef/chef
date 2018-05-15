#
# Author:: Steven Murawski (<smurawski@chef.io>)
# Copyright:: Copyright 2016, Chef Software, Inc.
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

class Chef
  class Application

    # These are the exit codes defined in Chef RFC 062
    # https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md
    class ExitCode

      # -1 is defined as DEPRECATED_FAILURE in RFC 062, so it is
      # not enumerated in an active constant.
      #
      VALID_RFC_062_EXIT_CODES = {
        SUCCESS: 0,
        GENERIC_FAILURE: 1,
        SIGINT_RECEIVED: 2,
        SIGTERM_RECEIVED: 3,
        REBOOT_SCHEDULED: 35,
        REBOOT_NEEDED: 37,
        REBOOT_FAILED: 41,
        AUDIT_MODE_FAILURE: 42,
        CLIENT_UPGRADED: 213,
      }

      DEPRECATED_RFC_062_EXIT_CODES = {
        DEPRECATED_FAILURE: -1,
      }

      class << self

        def normalize_exit_code(exit_code = nil)
          normalized_exit_code = normalize_legacy_exit_code(exit_code)
          if valid_exit_codes.include? normalized_exit_code
            normalized_exit_code
          else
            Chef::Log.warn(non_standard_exit_code_warning(normalized_exit_code))
            VALID_RFC_062_EXIT_CODES[:GENERIC_FAILURE]
          end
        end

        private

        def normalize_legacy_exit_code(exit_code)
          case exit_code
          when Integer
            exit_code
          when Exception
            lookup_exit_code_by_exception(exit_code)
          else
            VALID_RFC_062_EXIT_CODES[:GENERIC_FAILURE]
          end
        end

        def lookup_exit_code_by_exception(exception)
          if sigint_received?(exception)
            VALID_RFC_062_EXIT_CODES[:SIGINT_RECEIVED]
          elsif sigterm_received?(exception)
            VALID_RFC_062_EXIT_CODES[:SIGTERM_RECEIVED]
          elsif reboot_scheduled?(exception)
            VALID_RFC_062_EXIT_CODES[:REBOOT_SCHEDULED]
          elsif reboot_needed?(exception)
            VALID_RFC_062_EXIT_CODES[:REBOOT_NEEDED]
          elsif reboot_failed?(exception)
            VALID_RFC_062_EXIT_CODES[:REBOOT_FAILED]
          elsif audit_failure?(exception)
            VALID_RFC_062_EXIT_CODES[:AUDIT_MODE_FAILURE]
          elsif client_upgraded?(exception)
            VALID_RFC_062_EXIT_CODES[:CLIENT_UPGRADED]
          else
            VALID_RFC_062_EXIT_CODES[:GENERIC_FAILURE]
          end
        end

        def reboot_scheduled?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::Reboot
          end
        end

        def reboot_needed?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::RebootPending
          end
        end

        def reboot_failed?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::RebootFailed
          end
        end

        def audit_failure?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::AuditError
          end
        end

        def client_upgraded?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::ClientUpgraded
          end
        end

        def sigint_received?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::SigInt
          end
        end

        def sigterm_received?(exception)
          resolve_exception_array(exception).any? do |e|
            e.is_a? Chef::Exceptions::SigTerm
          end
        end

        def resolve_exception_array(exception)
          exception_array = [exception]
          if exception.respond_to?(:wrapped_errors)
            exception.wrapped_errors.each do |e|
              exception_array.push e
            end
          end
          exception_array
        end

        def valid_exit_codes
          VALID_RFC_062_EXIT_CODES.values
        end

        def notify_on_deprecation(message)
          Chef.deprecated(:exit_code, message)
        rescue Chef::Exceptions::DeprecatedFeatureError
            # Have to rescue this, otherwise this unhandled error preempts
            # the current exit code assignment.
        end

        def non_standard_exit_code_warning(exit_code)
          "Chef attempted to exit with a non-standard exit code of #{exit_code}." \
          " Chef RFC 062 (https://github.com/chef/chef-rfc/blob/master/rfc062-exit-status.md) defines the" \
          " exit codes that should be used with Chef.  Chef::Application::ExitCode defines valid exit codes"  \
          " Non-standard exit codes are redefined as GENERIC_FAILURE."
        end

      end
    end

  end
end
