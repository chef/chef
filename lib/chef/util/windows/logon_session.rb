#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../../win32/api/security" if ChefUtils.windows?
require_relative "../../mixin/wide_string"

class Chef
  class Util
    class Windows
      class LogonSession
        include Chef::Mixin::WideString

        def initialize(username, password, domain = nil, authentication = :remote)
          if username.nil? || password.nil?
            raise ArgumentError, "The logon session must be initialize with non-nil user name and password parameters"
          end

          @original_username = username
          @original_password = password
          @original_domain = domain
          @authentication = authentication
          @token = FFI::Buffer.new(:pointer)
          @session_opened = false
          @impersonating = false
        end

        def open
          if session_opened
            raise "Attempted to open a logon session that was already open."
          end

          username = wstring(original_username)
          password = wstring(original_password)
          domain = wstring(original_domain)

          logon_type = (authentication == :local) ? (Chef::ReservedNames::Win32::API::Security::LOGON32_LOGON_NETWORK) : (Chef::ReservedNames::Win32::API::Security::LOGON32_LOGON_NEW_CREDENTIALS)
          status = Chef::ReservedNames::Win32::API::Security.LogonUserW(username, domain, password, logon_type, Chef::ReservedNames::Win32::API::Security::LOGON32_PROVIDER_DEFAULT, token)

          unless status
            last_error = FFI::LastError.error
            raise Chef::Exceptions::Win32APIError, "Logon for user `#{original_username}` failed with Win32 status #{last_error}."
          end

          @session_opened = true
        end

        def close
          validate_session_open!

          if impersonating
            restore_user_context
          end

          Chef::ReservedNames::Win32::API::System.CloseHandle(token.read_ulong)
          @token = nil
          @session_opened = false
        end

        def set_user_context
          validate_session_open!

          unless session_opened
            raise "Attempted to set the user context before opening a session."
          end

          if impersonating
            raise "Attempt to set the user context when the user context is already set."
          end

          status = Chef::ReservedNames::Win32::API::Security.ImpersonateLoggedOnUser(token.read_ulong)

          unless status
            last_error = FFI::LastError.error
            raise Chef::Exceptions::Win32APIError, "Attempt to impersonate user `#{original_username}` failed with Win32 status #{last_error}."
          end

          @impersonating = true
        end

        def restore_user_context
          validate_session_open!

          if impersonating
            status = Chef::ReservedNames::Win32::API::Security.RevertToSelf

            unless status
              last_error = FFI::LastError.error
              raise Chef::Exceptions::Win32APIError, "Unable to restore user context with Win32 status #{last_error}."
            end
          end

          @impersonating = false
        end

        protected

        attr_reader :original_username
        attr_reader :original_password
        attr_reader :original_domain
        attr_reader :authentication

        attr_reader :token
        attr_reader :session_opened
        attr_reader :impersonating

        def validate_session_open!
          unless session_opened
            raise "Attempted to set the user context before opening a session."
          end
        end
      end
    end
  end
end
