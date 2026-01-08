#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require_relative "../util/windows/logon_session" if ChefUtils.windows?

class Chef
  module Mixin
    module UserContext

      # valid values for authentication => :remote, :local
      # When authentication = :local, we use the credentials to create a logon session against the local system, and then try to access the files.
      # When authentication = :remote, we continue with the current user but pass the provided credentials to the remote system.
      def with_user_context(user, password, domain = nil, authentication = :remote, &block)
        unless ChefUtils.windows?
          raise Exceptions::UnsupportedPlatform, "User context impersonation is supported only on the Windows platform"
        end

        unless block_given?
          raise ArgumentError, "You must supply a block to `with_user_context`"
        end

        logon_session = nil

        begin
          if user
            logon_session = Chef::Util::Windows::LogonSession.new(user, password, domain, authentication)
            logon_session.open
            logon_session.set_user_context
          end
          yield
        ensure
          logon_session.close if logon_session
        end
      end

      protected(:with_user_context)

    end
  end
end
