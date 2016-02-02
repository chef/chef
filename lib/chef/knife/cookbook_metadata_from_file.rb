#
#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
# Copyright:: Copyright 2010-2016, Matthew Kent
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

require "chef/knife"

class Chef
  class Knife
    class CookbookMetadataFromFile < Knife

      deps do
        require "chef/cookbook/metadata"
      end

      banner "knife cookbook metadata from FILE (options)"

      def run
        file = @name_args[0]
        cookbook = File.basename(File.dirname(file))

        @metadata = Chef::Knife::CookbookMetadata.new
        @metadata.generate_metadata_from_file(cookbook, file)
      end

    end
  end
end
