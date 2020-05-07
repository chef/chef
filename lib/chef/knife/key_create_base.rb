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
    # Extendable module that class_eval's common options into UserKeyCreate and ClientKeyCreate
    #
    # @author Tyler Cloke
    module KeyCreateBase
      def self.included(includer)
        includer.class_eval do
          option :public_key,
            short: "-p FILENAME",
            long: "--public-key FILENAME",
            description: "Public key for newly created key. If not passed, the server will create a key pair for you, but you must pass --key-name NAME in that case."

          option :file,
            short: "-f FILE",
            long: "--file FILE",
            description: "Write the private key to a file, if you requested the server to create one."

          option :key_name,
            short: "-k NAME",
            long: "--key-name NAME",
            description: "The name for your key. If you do not pass a name, you must pass --public-key, and the name will default to the fingerprint of the public key passed."

          option :expiration_date,
            short: "-e DATE",
            long: "--expiration-date DATE",
            description: "Optionally pass the expiration date for the key in ISO 8601 formatted string: YYYY-MM-DDTHH:MM:SSZ e.g. 2013-12-24T21:00:00Z. Defaults to infinity if not passed. UTC timezone assumed."
        end
      end
    end
  end
end
