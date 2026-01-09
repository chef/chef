#
# Author:: Jordan Running (<jr@chef.io>)
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

require_relative "acl"
require_relative "../../data_handler/acl_data_handler"
require_relative "directory"

class Chef
  module ChefFS
    module FileSystem
      module Repository
        class AclsSubDir < Repository::Directory

          protected

          def make_child_entry(child_name)
            Acl.new(child_name, self)
          end
        end
      end
    end
  end
end
