#
# Author:: Jay Mundrawala (<jdm@chef.io>)
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

require_relative "../util/powershell/ps_credential"

class Chef
  module DSL
    module Powershell
      def ps_credential(username = "placeholder", password) # rubocop:disable Style/OptionalArguments
        Chef::Util::Powershell::PSCredential.new(username, password)
      end
    end
  end
end
