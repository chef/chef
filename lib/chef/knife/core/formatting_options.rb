#
# Author:: Nicolas DUPEUX (<nicolas.dupeux@arkea.com>)
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
    module Core

      # This module may be included into a knife subcommand class to automatically
      # add configuration options used by the StatusPresenter and NodePresenter.
      module FormattingOptions
        # @private
        # Would prefer to do this in a rational way, but can't be done b/c of
        # Mixlib::CLI's design :(
        def self.included(includer)
          includer.class_eval do
            option :medium_output,
              short: "-m",
              long: "--medium",
              boolean: true,
              default: false,
              description: "Include normal attributes in the output"

            option :long_output,
              short: "-l",
              long: "--long",
              boolean: true,
              default: false,
              description: "Include all attributes in the output"
          end
        end
      end
    end
  end
end
