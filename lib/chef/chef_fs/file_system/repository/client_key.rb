#
# Author:: Thom May (<thom@chef.io>)
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

require_relative "../../data_handler/client_key_data_handler"
require_relative "base_file"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class ClientKey < BaseFile

          def initialize(name, parent)
            @data_handler = Chef::ChefFS::DataHandler::ClientKeyDataHandler.new
            super
          end

        end
      end
    end
  end
end
