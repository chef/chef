#
# Author:: Antony Thomas (<antonydeepak@gmail.com>)
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

require "psych" unless defined?(Psych)

class Chef
  class Resource
    class File
      class Verification

        #
        # Extends File verification to provide a Yaml verification
        #
        # Example:
        # file 'foo.yaml' do
        #   content "--- foo: 'foo-"
        #   verify :yaml
        # end
        #
        #

        class Yaml < Chef::Resource::File::Verification

          provides :yaml

          def verify(path, opts = {})
            Psych.parse(TargetIO::IO.read(path))
            true
          rescue Psych::SyntaxError => e
            Chef::Log.error("Yaml syntax verify failed with : #{e.message}")
            false
          end
        end
      end
    end
  end
end
