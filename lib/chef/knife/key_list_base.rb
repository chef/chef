#
# Author:: Tyler Cloke (<tyler@chef.io>)
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

class Chef
  class Knife
    # Extendable module that class_eval's common options into UserKeyList and ClientKeyList
    #
    # @author Tyler Cloke
    module KeyListBase
      def self.included(includer)
        includer.class_eval do
          option :with_details,
            short: "-w",
            long: "--with-details",
            description: "Show corresponding URIs and whether the key has expired or not."

          option :only_expired,
            short: "-e",
            long: "--only-expired",
            description: "Only show expired keys."

          option :only_non_expired,
            short: "-n",
            long: "--only-non-expired",
            description: "Only show non-expired keys."
        end
      end
    end
  end
end
