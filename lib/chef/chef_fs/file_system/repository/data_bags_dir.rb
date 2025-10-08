#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require_relative "directory"
require_relative "data_bag"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        # Represents the REPO_ROOT/data_bags directory. Children of this are
        # data bags.
        class DataBagsDir < Repository::Directory

          def make_child_entry(child_name)
            DataBag.new(child_name, self)
          end

        end
      end
    end
  end
end
