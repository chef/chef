#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system/operation_not_allowed_error'

class Chef
  module ChefFS
    module FileSystem
      class DefaultEnvironmentCannotBeModifiedError < OperationNotAllowedError
        def initialize(operation, entry, cause = nil)
          super(operation, entry, cause)
        end

        def reason
          result = super
          result + " (default environment cannot be modified)"
        end
      end
    end
  end
end
